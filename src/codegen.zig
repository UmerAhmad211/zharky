const std = @import("std");
const eql = std.mem.eql;

const l = @import("lexer.zig");
const p = @import("parser.zig");
const instruction = p.instruction;
const operand = p.operand;
const pp = @import("pretty_print_errs.zig");
const compilerError = pp.compilerErrors;
const errorToken = pp.errorToken;
const SecOperandOp1 = @import("token_def.zig").SecOperandOp1;
const symbol = @import("symb_table.zig").Symbol;
const symbolTable = @import("symb_table.zig").SymbolTable;
const td = @import("token_def.zig");
const Jmps = td.Jmps;
const RegsOp1 = td.RegsOp1;
const TokenType = td.TokenType;
const RegReg = td.RegReg;
const RegMem = td.RegMem;
const MemReg = td.MemReg;
const RegData = td.RegData;
const MemData = td.MemData;
const MemDataByte = td.MemDataByte;
const ut = @import("util.zig");
const numberType = ut.numberType;
const Number = ut.Number;
const checkIfDoubleOrByte = ut.checkIfDoubleOrByte;
const ELF_HDR_SZ = ut.ELF_HDR_SZ;

const text_hdr_addr: u32 = 0x08048000;
var data_hdr_addr: u32 = 0;

// codegen driver
pub fn codegenDriver(encodings: *std.ArrayList(u8), text_arr: *std.ArrayList(instruction), s_table: *symbolTable, header: *[ELF_HDR_SZ]u8, data_offset: u32, err_tok: *errorToken) bool {
    const start: []const u8 = "_start";
    const retd_offset = s_table.*.getOffset(start) catch {
        err_tok.*.error_type = compilerError.startNotFound;
        return false;
    };

    ut.updateFourConsecIndexes(&header.*, retd_offset.offset, 24);
    data_hdr_addr = data_offset + text_hdr_addr;

    for (text_arr.*.items) |inst| {
        if (inst.opcode.type == .INSTRUCTION_0OP) {
            encodeInst0OP(&encodings.*, &inst.opcode) catch {
                err_tok.*.error_type = compilerError.programError;
                err_tok.*.err_token = inst.opcode;
                return false;
            };
        } else if (inst.opcode.type == .INSTRUCTION_1OP) {
            encodeInst1OP(&encodings.*, &inst, &s_table.*) catch |err| {
                err_tok.*.error_type = err;
                err_tok.*.err_token = inst.opcode;
                return false;
            };
        } else if (inst.opcode.type == .INSTRUCTION_2OP) {
            encode2OP(&encodings.*, &inst, &s_table.*) catch |err| {
                err_tok.*.error_type = err;
                err_tok.*.err_token = inst.opcode;
                return false;
            };
        } else {
            encodeInstO1OP(&encodings.*, &inst) catch {
                err_tok.*.error_type = compilerError.programError;
                err_tok.*.err_token = inst.opcode;
                return false;
            };
        }
    }
    return true;
}

fn encodeInst0OP(encodings: *std.ArrayList(u8), opcode: *const l.Token) !void {
    if (eql(u8, opcode.*.value, "nop"))
        try encodings.*.append(0x90)
    else {
        try encodings.*.append(0xF4);
    }
}

fn encodeInst1OP(encodings: *std.ArrayList(u8), inst: *const instruction, s_table: *symbolTable) compilerError!void {
    const op = inst.*.op1.?;
    const opcode = inst.*.opcode.value;
    if (eql(u8, opcode, "int")) {
        encodings.*.append(0xCD) catch return compilerError.programError;
        encodings.*.append(op.value.int_u8) catch return compilerError.programError;
    } else if (op.op_type == .REG) {
        encodings.*.append(RegsOp1.get(opcode).? + ut.retRegValues(op.value.slice)) catch return compilerError.programError;
    } else if (SecOperandOp1.get(opcode) != null) {
        const inst_val = SecOperandOp1.get(opcode).?;
        if (op.op_type == .IMM) {
            encodings.*.append(inst_val) catch return compilerError.programError;
            ut.append32BitLittleEndian(&encodings.*, op.value.int_u32) catch return compilerError.programError;
        } else {
            const in_mem_type = checkIfDoubleOrByte(op.value, &s_table.*) catch |err| return err;
            const byte_mem = in_mem_type == .DB and inst_val != 0x8F;
            const reg_bits = if (inst_val == 0x8F) 0 else inst_val;
            encodings.*.append(if (inst_val == 0x8F) inst_val else if (byte_mem) 0xFE else 0xFF) catch return compilerError.programError;
            appendInMemValsWithModrm(&encodings.*, &s_table.*, op.value, byte_mem, reg_bits, false) catch |err| return err;
        }
    } else {
        const retd_offset = s_table.*.getOffset(op.value.slice) catch |err| return err;
        if (retd_offset.symbol_type == .DD or retd_offset.symbol_type == .DB) return compilerError.syntaxError;
        const inst_encoding = Jmps.get(opcode);
        encodings.*.append(if (inst_encoding == 0x10) inst_encoding.? - 1 else inst_encoding.?) catch return compilerError.programError;
        if (inst_encoding.? == 0x10 or inst_encoding.? == 0x0F) encodings.*.append(if (inst_encoding == 0x10) 0x85 else 0x84) catch return compilerError.programError;
        const symb_offset_s: i32 = @intCast(retd_offset.offset);
        const inst_offset_s: i32 = @intCast(inst.*.offset);
        const rel_label_addr: u32 = @bitCast(symb_offset_s - (inst_offset_s + 5));
        ut.append32BitLittleEndian(&encodings.*, rel_label_addr) catch return compilerError.programError;
    }
}

// zig fmt: off
fn encode2OP(encodings: *std.ArrayList(u8), inst: *const instruction, s_table: *symbolTable) compilerError!void {
    const op1 = inst.*.op1.?;
    const op2 = inst.*.op2.?;
    const opcode = inst.*.opcode.value;

    if (op1.op_type == .REG and op2.op_type == .REG) {
        encodings.*.append(RegReg.get(opcode).?) catch return compilerError.programError;
        const reg_dest = ut.retRegValues(op1.value.slice);
        const reg_src = ut.retRegValues(op2.value.slice);
        encodings.*.append(ut.createModrmByte(0b11, reg_src, reg_dest)) catch return compilerError.programError;
    } else if (op1.op_type == .REG and op2.op_type == .MEM) {
        encodings.*.append(RegMem.get(opcode).?) catch return compilerError.programError;
        appendInMemValsWithModrm(&encodings.*, &s_table.*, op2.value, false, ut.retRegValues(op1.value.slice), true) catch |err| return err;
    } else if (op1.op_type == .REG and (op2.op_type == .IMM or op2.op_type == .IDENTIFIER or op2.op_type == .START)) {
        const reg = ut.retRegValues(op1.value.slice);
        const opcode_val = RegData.get(opcode).?;
        encodings.*.append(opcode_val + if (opcode_val == 0xB8) reg else 0) catch return compilerError.programError;
        if (opcode_val != 0xB8) {
            const reg_bits: u8 = if (eql(u8, opcode, "cmp")) 0b111 else 0;
            encodings.*.append(ut.createModrmByte(0b11, reg_bits, reg)) catch return compilerError.programError;
        }
        if (op2.op_type == .IMM) ut.append32BitLittleEndian(&encodings.*, op2.value.int_u32) catch return compilerError.programError 
        else findOffsetAndAppend(&encodings.*, &s_table.*, op2.value) catch |err| return err;
    } else if (op1.op_type == .MEM and op2.op_type == .REG) {
        encodings.*.append(MemReg.get(opcode).?) catch return compilerError.programError;
        appendInMemValsWithModrm(&encodings.*, &s_table.*, op1.value, false, ut.retRegValues(op1.value.slice), false) catch |err| return err;
    } else if (op1.op_type == .MEM and (op2.op_type == .IMM or op2.op_type == .CHAR or op2.op_type == .IDENTIFIER or op2.op_type == .START)) {
        const in_mem_type: TokenType = if ((op1.value != .int_u32) and ut.retRegValues(op1.value.slice) == 8) checkIfDoubleOrByte(op1.value, &s_table.*) catch |err| return err else .ERR;
        const byte_mem = in_mem_type == .DB;
        const reg_bits: u8 = if (eql(u8, opcode, "cmp")) 0b111 else 0;
        const allow_t_sec_id: bool = reg_bits != 0;
        encodings.*.append(if (byte_mem) MemDataByte.get(opcode).? else MemData.get(opcode).?) catch return compilerError.programError;
        appendInMemValsWithModrm(&encodings.*, &s_table.*, op1.value, byte_mem, reg_bits, allow_t_sec_id) catch |err| return err;
        if (byte_mem) encodings.*.append(op2.value.int_u8) catch return compilerError.programError else if (!byte_mem and op2.op_type != .CHAR) {
            if (op2.op_type == .IMM) ut.append32BitLittleEndian(&encodings.*, if (op2.value == .int_u8) 0 | op2.value.int_u8 else op2.value.int_u32) catch return compilerError.programError 
            else findOffsetAndAppend(&encodings.*, &s_table.*, op2.value) catch |err| return err;
        } else return compilerError.invalidOperand;
    }
}
// zig fmt: on

fn encodeInstO1OP(encodings: *std.ArrayList(u8), inst: *const instruction) !void {
    if (inst.*.op1) |op| {
        try encodings.*.append(0xC2);
        try encodings.*.append(@intCast(op.value.int_u16 & 0xFF));
        try encodings.*.append(@intCast((op.value.int_u16 >> 8) & 0xFF));
    } else {
        try encodings.*.append(0xC3);
    }
}

fn appendInMemValsWithModrm(encodings: *std.ArrayList(u8), s_table: *symbolTable, value: Number, byte_mem: bool, reg_bits: u8, allow_t_sec_id: bool) compilerError!void {
    if (value == .slice) {
        const in_mem_val = ut.retRegValues(value.slice);
        if (in_mem_val != 8) {
            var mod: u8 = 0;
            if (in_mem_val == 5) mod = 1;
            const modrm = ut.createModrmByte(mod, reg_bits, in_mem_val);
            encodings.*.append(modrm) catch return compilerError.programError;
            if (in_mem_val == 4) encodings.*.append(0x24) catch return compilerError.programError else if (in_mem_val == 5) encodings.*.append(0) catch return compilerError.programError;
        } else {
            var label_offset: u32 = 0;
            const retd_offset = s_table.*.getOffset(value.slice) catch |err| return err;
            if (retd_offset.symbol_type == .DD or (byte_mem and retd_offset.symbol_type == .DB)) {
                label_offset = data_hdr_addr + retd_offset.offset;
            } else if (allow_t_sec_id and (retd_offset.symbol_type == .IDENTIFIER or retd_offset.symbol_type == .START)) {
                label_offset = text_hdr_addr + retd_offset.offset + 0x1000;
            } else {
                return compilerError.invalidOperand;
            }
            appendModrmWithImm(&encodings.*, label_offset, 0, reg_bits, 0b101) catch return compilerError.programError;
        }
    } else {
        appendModrmWithImm(&encodings.*, value.int_u32, 0, reg_bits, 0b101) catch return compilerError.programError;
    }
}

fn appendModrmWithImm(encodings: *std.ArrayList(u8), imm: u32, mod: u8, reg: u8, rm: u8) !void {
    const modrm = ut.createModrmByte(mod, reg, rm);
    try encodings.*.append(modrm);
    try ut.append32BitLittleEndian(&encodings.*, imm);
}

fn findOffsetAndAppend(encodings: *std.ArrayList(u8), s_table: *symbolTable, val: Number) compilerError!void {
    const retd_offset = s_table.*.getOffset(val.slice) catch |err| return err;
    var label_offset: u32 = 0;
    if (retd_offset.symbol_type == .DD or retd_offset.symbol_type == .DB) label_offset = data_hdr_addr + retd_offset.offset else label_offset = text_hdr_addr + retd_offset.offset + 0x1000;
    ut.append32BitLittleEndian(&encodings.*, label_offset) catch return compilerError.programError;
}

const std = @import("std");
const eql = std.mem.eql;

const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const l = @import("lexer.zig");
const p = @import("parser.zig");
const instruction = p.instruction;
const pp = @import("pretty_print_errs.zig");
const symbolTable = @import("symb_table.zig").SymbolTable;
const ut = @import("util.zig");
const numberType = ut.numberType;
const symbol = @import("symb_table.zig").Symbol;

const text_hdr_addr: u32 = 0x08048000;
var data_hdr_addr: u32 = 0;

pub fn codegenDriver(encodings: *std.ArrayList(u8), text_arr: *std.ArrayList(instruction), s_table: *symbolTable, header: *std.ArrayList(u8), data_offset: u32) compilerError!void {
    const start: []const u8 = "_start";
    var retd_offset: symbol = undefined;
    if (!s_table.*.containsLabel(&start)) return compilerError.startNotFound else {
        retd_offset = s_table.*.getOffset(start) catch |err| return err;
        header.*.items[24] += @intCast(retd_offset.offset & 0xFF);
        header.*.items[25] += @intCast((retd_offset.offset >> 8) & 0xFF);
        header.*.items[26] += @intCast((retd_offset.offset >> 16) & 0xFF);
        header.*.items[27] += @intCast((retd_offset.offset >> 24) & 0xFF);
    }
    data_hdr_addr = data_offset + text_hdr_addr;
    for (text_arr.*.items) |inst| {
        if (inst.opcode.type == .INSTRUCTION_0OP) {
            encodeInst0OP(&encodings.*, &inst.opcode) catch return compilerError.programError;
        } else if (inst.opcode.type == .INSTRUCTION_1OP) {
            encodeInst1OP(&encodings.*, &inst, &s_table.*) catch |err| return err;
        } else if (inst.opcode.type == .INSTRUCTION_2OP) {
            encode2OP(&encodings.*, &inst, &s_table.*) catch |err| return err;
        } else {
            encodeInstO1OP(&encodings.*, &inst) catch return compilerError.programError;
        }
    }
}

fn encodeInst0OP(encodings: *std.ArrayList(u8), opcode: *const l.Token) !void {
    if (eql(u8, opcode.*.value, "nop"))
        try encodings.*.append(0x90)
    else {
        try encodings.*.append(0xF4);
    }
}

fn encodeInst1OP(encodings: *std.ArrayList(u8), inst: *const instruction, s_table: *symbolTable) compilerError!void {
    if (eql(u8, inst.*.opcode.value, "call")) {
        if (inst.*.op1.?.op_type == .IDENTIFIER) {
            const retd_offset = s_table.*.getOffset(inst.*.op1.?.value.slice) catch |err| return err;
            if (retd_offset.symbol_type == .D_SECTION) return compilerError.syntaxError;
            encodings.*.append(0xE8) catch return compilerError.programError;
            const symb_offset_s: i32 = @intCast(retd_offset.offset);
            const inst_offset_s: i32 = @intCast(inst.*.offset);
            const label_addr: u32 = @bitCast(symb_offset_s - (inst_offset_s + 5));
            ut.append32BitLittleEndian(&encodings.*, label_addr) catch return compilerError.programError;
        }
    } else if (eql(u8, inst.*.opcode.value, "int")) {
        encodings.*.append(0xCD) catch return compilerError.programError;
        encodings.*.append(inst.*.op1.?.value.int_u8) catch return compilerError.programError;
    }
}

fn encode2OP(encodings: *std.ArrayList(u8), inst: *const instruction, s_table: *symbolTable) compilerError!void {
    if (eql(u8, inst.*.opcode.value, "mov")) {
        if (inst.*.op1.?.op_type == .REG and inst.*.op2.?.op_type == .REG) {
            encodings.*.append(0x8B) catch return compilerError.programError;
            const mod: u8 = 3 << 6;
            const reg: u8 = ut.retRegValues(inst.*.op1.?.value.slice) << 3;
            const rm = ut.retRegValues(inst.*.op2.?.value.slice);
            const modrm: u8 = mod | reg | rm;
            encodings.*.append(modrm) catch return compilerError.programError;
        } else if (inst.*.op1.?.op_type == .REG and (inst.*.op2.?.op_type == .IMM or inst.*.op2.?.op_type == .IDENTIFIER)) {
            encodings.*.append(0xB8 + ut.retRegValues(inst.*.op1.?.value.slice)) catch return compilerError.programError;
            if (inst.*.op2.?.op_type == .IMM)
                ut.append32BitLittleEndian(&encodings.*, inst.*.op2.?.value.int_u32) catch return compilerError.programError
            else {
                var label_offset: u32 = 0;
                const retd_offset = s_table.*.getOffset(inst.*.op2.?.value.slice) catch |err| return err;
                if (retd_offset.symbol_type == .D_SECTION) label_offset = data_hdr_addr + retd_offset.offset else {
                    label_offset = text_hdr_addr + retd_offset.offset + 0x1000;
                }
                ut.append32BitLittleEndian(&encodings.*, label_offset) catch return compilerError.programError;
            }
        } else if (inst.*.op1.?.op_type == .REG and inst.*.op2.?.op_type == .MEM) {
            const mod: u8 = 0 << 6;
            const reg: u8 = ut.retRegValues(inst.*.op1.?.value.slice) << 3;
            const rm: u8 = 0x5;
            const modrm = mod | reg | rm;
            encodings.*.append(0x8B) catch return compilerError.programError;
            encodings.*.append(modrm) catch return compilerError.programError;
            if (inst.*.op2.?.value == .int_u32) {
                ut.append32BitLittleEndian(&encodings.*, inst.*.op2.?.value.int_u32) catch return compilerError.programError;
            } else if (inst.*.op2.?.value == .slice) {
                const retd_offset = s_table.*.getOffset(inst.*.op2.?.value.slice) catch |err| return err;
                var label_offset: u32 = 0;
                if (retd_offset.symbol_type == .D_SECTION) label_offset = data_hdr_addr + retd_offset.offset else {
                    label_offset = text_hdr_addr + retd_offset.offset + 0x1000;
                }
                ut.append32BitLittleEndian(&encodings.*, label_offset) catch return compilerError.programError;
            }
        }
    }
}

fn encodeInstO1OP(encodings: *std.ArrayList(u8), inst: *const instruction) !void {
    if (inst.*.op1) |op| {
        try encodings.*.append(0xC2);
        try encodings.*.append(@intCast(op.value.int_u16 & 0xFF));
        try encodings.*.append(@intCast((op.value.int_u16 >> 8) & 0xFF));
    } else {
        try encodings.*.append(0xC3);
    }
}

const std = @import("std");
const eql = std.mem.eql;

const l = @import("lexer.zig");
const pp = @import("pretty_print_errs.zig");
const errorToken = pp.errorToken;
const compilerError = pp.compilerErrors;
const symbol = @import("symb_table.zig").Symbol;
const symbolTable = @import("symb_table.zig").SymbolTable;
const td = @import("token_def.zig");
const TokenType = td.TokenType;
const Jmps = td.Jmps;
const ut = @import("util.zig");
const Number = ut.Number;

var curr_token: l.Token = undefined;
var token_arr: ?*std.ArrayList(l.Token) = null;
var curr_index: usize = 0;

pub const operand = struct {
    op_type: TokenType,
    value: Number,
};

pub const instruction = struct {
    opcode: l.Token,
    op1: ?operand,
    op2: ?operand,
    offset: u32,
};

// parser driver
pub fn parse(tokenized_input: *std.ArrayList(l.Token), err_tok: *errorToken, s_table: *symbolTable, text_arr: *std.ArrayList(instruction), data_arr: *std.ArrayList(u8), data_len: *u32, text_len: *u32) bool {
    token_arr = tokenized_input;
    curr_token = token_arr.?.*.items[curr_index];
    var d_offset: u32 = 0;
    var t_offset: u32 = 0;

    expectDataSection() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectData(&s_table.*, &d_offset, &data_arr.*) catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectTextSection() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectText(&s_table.*, &t_offset, &text_arr.*) catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };
    data_len.* = d_offset;
    text_len.* = t_offset;

    return true;
}

// check data section key words i.e: section .data\n
fn expectDataSection() compilerError!void {
    const valid_token_arr = [3]TokenType{ .K_SECTION, .D_SECTION, .EOL };
    for (valid_token_arr) |tok| {
        if (curr_token.type == tok) {
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
    }
}

// section .text\n
// global _start\n
fn expectTextSection() compilerError!void {
    const valid_token_arr = [6]TokenType{ .K_SECTION, .T_SECTION, .EOL, .K_GLOBAL, .START, .EOL };
    for (valid_token_arr) |tok| {
        if (curr_token.type == tok) {
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
    }
}

// msg db "Hi", Ah\n => ok
// msg db "hi",\n    => error
fn expectData(s_table: *symbolTable, d_offset: *u32, data_arr: *std.ArrayList(u8)) compilerError!void {
    var d_size: bool = undefined;
    while (curr_token.type == .IDENTIFIER) {
        var symb: symbol = undefined;
        var id_name = curr_token.value;
        if (curr_token.type == .IDENTIFIER) {
            symb.offset = d_offset.*;
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
        if (curr_token.type == .DB) {
            d_size = false;
        } else if (curr_token.type == .DD) {
            d_size = true;
        } else {
            return compilerError.wrongDataId;
        }
        symb.symbol_type = curr_token.type;
        s_table.*.storeSymbol(&symb, &id_name) catch |err| return err;
        nextToken();
        checkForDataCommaPattern(d_size, &d_offset.*, &data_arr.*) catch |err| return err;
        nextToken();
    }
}

// check operands and syntax
fn expectText(s_table: *symbolTable, t_offset: *u32, text_arr: *std.ArrayList(instruction)) compilerError!void {
    while (curr_token.type != .EOF) {
        var is_inst = true;
        var inst_line: instruction = .{ .opcode = undefined, .op1 = null, .op2 = null, .offset = 0 };
        if ((curr_token.type == .IDENTIFIER) or curr_token.type == .START) {
            var temp_token_for_symb = curr_token;
            nextToken();
            if (curr_token.type == .COLON) {
                var temp_symb: symbol = .{ .offset = t_offset.*, .symbol_type = temp_token_for_symb.type };
                s_table.*.storeSymbol(&temp_symb, &temp_token_for_symb.value) catch |err| return err;
                nextToken();
                is_inst = false;
            } else {
                return compilerError.syntaxError;
            }
        } else if (curr_token.type == .INSTRUCTION_0OP) {
            inst_line.opcode = curr_token;
            inst_line.offset = t_offset.*;
            t_offset.* += 1;
            nextToken();
        } else if (curr_token.type == .INSTRUCTION_1OP) {
            inst_line = checkOperand1op(&t_offset.*) catch |err| return err;
        } else if (curr_token.type == .INSTRUCTION_2OP) {
            inst_line = checkOperand2op(&t_offset.*) catch |err| return err;
        } else if (curr_token.type == .INSTRUCTION_O1OP) {
            inst_line = checkOperand01op(&t_offset.*) catch |err| return err;
        } else {
            return compilerError.unidentifiedInst;
        }

        if (curr_token.type != .EOL) {
            return compilerError.syntaxError;
        }
        if (is_inst) text_arr.*.append(inst_line) catch return compilerError.programError;
        nextToken();
    }
}

// if EOF has occurred return .ERR
fn nextToken() void {
    if (curr_token.type != .EOF) {
        curr_index += 1;
        curr_token = token_arr.?.items[curr_index];
    } else {
        curr_token = .{ .type = .ERR, .value = undefined, .curr_line = undefined, .row_no = undefined, .col_no = undefined };
    }
}

// .ERR if .EOF
fn seekToken() TokenType {
    if (curr_token.type != .EOF) return token_arr.?.items[curr_index + 1].type;
    return .ERR;
}

// .STRING .COMMA data .EOL => ok
// data .COMMA .EOL         => bad
fn checkForDataCommaPattern(d_size: bool, d_offset: *u32, data_arr: *std.ArrayList(u8)) compilerError!void {
    while (curr_token.type != .EOL) {
        if ((curr_token.type == .STRING or curr_token.type == .CHAR or curr_token.type == .IMM) and !d_size) {
            const d_convd = ut.incrDoffsetWrtDtype(d_size, &d_offset.*, curr_token.type, curr_token.value) catch |err| return err;
            if (d_convd == .int_u8) data_arr.*.append(d_convd.int_u8) catch return compilerError.programError else {
                for (d_convd.slice) |c|
                    data_arr.*.append(c) catch return compilerError.programError;
            }
        } else if (curr_token.type == .IMM and d_size) {
            const d_convd = ut.incrDoffsetWrtDtype(d_size, &d_offset.*, curr_token.type, curr_token.value) catch |err| return err;
            ut.append32BitLittleEndian(&data_arr.*, d_convd.int_u32) catch return compilerError.programError;
        } else {
            return compilerError.syntaxError;
        }
        nextToken();
        if (curr_token.type == .EOL) {
            continue;
        }
        if (curr_token.type == .COMMA) {
            const seeked_token = seekToken();
            if (seeked_token == .EOL) {
                return compilerError.syntaxError;
            }
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
    }
}

fn createMem(t_offset: *u32) compilerError!operand {
    var n_op: operand = undefined;
    n_op.op_type = .MEM;

    t_offset.* += 1;

    if (curr_token.type == .IDENTIFIER or curr_token.type == .START) {
        n_op.value = Number{ .slice = curr_token.value };
        t_offset.* += 4;
    } else if (curr_token.type == .IMM) {
        n_op.value = ut.isANumOfAnyBase(curr_token.value, true) catch return compilerError.syntaxError;
        t_offset.* += 4;
    } else if (curr_token.type == .REG) {
        n_op.value = Number{ .slice = curr_token.value };
        const reg_val = ut.retRegValues(curr_token.value);
        if (reg_val == 4 or reg_val == 5) t_offset.* += 1;
    } else {
        return compilerError.invalidOperand;
    }
    nextToken();

    if (curr_token.type == .C_BRACKET) {
        const seekd_token = seekToken();
        if (seekd_token == .EOL or seekd_token == .COMMA) {
            return n_op;
        } else {
            return compilerError.syntaxError;
        }
    }
    return n_op;
}

// check operands of instructions with 1 operand and return their processed form
fn checkOperand1op(t_offset: *u32) compilerError!instruction {
    var n_inst: instruction = .{ .opcode = curr_token, .op1 = null, .op2 = null, .offset = t_offset.* };
    const seekd_token = seekToken();
    var is_int_inst: bool = false;

    t_offset.* += 1;

    if (eql(u8, curr_token.value, "int")) is_int_inst = true;

    if (is_int_inst or eql(u8, curr_token.value, "push")) {
        if (seekd_token == .IMM) {
            nextToken();
            n_inst.op1 = parseImm(is_int_inst) catch |err| return err;
            t_offset.* += ut.retNumOfBytes(n_inst.op1.?.value);
            if (is_int_inst and n_inst.op1.?.value != .int_u8) return compilerError.invalidOperand;
        } else if (!is_int_inst and seekd_token == .REG) {
            nextToken();
            n_inst.op1 = parseAllOps(&t_offset.*, false) catch |err| return err;
        } else {
            return compilerError.invalidOperand;
        }
    } else if (eql(u8, curr_token.value, "jmp") or eql(u8, curr_token.value, "je") or eql(u8, curr_token.value, "jne") or eql(u8, curr_token.value, "call")) {
        if (seekd_token == .IDENTIFIER) {
            nextToken();
            n_inst.op1 = parseAllOps(&t_offset.*, false) catch |err| return err;
            const jmp_opcode = Jmps.get(n_inst.opcode.value);
            if (jmp_opcode.? == 0x0F or jmp_opcode.? == 0x10) t_offset.* += 1;
            t_offset.* += 4;
        } else {
            return compilerError.invalidOperand;
        }
    } else if (seekd_token == .REG or seekd_token == .O_BRACKET) {
        nextToken();
        n_inst.op1 = parseAllOps(&t_offset.*, false) catch |err| return err;
    } else {
        return compilerError.syntaxError;
    }

    nextToken();
    return n_inst;
}

// check operands of instructions with 2 operands and return their processed form
fn checkOperand2op(t_offset: *u32) compilerError!instruction {
    var n_inst: instruction = .{ .opcode = curr_token, .op1 = null, .op2 = null, .offset = t_offset.* };
    var seekd_token = seekToken();

    t_offset.* += 1;

    if (seekd_token == .REG or seekd_token == .O_BRACKET) {
        nextToken();
        n_inst.op1 = parseAllOps(&t_offset.*, false) catch |err| return err;
    } else {
        return compilerError.syntaxError;
    }
    nextToken();
    if (curr_token.type != .COMMA) return compilerError.syntaxError;
    seekd_token = seekToken();
    // zig fmt: off
    if (seekd_token == .REG
    or seekd_token == .START
    or (seekd_token == .CHAR and n_inst.op1.?.op_type != .REG)
    or (seekd_token == .O_BRACKET and n_inst.op1.?.op_type != .MEM)
    or seekd_token == .IMM or seekd_token == .IDENTIFIER) {
        nextToken();
        if (curr_token.type == .CHAR) {
            n_inst.op2.?.op_type = curr_token.type;
            n_inst.op2.?.value = Number{ .int_u8 = curr_token.value[0] };
            t_offset.* += 1;
        } else {
            n_inst.op2 = parseAllOps(&t_offset.*, n_inst.op1.?.op_type == .MEM) catch |err| return err;
            if (curr_token.type == .IDENTIFIER or curr_token.type == .START) t_offset.* += 4;
        }
    } else {
        return compilerError.invalidOperand;
    }

    if (n_inst.op1.?.op_type == .REG 
    and (n_inst.op2.?.op_type == .REG 
    or (td.RegData.get(n_inst.opcode.value).? == 0x81 and n_inst.op2.?.op_type == .IMM))) t_offset.* += 1;
    // zig fmt: on
    nextToken();
    return n_inst;
}

// check operands of instructions with 1 optional operand and return their processed form
fn checkOperand01op(t_offset: *u32) compilerError!instruction {
    var n_inst: instruction = .{ .opcode = curr_token, .op1 = null, .op2 = null, .offset = t_offset.* };
    const seekd_token = seekToken();
    t_offset.* += 1;
    if (seekd_token == .IMM) {
        nextToken();
        n_inst.op1 = parseImm(false) catch |err| return err;
        if (n_inst.op1.?.value.int_u32 >= std.math.minInt(u16) and n_inst.op1.?.value.int_u32 <= std.math.maxInt(u16)) {
            const convd_num_u16: u16 = @intCast(n_inst.op1.?.value.int_u32);
            n_inst.op1.?.value = Number{ .int_u16 = convd_num_u16 };
            t_offset.* += 2;
        } else {
            return compilerError.invalidOperand;
        }
    } else if (seekd_token != .EOL) return compilerError.syntaxError;

    nextToken();
    return n_inst;
}

// parse imm
fn parseImm(byte_op: bool) compilerError!operand {
    var op: operand = undefined;
    var convd_num: Number = undefined;

    if (byte_op)
        convd_num = ut.isANumOfAnyBase(curr_token.value, false) catch |err| return err
    else
        convd_num = ut.isANumOfAnyBase(curr_token.value, true) catch |err| return err;

    op.value = convd_num;
    op.op_type = curr_token.type;
    return op;
}

// parse reg,id or mem
fn parseAllOps(t_offset: *u32, byte_op: bool) compilerError!operand {
    var op: operand = undefined;

    if (curr_token.type == .O_BRACKET) {
        nextToken();
        op = createMem(&t_offset.*) catch |err| return err;
    } else {
        if (curr_token.type == .IMM) {
            op = parseImm(byte_op) catch |err| return err;
            t_offset.* += ut.retNumOfBytes(op.value);
        } else {
            op.value = Number{ .slice = curr_token.value };
            op.op_type = curr_token.type;
        }
    }
    return op;
}

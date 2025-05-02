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
const ut = @import("util.zig");
const Number = ut.Number;

var curr_token: l.Token = undefined;
var token_arr: ?*std.ArrayList(l.Token) = null;
var curr_index: usize = 0;

pub const operand = struct {
    op_type: TokenType,
    value: ?Number,
};

pub const instruction = struct {
    opcode: l.Token,
    op1: ?operand,
    op2: ?operand,
};

pub fn parse(tokenized_input: *std.ArrayList(l.Token), err_tok: *errorToken, s_table: *symbolTable, text_arr: *std.ArrayList(instruction), data_arr: *std.ArrayList(u8)) bool {
    token_arr = tokenized_input;
    curr_token = token_arr.?.*.items[curr_index];
    var d_offset: usize = 0;
    var t_offset: usize = 0;

    // errors bubbling
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
    const valid_token_arr = [6]TokenType{ .K_SECTION, .T_SECTION, .EOL, .K_GLOBAL, .IDENTIFIER, .EOL };
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
fn expectData(s_table: *symbolTable, d_offset: *usize, data_arr: *std.ArrayList(u8)) compilerError!void {
    var d_size: u1 = undefined;
    while (curr_token.type == .IDENTIFIER) {
        if (curr_token.type == .IDENTIFIER) {
            var symb: symbol = .{ .symbol_type = curr_token.type, .offset = d_offset.* };
            s_table.*.storeSymbol(&symb, &curr_token.value) catch |err| return err;
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
        if (curr_token.type == .DB) {
            d_size = 0;
        } else if (curr_token.type == .DD) {
            d_size = 1;
        } else {
            return compilerError.wrongDataId;
        }
        nextToken();
        checkForDataCommaPattern(d_size, &d_offset.*, &data_arr.*) catch |err| return err;
        nextToken();
    }
}

// check operands and syntax
fn expectText(s_table: *symbolTable, t_offset: *usize, text_arr: *std.ArrayList(instruction)) compilerError!void {
    // zig fmt: off
    while (curr_token.type != .EOF) {
        var inst_line: instruction = undefined;
        if (curr_token.type == .IDENTIFIER) {
            var temp_token_for_symb = curr_token;
            nextToken();
            if (curr_token.type == .COLON) {
                var temp_symb: symbol = .{.offset = t_offset.*,.symbol_type = temp_token_for_symb.type};
                s_table.*.storeSymbol(&temp_symb, &temp_token_for_symb.value) catch |err| return err;
                nextToken();
            } else {
                return compilerError.syntaxError;
            }
        }
        else if (curr_token.type == .INSTRUCTION_0OP) {
            inst_line.opcode = curr_token;
            nextToken();
        }
        else if (curr_token.type == .INSTRUCTION_1OP) {
            inst_line = checkOperands(&t_offset.*) catch |err| return err;
        }
        else if (curr_token.type == .INSTRUCTION_2OP) {
            inst_line = checkOperands(&t_offset.*) catch |err| return err;
        }
        else if (curr_token.type == .INSTRUCTION_O1OP) {
            inst_line = checkOperands(&t_offset.*) catch |err| return err;
        }
        else {
            return compilerError.unidentifiedInst;
        }

        if (curr_token.type != .EOL) {
            return compilerError.syntaxError;
        } 
        text_arr.*.append(inst_line) catch return compilerError.programError;
        nextToken();
    }
    // zig fmt: on
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
fn checkForDataCommaPattern(d_size: u1, d_offset: *usize, data_arr: *std.ArrayList(u8)) compilerError!void {
    while (curr_token.type != .EOL) {
        if (curr_token.type == .STRING or curr_token.type == .CHAR) {
            ut.createSymbol(d_size, &d_offset.*, curr_token.type, Number{ .slice = curr_token.value }) catch |err| return err;
            if (curr_token.type == .CHAR) data_arr.*.append(curr_token.value[0]) catch return compilerError.programError else {
                for (curr_token.value) |c|
                    data_arr.*.append(c) catch return compilerError.programError;
            }
        } else if (curr_token.type == .IMM) {
            const ch_num = ut.isANumOfAnyBase(curr_token.value, d_size) catch return compilerError.syntaxError;
            ut.createSymbol(d_size, &d_offset.*, curr_token.type, ch_num) catch |err| return err;
            if (ch_num == .int_u8) data_arr.*.append(ch_num.int_u8) catch return compilerError.syntaxError else {
                data_arr.*.append(@intCast(ch_num.int_u32 & 0xFF)) catch return compilerError.syntaxError;
                data_arr.*.append(@intCast((ch_num.int_u32 >> 8) & 0xFF)) catch return compilerError.syntaxError;
                data_arr.*.append(@intCast((ch_num.int_u32 >> 16) & 0xFF)) catch return compilerError.syntaxError;
                data_arr.*.append(@intCast((ch_num.int_u32 >> 24) & 0xFF)) catch return compilerError.syntaxError;
            }
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

fn createMem(t_offset: *usize) compilerError!operand {
    var n_op: operand = undefined;
    n_op.op_type = .MEM;

    t_offset.* += 1;

    if (curr_token.type == .IDENTIFIER) {
        n_op.value = Number{ .slice = curr_token.value };
        t_offset.* += 4;
    } else if (curr_token.type == .IMM) {
        n_op.value = ut.isANumOfAnyBase(curr_token.value, 1) catch return compilerError.syntaxError;
        if (n_op.value.? == .int_u8) return compilerError.syntaxError;
        t_offset.* += 4;
    } else if (curr_token.type == .REG) {
        n_op.value = Number{ .slice = curr_token.value };
        t_offset.* += 1;
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

fn checkOperands(t_offset: *usize) compilerError!instruction {
    var n_op: operand = undefined;
    var n_inst: instruction = undefined;
    var seekd_token = seekToken();
    if (curr_token.type == .INSTRUCTION_1OP) {
        // 1 byte inst
        t_offset.* += 1;
        // zig fmt: off
        if(seekd_token == .REG or seekd_token == .O_BRACKET){
            if(eql(u8, curr_token.value, "mul")
            or eql(u8, curr_token.value, "div")
            or eql(u8, curr_token.value, "pop")
            or eql(u8, curr_token.value, "neg")
            or eql(u8, curr_token.value, "jmp")
            or eql(u8, curr_token.value, "call")
            or eql(u8, curr_token.value, "dec")
            or eql(u8, curr_token.value, "inc")
            or eql(u8, curr_token.value, "not")){
                n_inst.opcode = curr_token;
                nextToken();
                if(seekd_token == .O_BRACKET){
                    nextToken();
                    n_op = createMem(&t_offset.*) catch |err| return err;
                }
                else {
                    n_op.value = Number{.slice = curr_token.value};
                    n_op.op_type = .REG;
                    if(!(eql(u8, curr_token.value, "pop")
                      or eql(u8, curr_token.value, "dec")
                      or eql(u8, curr_token.value, "inc"))) t_offset.* += 1;
                }
                n_inst.op1 = n_op;
            }
        }
        else if(seekd_token == .IMM){
            if(eql(u8, curr_token.value, "int")
            or eql(u8, curr_token.value, "push")){
                n_inst.opcode = curr_token;
                nextToken();
                const convd_num =  ut.isANumOfAnyBase(curr_token.value,1) catch return compilerError.syntaxError;
                t_offset.* += ut.retNumOfBytes(convd_num) catch |err| return err;
                n_op.value = convd_num; 
                n_op.op_type = curr_token.type;
                n_inst.op1 = n_op;
            }
        }
        else if(seekd_token == .IDENTIFIER){
            if(eql(u8, curr_token.value, "jmp")
            or eql(u8, curr_token.value, "je")
            or eql(u8, curr_token.value, "jne")
            or eql(u8, curr_token.value, "call")){
                n_inst.opcode = curr_token;
                nextToken();
                n_op.value = Number{.slice = curr_token.value};
                n_op.op_type = .IDENTIFIER;
                n_inst.op1 = n_op;
                t_offset.* += 4;
            }
        }
        else {return compilerError.invalidOperand;}
    }
    else if(curr_token.type == .INSTRUCTION_2OP){
            t_offset.* += 1;
            var n_op2: operand = undefined;
            if(eql(u8, curr_token.value, "mov")){
                if(seekd_token == .REG or seekd_token == .O_BRACKET){
                    n_inst.opcode = curr_token;
                    nextToken();
                    if(seekd_token == .O_BRACKET){
                        n_op = createMem(&t_offset.*) catch |err| return err;
                    }
                    else {
                        n_op.value = Number{.slice = curr_token.value};
                        n_op.op_type = .REG;
                        t_offset.* += 1;
                    }
                    n_inst.op1 = n_op;
                }
            nextToken();
            if(curr_token.type == .COMMA){}
            else {return compilerError.syntaxError;}
            seekd_token = seekToken();
            if(seekd_token == .REG or seekd_token == .O_BRACKET or seekd_token == .IMM or seekd_token == .IDENTIFIER){
                nextToken();
                if(curr_token.type == .O_BRACKET){
                    nextToken();
                    if(n_inst.op1.?.op_type == .MEM) {return compilerError.invalidOperand;}
                    n_op2 = createMem(&t_offset.*) catch |err| return err;
                }
                else {
                    n_op2.op_type = curr_token.type;
                    if(curr_token.type == .REG or curr_token.type == .IDENTIFIER)
                        n_op2.value = Number{.slice = curr_token.value} else { // IMM
                        n_op2.value = ut.isANumOfAnyBase(curr_token.value,1) catch return compilerError.syntaxError;
                    }
                    if(curr_token.type == .IMM or curr_token.type == .IDENTIFIER) t_offset.* += 4 else {
                        t_offset.* += 1;
                    }
                }
                if(n_op2.value.? == .int_u8) return compilerError.syntaxError;
                n_inst.op2 = n_op2;
            }
            else {return compilerError.invalidOperand;}
        }
        else if(eql(u8, curr_token.value, "add")
             or eql(u8, curr_token.value, "adc")
             or eql(u8, curr_token.value, "sub")
             or eql(u8, curr_token.value, "cmp")
             or eql(u8, curr_token.value, "xor")
             or eql(u8, curr_token.value, "and")
             or eql(u8, curr_token.value, "or")
             or eql(u8, curr_token.value, "test")){
            if(seekd_token == .REG or seekd_token == .O_BRACKET){
                n_inst.opcode = curr_token;
                nextToken();
                if(seekd_token == .O_BRACKET){
                    nextToken();
                    n_op = createMem(&t_offset.* ) catch |err| return err;
                }
                else {
                    n_op.value = Number{.slice = curr_token.value};
                    n_op.op_type = .REG;
                    t_offset.* += 1;
                }
            }
            nextToken();
            if(curr_token.type == .COMMA){}
            else {return compilerError.syntaxError;}
            seekd_token = seekToken();
            if(seekd_token == .REG or seekd_token == .IMM){
                nextToken();
                n_op2.op_type = curr_token.type;
                if(curr_token.type == .REG){
                    n_op2.value = Number{.slice = curr_token.value};
                    t_offset.* += 1;
                } else {
                    n_op2.value = ut.isANumOfAnyBase(curr_token.value,1) catch return compilerError.syntaxError; 
                    t_offset.* += 1;
                }
            }
            else {return compilerError.syntaxError;}
        }
    }
    else if(curr_token.type == .INSTRUCTION_O1OP){
        t_offset.* += 1;
        n_inst.opcode = curr_token;
        if(seekd_token == .IMM){
            nextToken();
            n_op.op_type = seekd_token;
            const convd_num = ut.isANumOfAnyBase(curr_token.value,1) catch return compilerError.syntaxError;
            if (convd_num.int_u32 >= std.math.minInt(u16) and convd_num.int_u32 <= std.math.maxInt(u16)) {
                    const conv_num_u16: u16 = @intCast(convd_num.int_u32);
                    n_op.value = Number{.int_u16 = conv_num_u16};
                    t_offset.* += 2;
            }
            else {return compilerError.syntaxError;}
            n_inst.op1 = n_op;
        }
        else if(seekd_token == .EOL) {}
        else {return compilerError.syntaxError;}    
    }
    else {return compilerError.syntaxError;}
    nextToken();
    if(curr_token.type != .EOL) return compilerError.syntaxError;
    return n_inst;
}

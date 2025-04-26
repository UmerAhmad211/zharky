const std = @import("std");
const eql = std.mem.eql;

const l = @import("lexer.zig");
const pp = @import("pretty_print_errs.zig");
const errorToken = pp.errorToken;
const compilerError = pp.compilerErrors;
const td = @import("token_def.zig");
const TokenType = td.TokenType;
const ut = @import("util.zig");
const Number = ut.Number;

var curr_token: l.Token = undefined;
var token_arr: ?*std.ArrayList(l.Token) = null;
var curr_index: usize = 0;

const operand = struct {
    op_type: TokenType,
    disp: ?Number,
    value: ?Number,
};

const instruction = struct {
    opcode: l.Token,
    op1: ?operand,
    op2: ?operand,
};

pub fn parse(tokenized_input: *std.ArrayList(l.Token), err_tok: *errorToken) bool {
    token_arr = tokenized_input;
    curr_token = token_arr.?.*.items[curr_index];

    // errors bubbling
    expectDataSection() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectData() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectTextSection() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };

    expectText() catch |err| {
        err_tok.*.error_type = err;
        err_tok.*.err_token = curr_token;
        return false;
    };
    return true;
}

// check data section key words i.e: section .data\n
fn expectDataSection() compilerError!void {
    const valid_token_arr = [3]TokenType{ .K_SECTION, .D_SECTION, .EOL };
    inline for (valid_token_arr) |tok| {
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
    inline for (valid_token_arr) |tok| {
        if (curr_token.type == tok) {
            nextToken();
        } else {
            return compilerError.syntaxError;
        }
    }
}

// msg db "Hi", Ah\n => ok
// msg db "hi",\n    => error
fn expectData() compilerError!void {
    while (curr_token.type == .IDENTIFIER) {
        if (curr_token.type == .IDENTIFIER) nextToken() else {
            return compilerError.syntaxError;
        }
        // zig fmt: off
        if (curr_token.type == .DB 
            or curr_token.type == .DD) nextToken() else {
            return compilerError.syntaxError;
        }
        // zig fmt: on
        if (!checkForDataCommaPattern()) {
            return compilerError.syntaxError;
        }
        nextToken();
    }
}

// check operands and syntax
fn expectText() compilerError!void {
    // zig fmt: off
    while (curr_token.type != .EOF) {
        var inst_line: instruction = undefined;
        if (curr_token.type == .IDENTIFIER) {
            nextToken();
            if (curr_token.type == .COLON) {
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
            inst_line = checkOperands() catch |err| return err;
        }
        else if (curr_token.type == .INSTRUCTION_2OP) {
            inst_line = checkOperands() catch |err| return err;
        }
        else if (curr_token.type == .INSTRUCTION_O1OP) {
            inst_line = checkOperands() catch |err| return err;
        }
        else {
            return compilerError.syntaxError;
        }

        if (curr_token.type != .EOL) {
            return compilerError.syntaxError;
        } 
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
fn checkForDataCommaPattern() bool {
    // zig fmt: off
    while (curr_token.type != .EOL) {
        if (curr_token.type == .STRING
            or curr_token.type == .CHAR
            or curr_token.type == .IMM
            or curr_token.type == .NUM) nextToken() else {
            return false;
        }
        if(curr_token.type == .EOL) {
            continue;
        }
        if(curr_token.type == .COMMA){
            const seeked_token = seekToken();
            if(seeked_token == .EOL){
                return false;
            }
            nextToken();
        }
        else {
            return false;
        }
    }
    // zig fmt: on
    return true;
}

fn createMem() compilerError!operand {
    var n_op: operand = undefined;
    n_op.op_type = .MEM;
    var pm: u2 = 2;

    if (curr_token.type == .IDENTIFIER) {
        n_op.value = Number{ .slice = curr_token.value };
    } else if (curr_token.type == .IMM) {
        n_op.disp = ut.isANumOfAnyBase(curr_token.value, .IMM) catch return compilerError.wrongNumFormat;
    } else if (curr_token.type == .REG) {
        if (eql(u8, curr_token.value, "eax")) {
            const seekd_token = seekToken();
            if (seekd_token != .C_BRACKET) return compilerError.eaxNoDisp;
        }
        n_op.value = Number{ .slice = curr_token.value };
    } else {
        return compilerError.syntaxError;
    }
    nextToken();

    if (curr_token.type == .C_BRACKET) {
        if (seekToken() == .EOL) {
            return n_op;
        }
        return compilerError.syntaxError;
    } else if (curr_token.type == .PLUS) {} else if (curr_token.type == .MINUS) {
        pm = 1;
    } else {
        return compilerError.syntaxError;
    }

    nextToken();

    if (curr_token.type == .IMM) {
        if (pm == 0) {
            n_op.disp = ut.isANumOfAnyBase(curr_token.value, .PLUS) catch return compilerError.wrongNumFormat;
        } else if (pm == 1) {
            n_op.disp = ut.isANumOfAnyBase(curr_token.value, .MINUS) catch return compilerError.wrongNumFormat;
        } else {
            n_op.disp = ut.isANumOfAnyBase(curr_token.value, .IMM) catch return compilerError.wrongNumFormat;
        }
    } else {
        return compilerError.syntaxError;
    }
    return n_op;
}

fn checkOperands() compilerError!instruction {
    var n_op: operand = undefined;
    var n_inst: instruction = undefined;
    var seekd_token = seekToken();
    if (curr_token.type == .INSTRUCTION_1OP) {
        // zig fmt: off
        if(seekd_token == .REG or seekd_token == .O_BRACKET){
            if(eql(u8, curr_token.value, "mul")
            or eql(u8, curr_token.value, "div")
            or eql(u8, curr_token.value, "pop")
            or eql(u8, curr_token.value, "push")
            or eql(u8, curr_token.value, "neg")
            or eql(u8, curr_token.value, "jmp")
            or eql(u8, curr_token.value, "call")
            or eql(u8, curr_token.value, "dec")
            or eql(u8, curr_token.value, "inc")
            or eql(u8, curr_token.value, "not")){
                n_inst.opcode = curr_token;
                nextToken();
                if(seekd_token == .O_BRACKET){
                    n_op = createMem() catch |err| return err;
                }
                else {
                    n_op.value = Number{.slice = curr_token.value};
                    n_op.op_type = .REG;
                }
                n_inst.op1 = n_op;
            }
        }
        else if(seekd_token == .IMM){
            if(eql(u8, curr_token.value, "int")
            or eql(u8, curr_token.value, "push")){
                n_inst.opcode = curr_token;
                nextToken();
                const convd_num =  ut.isANumOfAnyBase(curr_token.value,.IMM) catch return compilerError.syntaxError;
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
                // should be in symb table
                n_op.value = Number{.slice = curr_token.value};
                n_op.op_type = .IDENTIFIER;
                n_inst.op1 = n_op;
            }
        }
        else {return compilerError.syntaxError;}
    }
    else if(curr_token.type == .INSTRUCTION_2OP){
            var n_op2: operand = undefined;
            if(eql(u8, curr_token.value, "mov")){
                if(seekd_token == .REG or seekd_token == .O_BRACKET){
                    n_inst.opcode = curr_token;
                    nextToken();
                    if(seekd_token == .O_BRACKET){
                        n_op = createMem() catch |err| return err;
                    }
                    else {
                        n_op.value = Number{.slice = curr_token.value};
                        n_op.op_type = .REG;
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
                    else {n_op2 = createMem() catch |err| return err;}
                }
                else {
                    n_op2.op_type = curr_token.type;
                    if(curr_token.type == .REG or curr_token.type == .IDENTIFIER)
                        n_op2.value = Number{.slice = curr_token.value} else {
                        n_op2.value = ut.isANumOfAnyBase(curr_token.value,.IMM) catch return compilerError.wrongNumFormat;
                    }
                }
                n_inst.op2 = n_op2;
            }
            else {return compilerError.syntaxError;}
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
                    n_op = createMem() catch |err| return err;
                }
                else {
                    n_op.value = Number{.slice = curr_token.value};
                    n_op.op_type = .REG;
                }
            }
            nextToken();
            if(curr_token.type == .COMMA){}
            else {return compilerError.syntaxError;}
            seekd_token = seekToken();
            if(seekd_token == .REG or seekd_token == .IMM){
                nextToken();
                n_op2.op_type = curr_token.type;
                if(curr_token.type == .REG)
                    n_op2.value = Number{.slice = curr_token.value} else {
                    n_op2.value = ut.isANumOfAnyBase(curr_token.value,.IMM) catch return compilerError.wrongNumFormat; 
                }
            }
            else {return compilerError.syntaxError;}
        }
    }
    else if(curr_token.type == .INSTRUCTION_O1OP){
        n_inst.opcode = curr_token;
        if(seekd_token == .IMM){
            nextToken();
            n_op.op_type = seekd_token;
            const convd_num = ut.isANumOfAnyBase(curr_token.value,.IMM) catch return compilerError.wrongNumFormat;
            n_op.value = convd_num;
            n_inst.op1 = n_op;
        }
        else if(seekd_token == .EOL){nextToken();}
        else {return compilerError.syntaxError;}    
    }
    else {return compilerError.syntaxError;}
    nextToken();
    if(curr_token.type != .EOL) return compilerError.syntaxError;
    return n_inst;
}

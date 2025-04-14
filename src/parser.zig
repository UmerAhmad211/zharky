const std = @import("std");
const l = @import("lexer.zig");
const td = @import("token_def.zig");
const TokenType = td.TokenType;
const ut = @import("util.zig");
const eql = std.mem.eql;
var curr_token: l.Token = undefined;
var curr_index: u32 = 0;

// TODO: throw error from custom error set
pub fn parse(tokenized_input: *std.ArrayList(l.Token)) void {
    expectDataSection(tokenized_input);
    expectData(tokenized_input);
    expectTextSection(tokenized_input);
    expectText(tokenized_input);
}

fn expectDataSection(tokenized_input: *std.ArrayList(l.Token)) void {
    // zig fmt: off
    if ((curr_index + 2 < tokenized_input.items.len)
        and tokenized_input.items[curr_index].type == TokenType.K_SECTION
        and tokenized_input.items[curr_index + 1].type == TokenType.D_SECTION
        and tokenized_input.items[curr_index + 2].type == TokenType.EOL)
    {
        curr_index += 3;
        curr_token = tokenized_input.items[curr_index];
        return;
    }
    // zig fmt: on
    ut.printErrMsgAndExit("Error at data section.");
}

fn expectTextSection(tokenized_input: *std.ArrayList(l.Token)) void {
    // zig fmt: off
    if ((curr_index + 5 < tokenized_input.items.len)
        and tokenized_input.items[curr_index].type     == TokenType.K_SECTION
        and tokenized_input.items[curr_index + 1].type == TokenType.T_SECTION
        and tokenized_input.items[curr_index + 2].type == TokenType.EOL
        and tokenized_input.items[curr_index + 3].type == TokenType.K_GLOBAL
        and tokenized_input.items[curr_index + 4].type == TokenType.IDENTIFIER
        and tokenized_input.items[curr_index + 5].type == TokenType.EOL)
    {
        curr_index += 6;
        curr_token = tokenized_input.items[curr_index];
        return;
    }
    // zig fmt: on
    ut.printErrMsgAndExit("Error at text section.");
}

fn expectData(tokenized_input: *std.ArrayList(l.Token)) void {
    while (curr_token.type == TokenType.IDENTIFIER) {
        if (curr_token.type == TokenType.IDENTIFIER) nextToken(tokenized_input) else {
            ut.printErrMsgAndExit("Expect ID in data section.");
        }
        // zig fmt: off
        if (curr_token.type == TokenType.DB 
            or curr_token.type == TokenType.DW
            or curr_token.type == TokenType.DD) nextToken(tokenized_input) else {
            ut.printErrMsgAndExit("Expect data size in data section");
        }
        if (curr_token.type == TokenType.STRING 
            or curr_token.type == TokenType.CHAR 
            or curr_token.type == TokenType.IMM
            or curr_token.type == TokenType.NUM) nextToken(tokenized_input) else {
            ut.printErrMsgAndExit("Expect data in data section.");
        }
        const seeked_token = seekToken(tokenized_input);
        if (curr_token.type == TokenType.COMMA
            and (seeked_token == TokenType.STRING
            or seeked_token == TokenType.CHAR
            or seeked_token == TokenType.IMM
            or seeked_token == TokenType.NUM)) nextToken(tokenized_input)
        // zig fmt: on
        else if (curr_token.type == TokenType.EOL) {
            nextToken(tokenized_input);
            return;
        } else {
            ut.printErrMsgAndExit("Expect data type, standalone comma not allowd.");
        }
        nextToken(tokenized_input);
        if (curr_token.type == TokenType.EOL)
            nextToken(tokenized_input)
        else {
            ut.printErrMsgAndExit("Expect one data directive in one line.");
        }
    }
}

// to be changed
fn expectText(tokenzied_input: *std.ArrayList(l.Token)) void {
    while (curr_token.type != TokenType.EOF) {
        if (curr_token.type == TokenType.IDENTIFIER) {
            nextToken(tokenzied_input);
            if (curr_token.type == TokenType.COLON) nextToken(tokenzied_input) else ut.printErrMsgAndExit("Syntax error, colon expected.");
            if (curr_token.type == TokenType.EOL) nextToken(tokenzied_input) else ut.printErrMsgAndExit("Sytax error, one label reference at one line.");
        } else if (curr_token.type == TokenType.INSTRUCTION_0OP)
            nextToken(tokenzied_input)
        else if (curr_token.type == TokenType.INSTRUCTION_1OP) {
            nextToken(tokenzied_input);
            if (curr_token.type == TokenType.IDENTIFIER or curr_token.type == TokenType.REG) nextToken(tokenzied_input) else ut.printErrMsgAndExit("Syntax error,Wrong operand");
        }
    }
}

inline fn nextToken(tokenized_input: *std.ArrayList(l.Token)) void {
    if (curr_token.type != TokenType.EOF) {
        curr_index += 1;
        curr_token = tokenized_input.items[curr_index];
    }
}

fn seekToken(tokenized_input: *std.ArrayList(l.Token)) TokenType {
    if (curr_token.type != TokenType.EOF) return tokenized_input.items[curr_index + 1].type;
    return TokenType.ERR;
}

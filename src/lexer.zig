const std = @import("std");
const eql = std.mem.eql;

pub const td = @import("token_def.zig");
const ut = @import("util.zig");
const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const red = @import("pretty_print_errs.zig").red;
const reset = @import("pretty_print_errs.zig").reset;
const errorToken = @import("pretty_print_errs.zig").errorToken;

pub const Token = struct {
    type: td.TokenType,
    value: []const u8,
    curr_line: []const u8,
    row_no: usize,
    col_no: usize,
};

pub fn tokenizeInputStream(line: []const u8, tokenized_input: *std.ArrayList(Token), line_no: usize, err_tok: *errorToken) bool {
    var i: usize = 0;
    var err_occur: bool = false;
    var tok_ap: Token = undefined;

    while (i < line.len) : (i += 1) {
        switch (line[i]) {
            ',' => tok_ap = .{ .type = td.TokenType.COMMA, .value = ",", .curr_line = line, .row_no = line_no, .col_no = i + 1 },
            '[' => tok_ap = .{ .type = td.TokenType.O_BRACKET, .value = "[", .curr_line = line, .row_no = line_no, .col_no = i + 1 },
            ']' => tok_ap = .{ .type = td.TokenType.C_BRACKET, .value = "]", .curr_line = line, .row_no = line_no, .col_no = i + 1 },
            ':' => tok_ap = .{ .type = td.TokenType.COLON, .value = ":", .curr_line = line, .row_no = line_no, .col_no = i + 1 },
            ' ' => {
                continue;
            }, //skip whitesapces
            '\n' => {
                continue;
            },
            '\'' => {
                // 'A','2'
                if ((i + 2 < line.len) and line[i + 2] == '\'') {
                    if (std.ascii.isASCII(line[i + 1])) {
                        tok_ap = .{ .type = td.TokenType.CHAR, .value = line[i + 1 .. i + 2], .curr_line = line, .row_no = line_no, .col_no = i + 1 };
                    } else {
                        err_tok.*.error_type = compilerError.onlyASCII;
                        err_occur = true;
                    }
                    i += 2;
                } else {
                    // not finding closing single quote
                    err_tok.*.error_type = compilerError.noClosingQuote;
                    err_occur = true;
                }
            },
            '\"' => {
                var enc_end_quote: bool = false;
                var inner_index: usize = i + 1;
                // read string
                while (inner_index < line.len) {
                    if (line[inner_index] == '\"') {
                        enc_end_quote = true;
                        break;
                    }
                    inner_index += 1;
                }
                if (inner_index < line.len and enc_end_quote) {
                    tok_ap = .{ .type = td.TokenType.STRING, .value = line[i + 1 .. inner_index], .curr_line = line, .row_no = line_no, .col_no = i + 1 };
                    i = inner_index;
                } else {
                    // not finding closing double quote
                    err_tok.*.error_type = compilerError.noClosingQuote;
                    err_occur = true;
                }
            },
            else => {
                // read till a delimiter
                var inner_index: usize = i;
                while (inner_index < line.len) {
                    if (!ut.containsChar(&td.single_char, line[inner_index])) {
                        inner_index += 1;
                    } else {
                        break;
                    }
                }

                // check on tokens
                const conv_if_num = ut.isANumOfAnyBase(line[i..inner_index], 0);

                // zig fmt: off
                var token_type: td.TokenType = undefined;

                if(conv_if_num != compilerError.programError) token_type = .IMM 
                else if (eql(u8,line[i..inner_index],td.k_global)) token_type = td.TokenType.K_GLOBAL
                else if (eql(u8,line[i..inner_index],td.start)) token_type = td.TokenType.START
                else if (eql(u8,line[i..inner_index],td.k_section)) token_type = td.TokenType.K_SECTION
                else if (eql(u8,line[i..inner_index],td.t_section)) token_type = td.TokenType.T_SECTION
                else if (eql(u8,line[i..inner_index],td.d_section)) token_type = td.TokenType.D_SECTION
                else if (eql(u8,line[i..inner_index],td.db)) token_type = td.TokenType.DB
                else if (eql(u8,line[i..inner_index],td.dd)) token_type = td.TokenType.DD
                else if (ut.containsStr(td.instructions_0op, line[i..inner_index])) token_type = td.TokenType.INSTRUCTION_0OP
                else if (ut.containsStr(td.instructions_1op, line[i..inner_index])) token_type = td.TokenType.INSTRUCTION_1OP
                else if (ut.containsStr(td.instructions_2op, line[i..inner_index])) token_type = td.TokenType.INSTRUCTION_2OP
                else if (ut.containsStr(td.instructions_optional_1op, line[i..inner_index])) token_type = td.TokenType.INSTRUCTION_O1OP
                else if (ut.containsStr(td.regs, line[i..inner_index])) token_type = td.TokenType.REG
                else token_type = td.TokenType.IDENTIFIER;
                // zig fmt: on

                tok_ap = .{ .type = token_type, .value = line[i..inner_index], .curr_line = line, .row_no = line_no, .col_no = i + 1 };
                i = inner_index - 1;
            },
        }
        if (err_occur) {
            err_tok.*.err_token = tok_ap;
            return false;
        }
        tokenized_input.append(tok_ap) catch {
            err_tok.*.err_token = tok_ap;
            return false;
        };
    }
    // EOL to separate each instruction
    tokenized_input.append(.{ .type = td.TokenType.EOL, .value = "\n", .curr_line = line, .row_no = line_no, .col_no = i + 1 }) catch {
        err_tok.*.err_token = tok_ap;
        return false;
    };
    return true;
}

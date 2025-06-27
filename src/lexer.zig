const std = @import("std");
const eql = std.mem.eql;

pub const td = @import("token_def.zig");
const ut = @import("util.zig");
const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const red = @import("pretty_print_errs.zig").red;
const reset = @import("pretty_print_errs.zig").reset;
const errorToken = @import("pretty_print_errs.zig").errorToken;
const Regs = td.Regs;

pub const Token = struct {
    type: td.TokenType,
    value: []const u8,
    curr_line: []const u8,
    row_no: usize,
    col_no: usize,
};

pub const Lexer = struct {
    pub const Keywords = std.StaticStringMap(td.TokenType).initComptime(.{
        .{ "global", .K_GLOBAL },
        .{ "section", .K_SECTION },
        .{ "_start", .START },
        .{ ".text", .T_SECTION },
        .{ ".data", .D_SECTION },
        .{ "hlt", .INSTRUCTION_0OP },
        .{ "nop", .INSTRUCTION_0OP },
        .{ "pop", .INSTRUCTION_1OP },
        .{ "push", .INSTRUCTION_1OP },
        .{ "int", .INSTRUCTION_1OP },
        .{ "jmp", .INSTRUCTION_1OP },
        .{ "je", .INSTRUCTION_1OP },
        .{ "jne", .INSTRUCTION_1OP },
        .{ "call", .INSTRUCTION_1OP },
        .{ "dec", .INSTRUCTION_1OP },
        .{ "inc", .INSTRUCTION_1OP },
        .{ "mov", .INSTRUCTION_2OP },
        .{ "add", .INSTRUCTION_2OP },
        .{ "cmp", .INSTRUCTION_2OP },
        .{ "ret", .INSTRUCTION_O1OP },
        .{ "db", .DB },
        .{ "dd", .DD },
    });

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
                ' ' => continue,
                ';' => return true,
                '\'' => {
                    if ((i + 2 < line.len) and line[i + 2] == '\'') {
                        if (std.ascii.isASCII(line[i + 1])) {
                            tok_ap = .{ .type = td.TokenType.CHAR, .value = line[i + 1 .. i + 2], .curr_line = line, .row_no = line_no, .col_no = i + 1 };
                        } else {
                            err_tok.*.error_type = compilerError.onlyASCII;
                            err_occur = true;
                        }
                        i += 2;
                    } else {
                        err_tok.*.error_type = compilerError.noClosingQuote;
                        err_occur = true;
                    }
                },
                '\"' => {
                    var enc_end_quote: bool = false;
                    var inner_index: usize = i + 1;
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
                        err_tok.*.error_type = compilerError.noClosingQuote;
                        err_occur = true;
                    }
                },
                else => {
                    var inner_index: usize = i;
                    while (inner_index < line.len) {
                        if (!ut.containsChar(&td.single_char, line[inner_index])) {
                            inner_index += 1;
                        } else {
                            break;
                        }
                    }

                    // check on tokens
                    const conv_if_num = ut.isANumOfAnyBase(line[i..inner_index], true);

                    var token_type: td.TokenType = undefined;

                    if (conv_if_num != compilerError.programError) {
                        token_type = .IMM;
                    } else if (Regs.has(line[i..inner_index])) {
                        token_type = .REG;
                    } else if (Keywords.get(line[i..inner_index])) |kw| {
                        token_type = kw;
                    } else {
                        token_type = td.TokenType.IDENTIFIER;
                    }

                    tok_ap = .{ .type = token_type, .value = line[i..inner_index], .curr_line = line, .row_no = line_no, .col_no = i + 1 };
                    i = inner_index - 1;
                },
            }
            if (err_occur) {
                err_tok.*.err_token = tok_ap;
                return false;
            }
            tokenized_input.append(tok_ap) catch {
                err_tok.*.error_type = compilerError.programError;
                return false;
            };
        }
        tokenized_input.append(.{ .type = td.TokenType.EOL, .value = "\n", .curr_line = line, .row_no = line_no, .col_no = i + 1 }) catch {
            err_tok.*.err_token = tok_ap;
            return false;
        };
        return true;
    }
};

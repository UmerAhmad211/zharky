const std = @import("std");
const ut = @import("util.zig");
pub const td = @import("token_def.zig");
const expect = std.testing.expect;

pub const Token = struct {
    type: td.TokenType,
    value: []const u8,
};

pub fn tokenizeInputStream(line: []const u8, tokenized_input: *std.ArrayList(Token)) !void {
    var i: usize = 0;

    while (i < line.len) : (i += 1) {
        switch (line[i]) {
            ',' => try tokenized_input.append(.{ .type = td.TokenType.COMMA, .value = "," }),
            '[' => try tokenized_input.append(.{ .type = td.TokenType.O_BRACKET, .value = "[" }),
            ']' => try tokenized_input.append(.{ .type = td.TokenType.C_BRACKET, .value = "]" }),
            ':' => try tokenized_input.append(.{ .type = td.TokenType.COLON, .value = ":" }),
            '+' => try tokenized_input.append(.{ .type = td.TokenType.PLUS, .value = "+" }),
            '-' => try tokenized_input.append(.{ .type = td.TokenType.MINUS, .value = "-" }),
            '*' => try tokenized_input.append(.{ .type = td.TokenType.STAR, .value = "*" }),
            ' ' => {}, //skip whitesapces
            '\'' => {
                // 'A','2'
                if ((i + 2 < line.len) and line[i + 2] == '\'') {
                    if (std.ascii.isDigit(line[i + 1])) {
                        try tokenized_input.append(.{ .type = td.TokenType.NUM, .value = line[i + 1 .. i + 2] });
                    } else if (std.ascii.isASCII(line[i + 1])) {
                        try tokenized_input.append(.{ .type = td.TokenType.CHAR, .value = line[i + 1 .. i + 2] });
                    }
                    i += 2;
                } else {
                    // not finding closing single quote
                    std.debug.print("ZHARKY: Error: Unexpected token.\n", .{});
                    std.process.exit(1);
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
                    try tokenized_input.append(.{ .type = td.TokenType.STRING, .value = line[i + 1 .. inner_index] });
                    i = inner_index;
                } else {
                    // not finding closing single quote
                    std.debug.print("ZHARKY: Error: Unexpected token.\n", .{});
                    std.process.exit(1);
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
                const conv_if_num = ut.isANumOfAnyBase(line[i..inner_index]);
                var token_type: td.TokenType = undefined;
                // zig fmt: off
                if (conv_if_num != ut.NumError.NumConv 
                    and conv_if_num != ut.NumError.InvalidNumBase
                    and conv_if_num != ut.NumError.DefaultError)
                {
                    token_type = td.TokenType.IMM;
                }
                    // zig fmt: on
                else if (ut.containsStr(td.keyword, line[i..inner_index])) {
                    token_type = td.TokenType.KEYWORD;
                } else if (ut.containsStr(td.section_name, line[i..inner_index])) {
                    token_type = td.TokenType.SECTION_NAME;
                } else if (ut.containsStr(td.instructions, line[i..inner_index])) {
                    token_type = td.TokenType.INSTRUCTION;
                } else if (ut.containsStr(td.size, line[i..inner_index])) {
                    token_type = td.TokenType.SIZE;
                } else if (ut.containsStr(td.regs, line[i..inner_index])) {
                    token_type = td.TokenType.REG;
                } else {
                    token_type = td.TokenType.IDENTIFIER;
                }
                try tokenized_input.append(.{ .type = token_type, .value = line[i..inner_index] });
                i = inner_index - 1;
            },
        }
    }
    // EOL to separate each instruction
    try tokenized_input.append(.{ .type = td.TokenType.EOL, .value = "\n" });
}

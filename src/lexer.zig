const std = @import("std");
const ut = @import("util.zig");
const td = @import("token_def.zig");

pub const Token = struct {
    type: td.TokenType,
    value: []const u8,
};

pub fn tokenizeInputStream(line: []const u8, tokenized_input: *std.ArrayList(Token)) !void {
    var i: usize = 0;

    while (i < line.len) : (i += 1) {
        switch (line[i]) {
            ',' => try tokenized_input.append(.{ .type = td.TokenType.COMMA, .value = &[_]u8{line[i]} }),
            '[' => try tokenized_input.append(.{ .type = td.TokenType.O_BRACKET, .value = &[_]u8{line[i]} }),
            ']' => try tokenized_input.append(.{ .type = td.TokenType.C_BRACKET, .value = &[_]u8{line[i]} }),
            ' ' => try tokenized_input.append(.{ .type = td.TokenType.WHITE_SPACE, .value = &[_]u8{line[i]} }),
            ':' => try tokenized_input.append(.{ .type = td.TokenType.COLON, .value = &[_]u8{line[i]} }),
            '+' => try tokenized_input.append(.{ .type = td.TokenType.PLUS, .value = &[_]u8{line[i]} }),
            '-' => try tokenized_input.append(.{ .type = td.TokenType.MINUS, .value = &[_]u8{line[i]} }),
            '*' => try tokenized_input.append(.{ .type = td.TokenType.STAR, .value = &[_]u8{line[i]} }),
            '\'' => {
                if ((i + 2 < line.len) and line[i + 2] == '\'') {
                    if (std.ascii.isDigit(line[i + 1])) {
                        try tokenized_input.append(.{ .type = td.TokenType.NUM, .value = &[_]u8{line[i + 1]} });
                    } else if (std.ascii.isASCII(line[i + 1])) {
                        try tokenized_input.append(.{ .type = td.TokenType.CHAR, .value = &[_]u8{line[i + 1]} });
                    }
                    i += 2;
                } else {
                    std.debug.print("ZHARKY: Error: Unexpected token.", .{});
                    std.process.exit(1);
                }
            },
            '\"' => {
                var delim_enc: bool = false;
                var inner_index: usize = i + 1;
                while ((inner_index < line.len) and line[inner_index] != '\"') {
                    if (ut.containsChar(&td.single_char, line[inner_index])) delim_enc = true;
                    inner_index += 1;
                }
                if (inner_index < line.len and !delim_enc) {
                    try tokenized_input.append(.{ .type = td.TokenType.STRING, .value = line[i + 1 .. inner_index] });
                    i += inner_index;
                } else {
                    std.debug.print("ZHARKY: Error: Unexpected token.", .{});
                    std.process.exit(1);
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
                const conv_if_num = ut.isANumOfAnyBase(line[i..inner_index]);
                var token_type: td.TokenType = undefined;
                if (conv_if_num != ut.NumError.NumConv or conv_if_num != ut.NumError.InvalidNumBase) {
                    token_type = td.TokenType.IMM;
                } else if (ut.containsStr(td.keyword, line[i..inner_index])) {
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
                i += inner_index - 1;
                try tokenized_input.append(.{ .type = token_type, .value = line[i..inner_index] });
            },
        }
    }
    try tokenized_input.append(.{ .type = td.TokenType.EOL, .value = "\n" });
}

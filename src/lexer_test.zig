const std = @import("std");
const expect = std.testing.expect;
const l = @import("lexer.zig");

// tests for lexer
test "Testing mov imm to reg" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const mov_imm_to_const = "mov eax,1234d";
    var t_tokenized_input = std.ArrayList(l.Token).init(allocator);
    try l.tokenizeInputStream(mov_imm_to_const, &t_tokenized_input);

    try expect(std.mem.eql(u8, t_tokenized_input.items[0].value, "mov"));
    try expect(t_tokenized_input.items[0].type == l.td.TokenType.INSTRUCTION);

    try expect(std.mem.eql(u8, t_tokenized_input.items[1].value, "eax"));
    try expect(t_tokenized_input.items[1].type == l.td.TokenType.REG);

    try expect(std.mem.eql(u8, t_tokenized_input.items[2].value, ","));
    try expect(t_tokenized_input.items[2].type == l.td.TokenType.COMMA);

    try expect(std.mem.eql(u8, t_tokenized_input.items[3].value, "1234d"));
    try expect(t_tokenized_input.items[3].type == l.td.TokenType.IMM);

    try expect(std.mem.eql(u8, t_tokenized_input.items[4].value, "\n"));
    try expect(t_tokenized_input.items[4].type == l.td.TokenType.EOL);
}

test "Testing section data" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const sec_data = "section .data";
    var t_tokenized_input = std.ArrayList(l.Token).init(allocator);
    try l.tokenizeInputStream(sec_data, &t_tokenized_input);

    try expect(std.mem.eql(u8, t_tokenized_input.items[0].value, "section"));
    try expect(t_tokenized_input.items[0].type == l.td.TokenType.KEYWORD);

    try expect(std.mem.eql(u8, t_tokenized_input.items[1].value, ".data"));
    try expect(t_tokenized_input.items[1].type == l.td.TokenType.SECTION_NAME);

    try expect(std.mem.eql(u8, t_tokenized_input.items[2].value, "\n"));
    try expect(t_tokenized_input.items[2].type == l.td.TokenType.EOL);
}

test "Testing section text" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const sec_data = "section .text";
    var t_tokenized_input = std.ArrayList(l.Token).init(allocator);
    try l.tokenizeInputStream(sec_data, &t_tokenized_input);

    try expect(std.mem.eql(u8, t_tokenized_input.items[0].value, "section"));
    try expect(t_tokenized_input.items[0].type == l.td.TokenType.KEYWORD);

    try expect(std.mem.eql(u8, t_tokenized_input.items[1].value, ".text"));
    try expect(t_tokenized_input.items[1].type == l.td.TokenType.SECTION_NAME);

    try expect(std.mem.eql(u8, t_tokenized_input.items[2].value, "\n"));
    try expect(t_tokenized_input.items[2].type == l.td.TokenType.EOL);
}

test "Testing Strings" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const sec_data = "msg db \"Hello, world\"";
    var t_tokenized_input = std.ArrayList(l.Token).init(allocator);
    try l.tokenizeInputStream(sec_data, &t_tokenized_input);

    try expect(std.mem.eql(u8, t_tokenized_input.items[0].value, "msg"));
    try expect(t_tokenized_input.items[0].type == l.td.TokenType.IDENTIFIER);

    try expect(std.mem.eql(u8, t_tokenized_input.items[1].value, "db"));
    try expect(t_tokenized_input.items[1].type == l.td.TokenType.KEYWORD);

    try expect(std.mem.eql(u8, t_tokenized_input.items[2].value, "Hello, world"));
    try expect(t_tokenized_input.items[2].type == l.td.TokenType.STRING);

    try expect(std.mem.eql(u8, t_tokenized_input.items[3].value, "\n"));
    try expect(t_tokenized_input.items[3].type == l.td.TokenType.EOL);
}

test "Testing Chars" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const sec_data = "msg db \'H\',\'e\'";
    var t_tokenized_input = std.ArrayList(l.Token).init(allocator);
    try l.tokenizeInputStream(sec_data, &t_tokenized_input);

    try expect(std.mem.eql(u8, t_tokenized_input.items[0].value, "msg"));
    try expect(t_tokenized_input.items[0].type == l.td.TokenType.IDENTIFIER);

    try expect(std.mem.eql(u8, t_tokenized_input.items[1].value, "db"));
    try expect(t_tokenized_input.items[1].type == l.td.TokenType.KEYWORD);

    try expect(std.mem.eql(u8, t_tokenized_input.items[2].value, "H"));
    try expect(t_tokenized_input.items[2].type == l.td.TokenType.CHAR);

    try expect(std.mem.eql(u8, t_tokenized_input.items[3].value, ","));
    try expect(t_tokenized_input.items[3].type == l.td.TokenType.COMMA);

    try expect(std.mem.eql(u8, t_tokenized_input.items[4].value, "e"));
    try expect(t_tokenized_input.items[4].type == l.td.TokenType.CHAR);

    try expect(std.mem.eql(u8, t_tokenized_input.items[5].value, "\n"));
    try expect(t_tokenized_input.items[5].type == l.td.TokenType.EOL);
}

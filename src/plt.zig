const std = @import("std");
const ut = @import("util.zig");
const tg_elf = @import("targets/elf.zig");
const tg_win = @import("targets/win.zig");
const td = @import("token_def.zig");
const l = @import("lexer.zig");
const p = @import("parser.zig");

pub fn process(file_name: []const u8) !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // allocate lines
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    // free lines
    defer for (lines.items) |line|
        allocator.free(line);

    // hold encodings
    var encodings = std.ArrayList(u8).init(allocator);
    defer encodings.deinit();

    // set target headers
    if (std.mem.eql(u8, ut.out_file_type, "-elf32")) {
        try tg_elf.tgELF32(&encodings);
    } else if (std.mem.eql(u8, ut.out_file_type, "-win32")) {
        tg_win.tgWIN32(&encodings);
    }

    try ut.readFileStoreAndTrim(&lines, &allocator, file_name);
    // lexer tokens
    var tokenized_input = std.ArrayList(l.Token).init(allocator);
    defer tokenized_input.deinit();

    // line no. to be used inform user where the error occured
    for (lines.items) |line|
        try l.tokenizeInputStream(line, &tokenized_input);

    try tokenized_input.append(.{ .type = td.TokenType.EOF, .value = "eof" });

    printDebugLexer(&tokenized_input);

    p.parse(&tokenized_input);
    std.debug.print("Parsing success.\n", .{});

    // file
    //const file = try std.fs.cwd().createFile(ut.out_file_name, .{ .truncate = false });
    //defer file.close();

    //_ = try file.writeAll(try encodings.toOwnedSlice());
}

fn printDebugLexer(tokenized_input: *std.ArrayList(l.Token)) void {
    for (tokenized_input.items) |item| {
        if (item.type == td.TokenType.EOL) {
            std.debug.print("EOL--\n", .{});
            continue;
        }
        std.debug.print("{s}--{}\n", .{ item.value, item.type });
    }
}

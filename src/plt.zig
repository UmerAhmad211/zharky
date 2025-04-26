const std = @import("std");

const l = @import("lexer.zig");
const p = @import("parser.zig");
const pp = @import("pretty_print_errs.zig");
const errorToken = pp.errorToken;
const compilerError = pp.compilerErrors;
const tg_elf = @import("targets/elf.zig");
const tg_win = @import("targets/win.zig");
const td = @import("token_def.zig");
const ut = @import("util.zig");

pub fn process(file_name: []const u8) !void {
    // allocator
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // allocate lines
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    // free lines
    defer for (lines.items) |line|
        allocator.free(line);

    try ut.readFileStoreAndTrim(&lines, &allocator, file_name);
    // lexer tokens
    var tokenized_input = std.ArrayList(l.Token).init(allocator);
    defer tokenized_input.deinit();

    var line_no: usize = 1;

    // lexer loop
    for (lines.items) |line| {
        try l.tokenizeInputStream(line, &tokenized_input, &line_no);
        line_no += 1;
    }
    try tokenized_input.append(.{ .type = td.TokenType.EOF, .value = "eof", .curr_line = undefined, .row_no = line_no, .col_no = 1 });

    printDebugLexer(&tokenized_input);

    var err_tok: errorToken = undefined;
    // parser
    if (!p.parse(&tokenized_input, &err_tok))
        pp.printErrMsgAndExit(&err_tok);
    std.debug.print("Parsing success.\n", .{});

    // hold encodings
    var encodings = std.ArrayList(u8).init(allocator);
    defer encodings.deinit();

    // set target headers
    if (std.mem.eql(u8, ut.out_file_type, "-elf32")) {
        try tg_elf.tgELF32(&encodings);
    } else if (std.mem.eql(u8, ut.out_file_type, "-win32")) {
        tg_win.tgWIN32(&encodings);
    }

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

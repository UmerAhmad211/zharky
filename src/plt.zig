const std = @import("std");
const ut = @import("util.zig");
const as = @import("assembler.zig");

// an asm line can have label: operator op1,op1 ;comment
pub const Mnemonics = struct {
    label: []const u8,
    operator: []const u8,
    op1: []const u8,
    op2: []const u8,
    line_no: u32,

    pub fn defaultConstructor() Mnemonics {
        return .{
            .label = "",
            .operator = "",
            .op1 = "",
            .op2 = "",
            .line_no = 0,
        };
    }
};

pub fn process(file_name: []const u8) !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // file
    const file = try std.fs.cwd().createFile(ut.out_file_name, .{});
    defer file.close();

    // allocate lines
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    // free lines
    defer for (lines.items) |line|
        allocator.free(line);

    // hold encodings
    var encodings = std.ArrayList(u8).init(allocator);
    defer encodings.deinit();

    try ut.readFileStoreAndTrim(&lines, &allocator, file_name);
    var line_no: u32 = 1;
    for (lines.items) |line| {
        tokenizeAndCheckForErr(line, line_no, &encodings);
        line_no += 1;
    }

    _ = try file.writeAll(try encodings.toOwnedSlice());
}

pub fn tokenizeAndCheckForErr(line: []const u8, line_no: u32, encodings: *std.ArrayList(u8)) void {
    var temp_tokens = [4][]const u8{ "", "", "", "" };
    // delimiters for tokens
    const delimiters = ";:$%%";
    // where original tokens are stored
    var tokens = Mnemonics.defaultConstructor();
    var line_stripped = line;
    //strip comment
    var index = std.mem.indexOf(u8, line, &[_]u8{delimiters[0]});
    if (index) |i|
        line_stripped = line[0..i];

    var iter_count: u32 = 1;
    var end_of_line: bool = false;

    // main tokenizing loop and partial semantic analyzer
    while (iter_count < 5) : (iter_count += 1) {
        line_stripped = std.mem.trim(u8, line_stripped, " ");
        index = std.mem.indexOf(u8, line_stripped, &[_]u8{delimiters[iter_count]});
        if (index) |i| {
            if (i + 1 < line_stripped.len) {
                if (iter_count != 1 and line_stripped[i + 1] != ' ') {
                    std.debug.print("ZHARKY: Error at line {d}.\n", .{line_no});
                    std.process.exit(1);
                }
            } else end_of_line = true;
            temp_tokens[iter_count - 1] = line_stripped[0..i];
            line_stripped = line_stripped[i + 1 ..];
        } else if (end_of_line) break;
    }

    // error if still tokens left (they were not valid so they remaind)
    if (line_stripped.len != 0) {
        std.debug.print("ZHARKY: Error at line {d}.\n", .{line_no});
        std.process.exit(1);
    }

    // store tokens
    tokens.line_no = line_no;
    tokens.label = temp_tokens[0];
    tokens.operator = temp_tokens[1];
    tokens.op1 = temp_tokens[2];
    tokens.op2 = temp_tokens[3];

    as.compareOperand(&tokens, encodings);
}

const std = @import("std");
const ut = @import("util.zig");

// an asm line may have label: operator op1,op1 ;comment
const Mnemonics = struct {
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

    // allocate lines
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();

    try ut.readFileStoreAndTrim(&lines, &allocator, file_name);
    for (lines.items) |line|
        std.debug.print("{s}", .{line});

    // free lines
    for (lines.items) |line|
        allocator.free(line);
}

pub fn tokenizeAndClassify(line: []const u8) void {
    // init
    var tokens: Mnemonics = Mnemonics.defaultConstructor();
    var line_no_comm = line;
    var indexs = std.mem.indexOf(u8, line, ";");
    if (indexs) |index|
        line_no_comm = line[0..index];

    indexs = std.mem.indexOf(u8, line_no_comm, ":");
    if (indexs) |index| {
        tokens.label = line_no_comm[0..index];
        if (index + 1 < line_no_comm.len)
            line_no_comm = line_no_comm[index + 1 ..];
    }

    line_no_comm = std.mem.trim(u8, line_no_comm, " ");

    indexs = std.mem.indexOf(u8, line_no_comm, " ");
    if (indexs) |index| {
        tokens.operator = line_no_comm[0..index];
        if (index + 1 < line_no_comm.len)
            line_no_comm = line_no_comm[index + 1 ..];
    }

    line_no_comm = std.mem.trim(u8, line_no_comm, " ");

    indexs = std.mem.indexOf(u8, line_no_comm, ",");
    if (indexs) |index| {
        tokens.op1 = line_no_comm[0..index];
        if (index + 1 < line_no_comm.len)
            line_no_comm = line_no_comm[index + 1 ..];
    }

    tokens.op2 = line_no_comm;
}

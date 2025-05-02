const std = @import("std");
const ut = @import("src/util.zig");
const plt = @import("src/plt.zig");

pub fn main() !void {
    // allocator
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // alloc args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    try ut.assemblerDriver(args);
    try plt.process(args[1]);
}

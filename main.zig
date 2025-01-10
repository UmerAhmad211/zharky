const std = @import("std");
const ut = @import("src/util.zig");
const plt = @import("src/plt.zig");

pub fn main() !void {
    // allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // alloc args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("SASM: Expected file name only.\n", .{});
        std.process.exit(1);
    }
    _ = ut.validFileExtension(args[1]);
    try plt.process(args[1]);
}

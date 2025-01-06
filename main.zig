const std = @import("std");
const ut = @import("src/util.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.debug.print("SASM: Expected file name only.\n", .{});
    }
    _ = ut.validFileExtension(args[1]);
}

const std = @import("std");

pub fn tgWIN32(encodings: *std.ArrayList(u8)) void {
    _ = encodings;
    std.debug.print("ZHARKY: Windows not implemented.\n", .{});
    std.process.exit(1);
}

const std = @import("std");

pub fn tgWIN32(header: *std.ArrayList(u8)) void {
    _ = header;
    std.debug.print("ZHARKY: Windows not implemented.\n", .{});
    std.process.exit(1);
}

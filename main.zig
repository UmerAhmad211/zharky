const std = @import("std");
const ut = @import("src/util.zig");
const ad = @import("src/asm_driver.zig");
const pp = @import("src/pretty_print_errs.zig");
const errorToken = pp.errorToken;

pub fn main() !void {
    var dbg = std.heap.DebugAllocator(.{}){};
    defer _ = dbg.deinit();
    const allocator = dbg.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var err_tok: errorToken = undefined;
    ut.assemblerDriver(args) catch |err| {
        err_tok.error_type = err;
        pp.printErrMsgAndExit(&err_tok);
    };

    ad.process(args[1]) catch |err| {
        err_tok.error_type = err;
        pp.printErrMsgAndExit(&err_tok);
    };
}

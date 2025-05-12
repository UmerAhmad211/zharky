const std = @import("std");
const ut = @import("src/util.zig");
const plt = @import("src/plt.zig");
const pp = @import("src/pretty_print_errs.zig");
const errorToken = pp.errorToken;

pub fn main() !void {
    // allocator
    var dbg = std.heap.DebugAllocator(.{}){};
    defer _ = dbg.deinit();
    const allocator = dbg.allocator();

    // alloc args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // bubble errs
    var err_tok: errorToken = undefined;
    ut.assemblerDriver(args) catch |err| {
        err_tok.error_type = err;
        pp.printErrMsgAndExit(&err_tok);
    };

    plt.process(args[1]) catch |err| {
        err_tok.error_type = err;
        pp.printErrMsgAndExit(&err_tok);
    };
}

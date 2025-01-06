const std = @import("std");
const asm_extension: []const u8 = ".asm";

pub fn validFileExtension(file_name: []const u8) bool {
    const validator = std.mem.indexOf(u8, file_name, asm_extension);
    if (validator) |_| {
        const file = std.fs.cwd().openFile(file_name, .{});
        const file_res = file catch |err| {
            std.debug.print("{}\n", .{err});
            std.process.exit(1);
        };
        defer file_res.close();
        return true;
    }
    return false;
}

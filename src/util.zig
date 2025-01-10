const std = @import("std");

// only .asm files allowed
pub fn validFileExtension(file_name: []const u8) bool {
    const asm_extension: []const u8 = ".asm";
    // rets index of where .asm is found
    const validator = std.mem.indexOf(u8, file_name, asm_extension);
    // discard capture
    if (validator) |_|
        return true;
    return false;
}

pub fn readFileStoreAndTrim(lines: *std.ArrayList([]const u8), allocator: *const std.mem.Allocator, file_name: []const u8) !void {
    // buffer i.e: file line
    var buf = std.ArrayList(u8).init(allocator.*);
    defer buf.deinit();

    // file
    // err when file not found
    const file = std.fs.cwd().openFile(file_name, .{}) catch |err|
        switch (err) {
        error.FileNotFound => {
            std.debug.print("SASM: file not found.\n", .{});
            std.process.exit(1);
        },
        else => {
            std.debug.print("SASM: {}\n", .{err});
            std.process.exit(1);
        },
    };
    defer file.close();
    var buf_rdr = std.io.bufferedReader(file.reader());
    const rdr = buf_rdr.reader();

    while (true) {
        // clear buf each time
        buf.clearRetainingCapacity();
        // read each line and store it in buf
        rdr.streamUntilDelimiter(buf.writer(), '\n', null) catch |err|
            switch (err) {
            // switch on err, if end of stream append and break
            error.EndOfStream => {
                if (buf.items.len > 0) {
                    // append copy of buf to lines and trim
                    if (buf.items[0] != '\n') {
                        const trimmed_buf = std.mem.trim(u8, buf.items, " \r\n\t");
                        try lines.append(try allocator.dupe(u8, trimmed_buf));
                    }
                }
                break;
            },
            // err out
            else => {
                std.debug.print("Err: {}\n", .{err});
                std.process.exit(1);
            },
        };
        // append copy of buf to lines and trim
        if (buf.items.len > 0) {
            if (buf.items[0] != '\n') {
                const trimmed_buf = std.mem.trim(u8, buf.items, " \r\n\t");
                try lines.append(try allocator.dupe(u8, trimmed_buf));
            }
        }
    }
}

const std = @import("std");

const td = @import("token_def.zig");

pub const NumError = error{ InvalidNumBase, NumConv, DefaultError };
pub const AsmError = error{InvalidRegister};
pub var out_file_name: []const u8 = undefined;
pub var out_file_type: []const u8 = undefined;

pub const Number = union {
    int_i8: i8,
    int_i32: i32,
    int_u32: u32,
    slice: []const u8,
};

// operand types
pub const OperandsType = enum {
    regToReg,
    regToMem,
    memToReg,
    constToReg,
    constToMem,
    noExist,
};

// only .asm files allowed
pub fn validFileExtension(file_name: []const u8) bool {
    const asm_extension = ".asm";
    const s_extension = ".s";
    // rets index of where .asm is found
    const validator = std.mem.indexOf(u8, file_name, asm_extension);
    // save index
    if (validator) |_| {
        return true;
    } else {
        const validator_s = std.mem.indexOf(u8, file_name, s_extension);
        if (validator_s) |_|
            return true;
    }
    return false;
}

pub fn readFileStoreAndTrim(lines: *std.ArrayList([]const u8), allocator: *const std.mem.Allocator, file_name: []const u8) !void {
    // buffer i.e: file line
    var buf = std.ArrayList(u8).init(allocator.*);
    defer buf.deinit();

    // file
    // err when file not found
    const file = try std.fs.cwd().openFile(file_name, .{});
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
                            const trimmed_buf = std.mem.trim(u8, buf.items, " ;\r\n\t");
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
                const trimmed_buf = std.mem.trim(u8, buf.items, " ;\r\n\t");
                try lines.append(try allocator.dupe(u8, trimmed_buf));
            }
        }
    }
}

pub fn retRegValues(reg: []const u8) AsmError!u8 {
    // returns registers values or error
    if (std.ascii.eqlIgnoreCase(reg, "ax")) {
        return 0;
    } else if (std.ascii.eqlIgnoreCase(reg, "ecx")) {
        return 1;
    } else if (std.ascii.eqlIgnoreCase(reg, "edx")) {
        return 2;
    } else if (std.ascii.eqlIgnoreCase(reg, "ebx")) {
        return 3;
    } else if (std.ascii.eqlIgnoreCase(reg, "esp")) {
        return 4;
    } else if (std.ascii.eqlIgnoreCase(reg, "ebp")) {
        return 5;
    } else if (std.ascii.eqlIgnoreCase(reg, "esi")) {
        return 6;
    } else if (std.ascii.eqlIgnoreCase(reg, "edi")) {
        return 7;
    } else return AsmError.InvalidRegister;
}

// max 32 bit number
pub fn isANumOfAnyBase(num: []const u8, num_type: td.TokenType) NumError!Number {
    // MINUS and PLUS are symbols i.e: +32 -> PLUS and -32 -> MINUS
    // postfix check
    // d = decimal, h = hexa, o = octal, b = binary
    var base: u8 = undefined;
    if (num.len > 0) {
        base = switch (num[num.len - 1]) {
            'h' => 16,
            'o' => 8,
            'b' => 2,
            else => 10,
        };
    } else {
        return NumError.DefaultError;
    }
    var conv_num: Number = undefined;

    // slice based on type
    const conv_str = switch (base) {
        10 => num[0..num.len],
        else => num[0 .. num.len - 1],
    };

    // convert or return err
    // if IMM return u32
    if (num_type == .IMM) {
        conv_num = Number{ .int_u32 = std.fmt.parseInt(u32, conv_str, base) catch return NumError.NumConv };
    } else if (num_type == .PLUS or num_type == .MINUS) {
        // i32 disp
        conv_num = Number{ .int_i32 = std.fmt.parseInt(i32, conv_str, base) catch return NumError.NumConv };
        // if MINUS, negate number
        if (num_type == .MINUS)
            conv_num = Number{ .int_i32 = -conv_num.int_i32 };
        // if fits i8 disp return that
        if (conv_num.int_i32 >= std.math.minInt(i8) and conv_num.int_i32 <= std.math.maxInt(i8)) {
            const conv_num_i8: i8 = @intCast(conv_num.int_i32);
            return Number{ .int_i8 = conv_num_i8 };
        }
    } else {
        // @compileError("isANumOfAnyBase only accepts IMM, PLUS or MINUS.");
    }
    return conv_num;
}

pub fn printHelp() !void {
    const zhky_usage =
        \\zhky <file_name> -o <out_file_name> -<out_file_type>
        \\Example:
        \\zhky main.asm -o main -elf32 
        \\Note: As of now zharky only emits Windows (PE32), Linux (elf32) and DOS (dos) executables.
        \\zharky supports cross compilation.
    ;

    // dont make this global, wont compile for windows
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{zhky_usage});
}

pub fn assemblerDriver(args: [][:0]u8) !void {
    // only help with 2 args len
    if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "help")) {
            try printHelp();
            std.process.exit(0);
        }
        std.debug.print("ZHARKY: Wrong arguments.Type zhky help to get more info.\n", .{});
        std.process.exit(1);
    } else if (args.len != 5) {
        std.debug.print("ZHARKY: Wrong arguments.Type zhky help to get more info.\n", .{});
        std.process.exit(1);
    } else if (!validFileExtension(args[1])) {
        std.debug.print("ZHARKY: Wrong arguments.Type zhky help to get more info.\n", .{});
        std.process.exit(1);
    }

    // only available targets
    if (!(std.mem.eql(u8, args[4], "-pe32") or
        std.mem.eql(u8, args[4], "-elf32") or
        std.mem.eql(u8, args[4], "-dos")))
    {
        std.debug.print("ZHARKY: No such target exists. Use -elf32, -win32 or -dos.", .{});
        std.process.exit(1);
    }
    out_file_type = args[4];
    out_file_name = args[3];
}

pub inline fn containsStr(haystack: anytype, needle: []const u8) bool {
    for (haystack) |i| {
        if (std.mem.eql(u8, needle, i)) return true;
    }
    return false;
}

pub inline fn containsChar(haystack: []const u8, needle: u8) bool {
    for (haystack) |i| {
        if (i == needle) return true;
    }
    return false;
}

const std = @import("std");

const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const errorToken = @import("pretty_print_errs.zig").errorToken;
const s = @import("symb_table.zig");
const symbol = s.Symbol;
const td = @import("token_def.zig");

pub var out_file_name: []const u8 = undefined;
pub var out_file_type: []const u8 = undefined;

pub const Line = struct {
    ln: []const u8,
    ln_no: usize,
};

pub const numberType = enum {
    int_u16,
    int_u8,
    int_u32,
    slice,
};

pub const Number = union(numberType) {
    int_u16: u16,
    int_u8: u8,
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

pub fn readFileStoreAndTrim(lines: *std.MultiArrayList(Line), allocator: *const std.mem.Allocator, file_name: []const u8) !void {
    // buffer i.e: file line
    var buf = std.ArrayList(u8).init(allocator.*);
    defer buf.deinit();

    // file
    // err when file not found
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_rdr = std.io.bufferedReader(file.reader());
    const rdr = buf_rdr.reader();

    var line_no: usize = 1;

    while (true) {
        buf.clearRetainingCapacity();
        // read each line and store it in buf
        rdr.streamUntilDelimiter(buf.writer(), '\n', null) catch |err|
            switch (err) {
                // switch on err, if end of stream append and break
                error.EndOfStream => {
                    if (buf.items.len > 0) {
                        const trimmed_buf = std.mem.trim(u8, buf.items, " \r\t");
                        try lines.append(allocator.*, .{ .ln = try allocator.dupe(u8, trimmed_buf), .ln_no = line_no });
                    }
                    break;
                },
                // err out
                else => {
                    return compilerError.fileReadError;
                },
            };
        // append copy of buf to lines and trim
        if (buf.items.len > 0) {
            const trimmed_buf = std.mem.trim(u8, buf.items, " \r\t");
            try lines.append(allocator.*, .{ .ln = try allocator.dupe(u8, trimmed_buf), .ln_no = line_no });
        }
        line_no += 1;
    }
}

pub fn retRegValues(reg: []const u8) u8 {
    // returns registers values
    if (std.ascii.eqlIgnoreCase(reg, "eax")) {
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
    }
    return 8;
}

// max 32 bit number
pub fn isANumOfAnyBase(num: []const u8, allow_u8: u1) compilerError!Number {
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
        return compilerError.programError;
    }
    var conv_num: Number = undefined;

    // slice based on type
    const conv_str = switch (base) {
        10 => num[0..num.len],
        else => num[0 .. num.len - 1],
    };

    // convert or return err
    conv_num = Number{ .int_u32 = std.fmt.parseInt(u32, conv_str, base) catch return compilerError.programError };
    if (allow_u8 == 0) {
        if (conv_num.int_u32 >= std.math.minInt(u8) and conv_num.int_u32 <= std.math.maxInt(u8)) {
            const conv_num_i8: u8 = @intCast(conv_num.int_u32);
            return Number{ .int_u8 = conv_num_i8 };
        } else {
            return compilerError.syntaxError;
        }
    }
    return conv_num;
}

pub fn printHelp() compilerError!void {
    const zhky_usage =
        \\zhky <file_name> -o <out_file_name> -<out_file_type>
        \\Example:
        \\zhky main.asm -o main -elf32 
        \\Note: As of now zharky only emits Windows (PE32), Linux (elf32) and DOS (dos) executables.
        \\zharky supports cross compilation.
    ;

    // dont make this global, wont compile for windows
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}\n", .{zhky_usage}) catch return compilerError.stdoutFail;
}

pub fn assemblerDriver(args: [][:0]u8) compilerError!void {
    // only help with 2 args len
    if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "help")) {
            printHelp() catch |err| return err;
        }
        return compilerError.wrongArgs;
    } else if (args.len != 5) {
        return compilerError.wrongArgs;
    } else if (!validFileExtension(args[1])) {
        return compilerError.wrongArgs;
    }

    // only available targets
    if (!(std.mem.eql(u8, args[4], "-pe32") or
        std.mem.eql(u8, args[4], "-elf32") or
        std.mem.eql(u8, args[4], "-dos")))
    {
        return compilerError.wrongArgs;
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

pub fn createSymbol(d_size: usize, offset: *u32, t_type: td.TokenType, d_value: Number) compilerError!void {
    switch (t_type) {
        .CHAR => {
            if (d_size == 0) offset.* += 1 else {
                return compilerError.stringCharNoDD;
            }
        },
        .STRING => {
            if (d_size == 0)
                offset.* = @intCast(d_value.slice.len)
            else {
                return compilerError.stringCharNoDD;
            }
        },
        .IMM => {
            if (d_size == 0 and d_value == .int_u8) offset.* += 1 else if (d_size == 1 and d_value == .int_u32) offset.* += 4 else {
                return compilerError.syntaxError;
            }
        },
        else => return compilerError.notWorking,
    }
}

pub fn retNumOfBytes(num: Number) compilerError!u32 {
    switch (num) {
        numberType.int_u32 => return 4,
        numberType.int_u8 => return 1,
        numberType.int_u16 => return 2,
        numberType.slice => {
            return compilerError.invalidOperand;
        },
    }
}

pub fn append32BitLittleEndian(buffer: *std.ArrayList(u8), num: u32) !void {
    try buffer.*.append(@intCast(num & 0xFF));
    try buffer.*.append(@intCast((num >> 8) & 0xFF));
    try buffer.*.append(@intCast((num >> 16) & 0xFF));
    try buffer.*.append(@intCast((num >> 24) & 0xFF));
}

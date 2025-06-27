const std = @import("std");
const eql = std.mem.eql;

const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const errorToken = @import("pretty_print_errs.zig").errorToken;
const s = @import("symb_table.zig");
const symbol = s.Symbol;
const symbolTable = s.SymbolTable;
const td = @import("token_def.zig");
const Regs = td.Regs;
const TokenType = td.TokenType;

pub const ELF_HDR_SZ = 116;

pub var out_file_name: []const u8 = undefined;

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

// check for valid file extensions
pub fn validFileExtension(file_name: []const u8) bool {
    const asm_extension = ".asm";
    const s_extension = ".s";
    const validator = std.mem.indexOf(u8, file_name, asm_extension);
    if (validator) |_| {
        return true;
    } else {
        const validator_s = std.mem.indexOf(u8, file_name, s_extension);
        if (validator_s) |_|
            return true;
    }
    return false;
}

// read file or error
pub fn readFileStoreAndTrim(lines: *std.MultiArrayList(Line), allocator: *const std.mem.Allocator, file_name: []const u8) !void {
    var buf = std.ArrayList(u8).init(allocator.*);
    defer buf.deinit();

    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    var buf_rdr = std.io.bufferedReader(file.reader());
    const rdr = buf_rdr.reader();

    var line_no: usize = 1;

    while (true) {
        buf.clearRetainingCapacity();
        rdr.streamUntilDelimiter(buf.writer(), '\n', null) catch |err|
            switch (err) {
                error.EndOfStream => {
                    if (buf.items.len > 0) {
                        const trimmed_buf = std.mem.trim(u8, buf.items, " \r\t");
                        try lines.append(allocator.*, .{ .ln = try allocator.dupe(u8, trimmed_buf), .ln_no = line_no });
                    }
                    break;
                },
                else => {
                    return compilerError.fileReadError;
                },
            };
        if (buf.items.len > 0) {
            const trimmed_buf = std.mem.trim(u8, buf.items, " \r\t");
            try lines.append(allocator.*, .{ .ln = try allocator.dupe(u8, trimmed_buf), .ln_no = line_no });
        }
        line_no += 1;
    }
}

// return register value
pub fn retRegValues(reg: []const u8) u8 {
    if (Regs.get(reg)) |r| return r;
    return 8;
}

// convert to number
pub fn isANumOfAnyBase(num: []const u8, not_allow_u8: bool) compilerError!Number {
    // postfix check
    // h = hexa, o = octal, b = binary
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

    // decimal (base 10) has no postfix
    const conv_str = switch (base) {
        10 => num[0..num.len],
        else => num[0 .. num.len - 1],
    };

    conv_num = Number{ .int_u32 = std.fmt.parseInt(u32, conv_str, base) catch return compilerError.programError };
    if (!not_allow_u8) {
        if (conv_num.int_u32 >= std.math.minInt(u8) and conv_num.int_u32 <= std.math.maxInt(u8)) {
            const convd_num_u8: u8 = @intCast(conv_num.int_u32);
            return Number{ .int_u8 = convd_num_u8 };
        } else {
            return compilerError.syntaxError;
        }
    }
    return conv_num;
}

pub fn printHelp() compilerError!void {
    const zhky_usage =
        \\zhky <file_name> -o <out_file_name>
        \\Example:
        \\zhky main.asm -o main
        \\Note: As of now zharky only emits Linux (elf32) executables.
    ;

    // dont make this global, wont compile for windows
    const stdout = std.io.getStdOut().writer();
    stdout.print("{s}\n", .{zhky_usage}) catch return compilerError.stdoutFail;
}

pub fn assemblerDriver(args: [][:0]u8) compilerError!void {
    if (args.len == 2) {
        if (std.mem.eql(u8, args[1], "help")) {
            printHelp() catch |err| return err;
            std.process.exit(0);
        }
        return compilerError.wrongArgs;
    } else if (args.len != 4) {
        return compilerError.wrongArgs;
    } else if (!validFileExtension(args[1]) or !eql(u8, args[2], "-o")) return compilerError.wrongArgs;

    out_file_name = args[3];
}

pub inline fn containsChar(haystack: []const u8, needle: u8) bool {
    for (haystack) |i| {
        if (i == needle) return true;
    }
    return false;
}

pub fn incrDoffsetWrtDtype(d_size: bool, offset: *u32, d_type: td.TokenType, d_value: []const u8) compilerError!Number {
    var d_convd: Number = undefined;
    switch (d_type) {
        .CHAR => {
            if (!d_size) offset.* += 1 else {
                return compilerError.stringCharNoDD;
            }
            d_convd = Number{ .int_u8 = d_value[0] };
        },
        .STRING => {
            if (!d_size)
                offset.* = @intCast(d_value.len)
            else {
                return compilerError.stringCharNoDD;
            }
            d_convd = Number{ .slice = d_value };
        },
        .IMM => {
            d_convd = isANumOfAnyBase(d_value, d_size) catch |err| return err;
            if (!d_size and d_convd == .int_u8) offset.* += 1 else if (d_size and d_convd == .int_u32) offset.* += 4 else {
                return compilerError.syntaxError;
            }
        },
        else => return compilerError.notWorking,
    }
    return d_convd;
}

pub fn retNumOfBytes(num: Number) u32 {
    switch (num) {
        numberType.int_u32 => return 4,
        numberType.int_u8 => return 1,
        numberType.int_u16 => return 2,
        numberType.slice => @panic("No slice here."),
    }
}

pub fn append32BitLittleEndian(buffer: *std.ArrayList(u8), num: u32) !void {
    try buffer.*.append(@intCast(num & 0xFF));
    try buffer.*.append(@intCast((num >> 8) & 0xFF));
    try buffer.*.append(@intCast((num >> 16) & 0xFF));
    try buffer.*.append(@intCast((num >> 24) & 0xFF));
}

pub inline fn createModrmByte(mod: u8, reg: u8, rm: u8) u8 {
    return (mod << 6) | (reg << 3) | rm;
}

// it is always provided that idx is always within the len of the buffer
pub fn updateFourConsecIndexes(header: *[ELF_HDR_SZ]u8, value: u32, idx: u32) void {
    header.*[idx] += @intCast(value & 0xFF);
    header.*[idx + 1] += @intCast((value >> 8) & 0xFF);
    header.*[idx + 2] += @intCast((value >> 16) & 0xFF);
    header.*[idx + 3] += @intCast((value >> 24) & 0xFF);
}

pub fn reduceToIntu8(value: u32) Number {
    if (value >= std.math.minInt(u8) and value <= std.math.maxInt(u8)) {
        const convd_num_u8: u8 = @intCast(value);
        return Number{ .int_u8 = convd_num_u8 };
    }
    return Number{ .int_u32 = value };
}

pub fn checkIfDoubleOrByte(value: Number, s_table: *symbolTable) compilerError!TokenType {
    if (value == .int_u32) return .ERR else if (value == .slice) {
        const retd_offset = s_table.*.getOffset(value.slice) catch |err| return err;
        return retd_offset.symbol_type;
    }
    return .ERR;
}

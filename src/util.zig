const std = @import("std");

pub const NumError = error{ InvalidNumBase, NumConv, DefaultError };
pub const AsmError = error{InvalidRegister};
pub var out_file_name: []const u8 = undefined;
pub var out_file_type: []const u8 = undefined;

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
    const asm_extension: []const u8 = ".asm";
    // rets index of where .asm is found
    const validator = std.mem.indexOf(u8, file_name, asm_extension);
    // save index
    if (validator) |_| {
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
    const file = std.fs.cwd().openFile(file_name, .{}) catch |err|
        switch (err) {
            error.FileNotFound => {
                std.debug.print("ZHARKY: file not found.\n", .{});
                std.process.exit(1);
            },
            else => {
                std.debug.print("ZHARKY: {}\n", .{err});
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
    } else if (std.ascii.eqlIgnoreCase(reg, "cx")) {
        return 1;
    } else if (std.ascii.eqlIgnoreCase(reg, "dx")) {
        return 2;
    } else if (std.ascii.eqlIgnoreCase(reg, "bx")) {
        return 3;
    } else if (std.ascii.eqlIgnoreCase(reg, "sp")) {
        return 4;
    } else if (std.ascii.eqlIgnoreCase(reg, "bp")) {
        return 5;
    } else if (std.ascii.eqlIgnoreCase(reg, "si")) {
        return 6;
    } else if (std.ascii.eqlIgnoreCase(reg, "di")) {
        return 7;
    } else return AsmError.InvalidRegister;
}

pub fn retOperandsType(op1: []const u8, op2: []const u8) OperandsType {
    // valid operands
    // mov$ ax% bx%
    if (retRegValues(op1) != AsmError.InvalidRegister and
        retRegValues(op2) != AsmError.InvalidRegister)
    {
        return OperandsType.regToReg;
    }
    // mov$ ax% 10h%
    else if (retRegValues(op1) != AsmError.InvalidRegister and isANumOfAnyBase(op2) != NumError.InvalidNumBase) {
        return OperandsType.constToReg;
    }
    // mov% [reg or num]% ax%
    else if (isValidMemAddrStyle(op1) and retRegValues(op2) != AsmError.InvalidRegister) {
        return OperandsType.regToMem;
    }
    // mov$ ax% [reg or num]%
    else if (retRegValues(op1) != AsmError.InvalidRegister and isValidMemAddrStyle(op2)) {
        return OperandsType.memToReg;
    }
    // mov$ [reg or num] 78d%
    else if (isValidMemAddrStyle(op1) and isANumOfAnyBase(op2) != NumError.InvalidNumBase) {
        return OperandsType.constToMem;
    } else return OperandsType.noExist;
}

// max 32 bit number
pub fn isANumOfAnyBase(num: []const u8) NumError!u32 {
    // postfix check
    // d = decimal, h = hexa, o = octal, b = binary
    var base: u8 = 0;
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
    // convert or return err
    const conv_num: u32 = std.fmt.parseInt(u32, num[0 .. num.len - 1], base) catch return NumError.NumConv;
    return conv_num;
}

fn isValidMemAddrStyle(mem_addr: []const u8) bool {
    // [] => style
    if (mem_addr[0] != '[' and mem_addr[mem_addr.len - 1] != ']') {
        return false;
    } else { // check or return false
        const num = mem_addr[1 .. mem_addr.len - 2];
        if (isANumOfAnyBase(num) != NumError.InvalidNumBase or retRegValues(num) != AsmError.InvalidRegister)
            return true;
        return false;
    }
}

pub fn printHelp() !void {
    const zhky_usage =
        \\ zhky <file_name> -o <out_file_name> -<out_file_type>
        \\ Example:
        \\ zhky main.asm -o main -elf32 
        \\ Note: As of now zharky only emits Windows (win32), Linux (elf32) and DOS (dos) executables.
        \\ zharky supports cross compilation.
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
        std.debug.print("ZHARKY: Wrong args.\n", .{});
        std.process.exit(1);
    } else if (args.len != 5) {
        std.debug.print("ZHARKY: Wrong args.\n", .{});
        std.process.exit(1);
    } else if (!validFileExtension(args[1])) {
        std.debug.print("ZHARKY: Wrong args.\n", .{});
        std.process.exit(1);
    }

    // only available targets
    if (!(std.mem.eql(u8, args[4], "-win32") or
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

pub inline fn printErrMsgAndExit(err_msg: []const u8) void {
    std.debug.print("{s}\n", .{err_msg});
    std.process.exit(1);
}

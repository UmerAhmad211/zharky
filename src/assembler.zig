const std = @import("std");
const plt = @import("plt.zig");
const ut = @import("util.zig");

// types of encoding errors
pub const encodingError = error{
    operandEmpty,
    wrongOperands,
};

pub fn compareOperand(tokens: *plt.Mnemonics, encodings: *std.ArrayList(u8)) void {
    const operator = tokens.*.operator;
    if (std.ascii.eqlIgnoreCase(operator, "mov")) {
        // if err then exit
        _ = mov(tokens, encodings) catch |err| switch (err) {
            error.wrongOperands, error.operandEmpty => {
                std.debug.print("ZHARKY: Error at line {d}.\n", .{tokens.*.line_no});
                std.process.exit(1);
            },
            // for ArrayList errors
            else => {},
        };
    } else if (std.ascii.eqlIgnoreCase(operator, "nop")) {
        // if err then exit
        _ = nop(tokens, encodings) catch |err| switch (err) {
            error.wrongOperands, error.operandEmpty => {
                std.debug.print("ZHARKY: Error at line {d}.\n", .{tokens.*.line_no});
                std.process.exit(1);
            },
            // for ArrayList errors
            else => {},
        };
    } else {
        std.debug.print("ZHARKY: Error at line {d}.\n", .{tokens.*.line_no});
        std.process.exit(1);
    }
}

fn mov(tokens: *plt.Mnemonics, encodings: *std.ArrayList(u8)) !void {
    // either operand empty
    if (tokens.op1.len == 0 or tokens.op2.len == 0) {
        return encodingError.operandEmpty;
    }
    // encode based on operands
    switch (ut.retOperandsType(tokens.op1, tokens.op2)) {
        ut.OperandsType.regToReg => {
            try encodings.append(0x89);
            // mod r/m byte
            // C0 = 11000000 => reg to reg exclusive mov
            try encodings.append((0xC0 | try ut.retRegValues(tokens.op2) << 3) | try ut.retRegValues(tokens.op1));
        },
        ut.OperandsType.constToReg => {
            // mov + reg
            try encodings.append(0xB8 + try ut.retRegValues(tokens.op1));
            // convert number ,only 16 bit allowed
            const conv_imm = ut.isANumOfAnyBase(tokens.op2) catch |err|
                switch (err) {
                error.InvalidNumBase => {
                    std.debug.print("ZHARKY: Error at line {d}.\n", .{tokens.line_no});
                    std.process.exit(1);
                },
            };
            // little endian
            try encodings.append(@intCast(conv_imm & 0xFF));
            try encodings.append(@intCast((conv_imm >> 8) & 0xFF));
        },
        ut.OperandsType.memToReg => {},
        // irrelevant operands
        else => {
            return encodingError.wrongOperands;
        },
    }
}

fn nop(tokens: *plt.Mnemonics, encodings: *std.ArrayList(u8)) !void {
    // nop has no operands
    if (tokens.op1.len == 0 and tokens.op2.len == 0) {
        try encodings.append(0x90);
        return;
    }
    return encodingError.wrongOperands;
}

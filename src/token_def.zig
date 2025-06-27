const std = @import("std");

pub const TokenType = enum {
    // multiple chars
    K_GLOBAL,
    START,
    K_SECTION,
    T_SECTION,
    D_SECTION,
    INSTRUCTION_0OP,
    INSTRUCTION_1OP,
    INSTRUCTION_2OP,
    INSTRUCTION_O1OP,
    DB,
    DD,
    REG,
    IDENTIFIER,
    MEM,
    // literals
    IMM,
    STRING,
    // single char
    COMMA,
    O_BRACKET,
    C_BRACKET,
    COLON,
    CHAR,
    EOL,
    ERR,
    // end of file
    EOF,
};

pub const Regs = std.StaticStringMap(u8).initComptime(.{
    .{ "eax", 0 },
    .{ "ecx", 1 },
    .{ "edx", 2 },
    .{ "ebx", 3 },
    .{ "esp", 4 },
    .{ "ebp", 5 },
    .{ "esi", 6 },
    .{ "edi", 7 },
});

pub const Jmps = std.StaticStringMap(u8).initComptime(.{
    .{ "jmp", 0xE9 },
    .{ "je", 0x0F },
    .{ "jne", 0x10 },
    .{ "call", 0xE8 },
});

pub const RegsOp1 = std.StaticStringMap(u8).initComptime(.{
    .{ "push", 0x50 },
    .{ "pop", 0x58 },
    .{ "dec", 0x48 },
    .{ "inc", 0x40 },
});

pub const SecOperandOp1 = std.StaticStringMap(u8).initComptime(.{
    .{ "push", 0x68 },
    .{ "pop", 0x8F },
    .{ "dec", 1 },
    .{ "inc", 0 },
});

pub const RegReg = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0x8B },
    .{ "add", 0x01 },
    .{ "cmp", 0x39 },
});

pub const RegMem = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0x8B },
    .{ "add", 0x03 },
    .{ "cmp", 0x3B },
});

pub const RegData = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0xB8 },
    .{ "add", 0x81 },
    .{ "cmp", 0x81 },
});
pub const MemReg = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0x89 },
    .{ "add", 0x01 },
    .{ "cmp", 0x39 },
});

pub const MemData = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0xC7 },
    .{ "add", 0x81 },
    .{ "cmp", 0x81 },
});

pub const MemDataByte = std.StaticStringMap(u8).initComptime(.{
    .{ "mov", 0xC6 },
    .{ "add", 0x80 },
    .{ "cmp", 0x80 },
});

pub const single_char = [_]u8{
    ',', '[', ']', ' ', ':',
};

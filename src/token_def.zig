pub const TokenType = enum {
    // multiple chars
    K_GLOBAL,
    K_SECTION,
    T_SECTION,
    D_SECTION,
    INSTRUCTION_0OP,
    INSTRUCTION_1OP,
    INSTRUCTION_2OP,
    INSTRUCTION_O1OP,
    WORD,
    DWORD,
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
    S_QUOTE,
    D_QUOTE,
    CHAR,
    EOL,
    // end of file
    ERR,
    EOF,
};

pub const k_global = "global";
pub const k_section = "section";

pub const t_section = ".text";
pub const d_section = ".data";

pub const instructions_0op = [_][]const u8{ "hlt", "nop" };

pub const instructions_1op = [_][]const u8{
    "mul", "div", "pop", "push", "int",  "neg",
    "jmp", "je",  "jne", "loop", "call", "dec",
    "inc", "not",
};

pub const instructions_2op = [_][]const u8{
    "mov", "add", "adc",  "sub", "cmp", "xor",
    "and", "or",  "test",
};

pub const instructions_optional_1op = [_][]const u8{
    "ret",
};

pub const word = "word";
pub const dword = "dword";

pub const db = "db";
pub const dd = "dd";

pub const regs = [_][]const u8{
    "eax", "ebx", "ecx",
    "edx", "esi", "edi",
    "ebp", "esp",
};

pub const single_char = [_]u8{
    ',', '[', ']', ' ', ':',
};

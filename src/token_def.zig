pub const TokenType = enum {
    // multiple chars
    KEYWORD,
    SECTION_NAME,
    INSTRUCTION_0OP,
    INSTRUCTION_1OP,
    INSTRUCTION_2OP,
    INSTRUCTION_O1OP,
    SIZE,
    REG,
    IDENTIFIER,
    // literals
    IMM,
    STRING,
    // single char
    COMMA,
    O_BRACKET,
    C_BRACKET,
    WHITE_SPACE,
    COLON,
    PLUS,
    MINUS,
    STAR,
    S_QUOTE,
    D_QUOTE,
    CHAR,
    NUM,
    EOL,
    // end of file or err
    ERR,
    EOF,
};

pub const keyword = [_][]const u8{
    "global", "section", "db", "dw", "dd",
};

pub const section_name = [_][]const u8{
    ".text", ".data",
};

pub const instructions_0op = [_][]const u8{
    "hlt", "nop", "pusha", "popa", "iret",
};

pub const instructions_1op = [_][]const u8{
    "mul", "div",  "pop",  "push", "int", "neg", "shl", "shr",
    "jmp", "ja",   "jae",  "jb",   "jbe", "jg",  "jge", "jl",
    "jle", "je",   "jne",  "jc",   "jnc", "jo",  "jno", "js",
    "jns", "loop", "call", "dec",  "inc", "not", "sar", "ror",
    "rol", "rcl",  "rcr",
};

pub const instructions_2op = [_][]const u8{
    "mov", "add", "adc", "sub", "cmp",  "xor",
    "and", "or",  "lea", "sbb", "xchg", "test",
};

pub const instructions_optional_1op = [_][]const u8{
    "ret",
};

pub const size = [_][]const u8{
    "word", "dword",
};

pub const regs = [_][]const u8{
    "ax",  "eax", "bx",  "ebx", "cx",  "ecx",
    "dx",  "si",  "esi", "di",  "edi", "bp",
    "ebp", "sp",  "esp",
};

pub const single_char = [_]u8{
    ',', '[', ']', ' ', ':',
};

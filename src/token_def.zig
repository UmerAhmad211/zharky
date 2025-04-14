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
    DW,
    DD,
    REG,
    IDENTIFIER,
    // literals
    IMM,
    STRING,
    // single char
    COMMA,
    O_BRACKET,
    C_BRACKET,
    COLON,
    PLUS,
    MINUS,
    S_QUOTE,
    D_QUOTE,
    CHAR,
    NUM,
    EOL,
    // end of file
    ERR,
    EOF,
};

pub const k_global = "global";
pub const k_section = "section";

pub const t_section = ".text";
pub const d_section = ".data";

pub const instructions_0op = [_][]const u8{
    "hlt", "nop", "pusha", "popa", "iret",
};

pub const instructions_1op = [_][]const u8{
    "mul",  "div", "pop", "push", "int", "neg",
    "jmp",  "ja",  "jae", "jb",   "jbe", "jg",
    "jge",  "jl",  "jle", "je",   "jne", "jc",
    "jnc",  "jo",  "jno", "js",   "jns", "loop",
    "call", "dec", "inc", "not",
};

pub const instructions_2op = [_][]const u8{
    "mov", "add", "adc", "sub", "cmp",  "xor",
    "and", "or",  "lea", "sbb", "xchg", "test",
    "shl", "shr", "sar", "ror", "rol",  "rcl",
    "rcr",
};

pub const instructions_optional_1op = [_][]const u8{
    "ret",
};

pub const word = "word";
pub const dword = "dword";

pub const db = "db";
pub const dw = "dw";
pub const dd = "dd";

pub const regs = [_][]const u8{
    "ax",  "eax", "bx",  "ebx", "cx",  "ecx",
    "dx",  "si",  "esi", "di",  "edi", "bp",
    "ebp", "sp",  "esp",
};

pub const single_char = [_]u8{
    ',', '[', ']', ' ', ':',
};

pub const TokenType = enum {
    // multiple chars
    KEYWORD,
    SECTION_NAME,
    INSTRUCTION,
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

pub const instructions = [_][]const u8{
    "mov",  "add", "adc",  "sub",   "mul",
    "div",  "pop", "push", "pusha", "xor",
    "popa", "cmp", "dec",  "inc",   "hlt",
    "nop",  "int", "neg",  "shl",   "shr",
    "and",  "or",  "jmp",  "ja",    "jae",
    "jb",   "jbe", "jg",   "jge",   "jl",
    "jle",  "je",  "jne",  "jc",    "jnc",
    "jo",   "jno", "js",   "jns",   "loop",
    "call", "ret", "int",  "lea",   "xchng",
    "sbb",  "not", "test", "iret",  "sar",
    "ror",  "rol", "rcl",  "rcr",
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

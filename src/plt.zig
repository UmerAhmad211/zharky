const std = @import("std");

const l = @import("lexer.zig");
const p = @import("parser.zig");
const instruction = p.instruction;
const operand = p.operand;
const pp = @import("pretty_print_errs.zig");
const errorToken = pp.errorToken;
const compilerError = pp.compilerErrors;
const st = @import("symb_table.zig");
const symbolTable = @import("symb_table.zig").SymbolTable;
const tg_elf = @import("targets/elf.zig");
const tg_win = @import("targets/win.zig");
const td = @import("token_def.zig");
const TokenType = td.TokenType;
const ut = @import("util.zig");
const Number = ut.Number;
const Line = ut.Line;

pub fn process(file_name: []const u8) !void {
    // allocator
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    // allocate lines
    var lines = std.MultiArrayList(Line){};
    defer lines.deinit(allocator);

    // free lines
    defer for (lines.items(.ln)) |line|
        allocator.free(line);

    var err_tok: errorToken = undefined;

    ut.readFileStoreAndTrim(&lines, &allocator, file_name) catch {
        err_tok.error_type = compilerError.fileReadError;
        pp.printErrMsgAndExit(&err_tok);
    };

    // lexer tokens
    var tokenized_input = std.ArrayList(l.Token).init(allocator);
    defer tokenized_input.deinit();

    var s_table: symbolTable = .init(&allocator);
    defer s_table.deinit();

    // lexer loop
    for (lines.items(.ln), lines.items(.ln_no)) |lne, lne_n| {
        if (!l.tokenizeInputStream(lne, &tokenized_input, lne_n, &err_tok)) pp.printErrMsgAndExit(&err_tok);
    }

    const tok_eof: l.Token = .{ .type = TokenType.EOF, .value = "eof", .curr_line = undefined, .row_no = lines.items(.ln_no)[lines.len - 1], .col_no = 1 };
    tokenized_input.append(tok_eof) catch {
        err_tok.err_token = tok_eof;
        err_tok.error_type = compilerError.programError;
        pp.printErrMsgAndExit(&err_tok);
    };

    var text_arr = std.ArrayList(instruction).init(allocator);
    defer text_arr.deinit();

    var data_arr = std.ArrayList(u8).init(allocator);
    defer data_arr.deinit();

    // parser
    if (!p.parse(&tokenized_input, &err_tok, &s_table, &text_arr, &data_arr))
        pp.printErrMsgAndExit(&err_tok);

    // hold encodings
    var encodings = std.ArrayList(u8).init(allocator);
    defer encodings.deinit();

    // set target headers
    if (std.mem.eql(u8, ut.out_file_type, "-elf32")) {
        try tg_elf.tgELF32(&encodings);
    } else if (std.mem.eql(u8, ut.out_file_type, "-pe32")) {
        tg_win.tgWIN32(&encodings);
    }
}

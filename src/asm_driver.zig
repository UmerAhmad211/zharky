const std = @import("std");
const bltn = @import("builtin");

const cg = @import("codegen.zig");
const l = @import("lexer.zig");
const Lexer = l.Lexer;
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

pub fn process(file_name: []const u8) compilerError!void {
    var allocator: std.mem.Allocator = undefined;
    if (bltn.target.os.tag == .windows) allocator = std.heap.c_allocator else allocator = std.heap.smp_allocator;

    var lines = std.MultiArrayList(Line){};
    defer lines.deinit(allocator);

    defer for (lines.items(.ln)) |line|
        allocator.free(line);

    var err_tok: errorToken = undefined;

    ut.readFileStoreAndTrim(&lines, &allocator, file_name) catch {
        err_tok.error_type = compilerError.fileReadError;
        pp.printErrMsgAndExit(&err_tok);
    };

    // lex
    var tokenized_input = std.ArrayList(l.Token).init(allocator);
    defer tokenized_input.deinit();

    var s_table: symbolTable = .init(&allocator);
    defer s_table.deinit();

    for (lines.items(.ln), lines.items(.ln_no)) |lne, lne_n| {
        if (!Lexer.tokenizeInputStream(lne, &tokenized_input, lne_n, &err_tok)) pp.printErrMsgAndExit(&err_tok);
    }

    const tok_eof: l.Token = .{ .type = TokenType.EOF, .value = "eof", .curr_line = undefined, .row_no = lines.items(.ln_no)[lines.len - 1], .col_no = 1 };
    tokenized_input.append(tok_eof) catch {
        err_tok.error_type = compilerError.programError;
        pp.printErrMsgAndExit(&err_tok);
    };

    var text_arr = std.ArrayList(instruction).init(allocator);
    defer text_arr.deinit();

    var data_arr = std.ArrayList(u8).init(allocator);
    defer data_arr.deinit();

    var data_len: u32 = 0;
    var text_len: u32 = 0;

    // parser
    if (!p.parse(&tokenized_input, &err_tok, &s_table, &text_arr, &data_arr, &data_len, &text_len))
        pp.printErrMsgAndExit(&err_tok);

    // hold encodings
    var encodings = std.ArrayList(u8).init(allocator);
    defer encodings.deinit();

    var header = comptime tg_elf.tgELF32();

    const pad_1 = comptime [_]u8{0} ** 0x0F8C;
    const pad_2_len: u32 = @abs(0x1000 - text_len);

    if (!cg.codegenDriver(&encodings, &text_arr, &s_table, &header, 0x1000 + text_len + pad_2_len, &err_tok)) pp.printErrMsgAndExit(&err_tok);

    const old_len = encodings.items.len;
    encodings.resize(old_len + pad_2_len) catch return compilerError.programError;
    @memset(encodings.items[old_len..], 0x00);

    tg_elf.updateELF(&header, text_len, data_len, 0x1000 + text_len + pad_2_len);

    const file = std.fs.cwd().createFile(ut.out_file_name, .{ .truncate = true }) catch return compilerError.writeCreateFileErr;
    defer file.close();

    file.writeAll(&header) catch return compilerError.writeCreateFileErr;
    file.writeAll(&pad_1) catch return compilerError.writeCreateFileErr;
    file.writeAll(encodings.items) catch return compilerError.writeCreateFileErr;
    file.writeAll(data_arr.items) catch return compilerError.writeCreateFileErr;

    const c_out_file_name = std.mem.Allocator.dupeZ(allocator, u8, ut.out_file_name) catch return compilerError.programError;
    defer allocator.free(c_out_file_name);
    const ptr_out_file_name = c_out_file_name.ptr;
    _ = std.os.linux.chmod(ptr_out_file_name, 0o755);
}

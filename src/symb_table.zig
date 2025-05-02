const std = @import("std");

const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const TokenType = @import("token_def.zig").TokenType;

pub const Symbol = struct {
    symbol_type: TokenType,
    offset: usize,
};

pub const SymbolTable = struct {
    table: std.StringHashMap(Symbol),

    pub fn init(allocator: *std.mem.Allocator) SymbolTable {
        return SymbolTable{ .table = std.StringHashMap(Symbol).init(allocator.*) };
    }

    pub fn storeSymbol(self: *SymbolTable, symbol: *Symbol, name: *[]const u8) compilerError!void {
        if (!self.*.table.contains(name.*))
            self.*.table.put(name.*, symbol.*) catch return compilerError.programError
        else
            return compilerError.dupeLabel;
    }

    pub fn deinit(self: *SymbolTable) void {
        self.*.table.deinit();
    }
};

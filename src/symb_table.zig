const std = @import("std");

const compilerError = @import("pretty_print_errs.zig").compilerErrors;
const TokenType = @import("token_def.zig").TokenType;

pub const Symbol = struct {
    symbol_type: TokenType,
    offset: u32,
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

    pub fn containsLabel(self: *SymbolTable, name: *const []const u8) bool {
        if (self.*.table.contains(name.*))
            return true;
        return false;
    }

    pub fn getOffset(self: *SymbolTable, name: []const u8) compilerError!Symbol {
        if (self.*.table.get(name)) |offset| return offset else {
            return compilerError.labelNotFound;
        }
    }

    pub fn deinit(self: *SymbolTable) void {
        self.*.table.deinit();
    }
};

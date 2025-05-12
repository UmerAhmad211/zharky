const std = @import("std");
const print = std.debug.print;

const l = @import("lexer.zig");

pub const compilerErrors = error{
    invalidOperand,
    wrongDataId,
    syntaxError,
    unidentifiedInst,
    eaxNoDisp,
    stringCharNoDD,
    notWorking,
    programError,
    dupeLabel,
    fileReadError,
    onlyASCII,
    noClosingQuote,
    startNotFound,
    labelNotFound,
    wrongArgs,
    stdoutFail,
    writeCreateFileErr,
};

pub const errorToken = struct {
    err_token: l.Token,
    error_type: compilerErrors,
};

pub const red = "\x1b[31m";
pub const reset = "\x1b[0m";
pub const blue = "\x1b[34m";
pub const green = "\x1b[32m";

pub fn printErrMsgAndExit(token: *errorToken) void {
    switch (token.*.error_type) {
        compilerErrors.invalidOperand => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Invalid operand:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.syntaxError => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Syntax error:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.eaxNoDisp => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "EAX takes no displacement:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.wrongDataId => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Unidentified data type:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.unidentifiedInst => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Unidentified instruction:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.stringCharNoDD => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "String and chars should not be DD:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.notWorking => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Either deprecated or not implemented:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.programError => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Program terminated unexpectedly.\n", .{});
        },
        compilerErrors.dupeLabel => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Duplicate label:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.fileReadError => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Error reading file.\n", .{});
        },
        compilerErrors.onlyASCII => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Only ASCII supported:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.noClosingQuote => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "No closing quote found:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.startNotFound => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Symbol _start not found.\n", .{});
        },
        compilerErrors.labelNotFound => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Label not found:{d}:{d}.\n", .{ token.*.err_token.row_no, token.*.err_token.col_no });
            printErrLine(token);
        },
        compilerErrors.wrongArgs => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "Wrong arguments.\n", .{});
        },
        compilerErrors.stdoutFail => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "stdout fail.\n", .{});
        },
        compilerErrors.writeCreateFileErr => {
            print("ZHARKY: " ++ red ++ "Error: " ++ reset ++ "File create/write error.\n", .{});
        },
    }
    std.process.exit(1);
}

fn printErrLine(token: *errorToken) void {
    print(blue ++ "{d}" ++ reset ++ " | {s}\n", .{ token.*.err_token.row_no, token.*.err_token.curr_line });
    var i: usize = 0;
    const limit: usize = token.*.err_token.col_no + std.math.log10(token.*.err_token.row_no) + 3;
    while (i < limit) : (i += 1) {
        print(" ", .{});
    }
    print(green ++ "^" ++ reset ++ "\n", .{});
}

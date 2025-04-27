const std = @import("std");

pub fn build(b: *std.Build) void {
    const module = b.addModule("zhky", .{
        .root_source_file = b.path("main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const exe = b.addExecutable(.{
        .name = "zhky",
        .root_module = module,
        .use_lld = false,
        .use_llvm = false,
    });
    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = "zhky",
        .root_module = module,
    });

    const check = b.step("check", "Check if zhkarky compiles");
    check.dependOn(&exe_check.step);
}

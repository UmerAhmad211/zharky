const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = std.Target.Query{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    };

    const exe = b.addExecutable(.{
        .name = "sasm",
        .root_source_file = b.path("main.zig"),
        .target = b.resolveTargetQuery(target),
    });

    b.installArtifact(exe);

    // for zls
    const exe_check = b.addExecutable(.{
        .name = "sasm",
        .root_source_file = b.path("main.zig"),
        .target = b.resolveTargetQuery(target),
    });

    // check
    // build but dont install bin
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);
}

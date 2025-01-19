const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "zhky",
        .root_source_file = b.path("main.zig"),
        .target = b.host,
        .optimize = .ReleaseFast,
        .strip = true,
        .single_threaded = true,
        .unwind_tables = false,
    });

    b.installArtifact(exe);
}

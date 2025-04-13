const std = @import("std");

pub fn build(b: *std.Build) void {
    const options = std.Build.Module.CreateOptions{
        .root_source_file = b.path("main.zig"),
        .target = b.graph.host,
    };

    const exe = b.addExecutable(.{
        .name = "zhky",
        .root_module = b.createModule(options),
        .optimize = .Debug,
        .use_llvm = false,
        .use_lld = false,
    });

    b.installArtifact(exe);
}

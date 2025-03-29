const std = @import("std");

const tgs = [_]std.Target.Query{
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
    .{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
    },
};

pub fn build(b: *std.Build) void {
    for (tgs) |tg| {
        const exe = b.addExecutable(.{
            .name = "zhky",
            .root_source_file = b.path("main.zig"),
            .target = b.resolveTargetQuery(tg),
            .optimize = .Debug,
        });

        b.installArtifact(exe);
    }
}

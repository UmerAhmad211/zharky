const std = @import("std");

const tg: []const std.Target.Query = &.{
    .{ .cpu_arch = .x86_64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

pub fn build(b: *std.Build) void {
    for (tg) |t| {
        const module = b.addModule("zhky", .{
            .root_source_file = b.path("main.zig"),
            .target = b.resolveTargetQuery(t),
            .strip = true,
            .optimize = .ReleaseFast,
        });
        const exe = b.addExecutable(.{
            .name = "zhky",
            .root_module = module,
        });
        if (t.os_tag.? == .windows) exe.linkLibC();
        b.installArtifact(exe);
    }
}

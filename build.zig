const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const in_target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .cpu_model = .{ .explicit = &std.Target.wasm.cpu.mvp },
        .cpu_features_add = std.Target.wasm.featureSet(&.{
            .atomics,
            .bulk_memory,
        }),
        .os_tag = .emscripten,
    });

    const target = if (in_target.result.ofmt == .wasm) wasm_target else in_target;

    const exe = b.addExecutable(.{
        .name = "lsr",
        .root_source_file = .{ .cwd_relative = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");
    // raylib_artifact.root_module.addCMacro("SUPPORT_FILEFORMAT_JPG", "");

    if (target.query.os_tag == .emscripten) {
        const exe_lib = try rlz.emcc.compileForEmscripten(
            b,
            "lsr",
            "src/main.zig",
            target,
            optimize,
        );
        exe_lib.linkLibC();
        exe_lib.initial_memory = 512 * 1024 * 1024;

        exe_lib.linkLibrary(raylib_artifact);
        exe_lib.root_module.addImport("raylib", raylib);
        exe_lib.root_module.addImport("raygui", raygui);

        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        const link_step = try rlz.emcc.linkWithEmscripten(b, &[_]*std.Build.Step.Compile{
            exe_lib,
            raylib_artifact,
        });
        link_step.addArg("-sEXPORTED_FUNCTIONS=['_realloc','_malloc','_free','_main']");
        link_step.addArg("-sMALLOC=emmalloc");
        link_step.addArg("--shell-file");
        link_step.addArg(b.path("src/shell.html").getPath(b));
        link_step.addArg("-sINITIAL_MEMORY=512MB");
        link_step.addArg("-sALLOW_MEMORY_GROWTH=1");

        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rlz.emcc.emscriptenRunStep(b);
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run", "Run lsr");
        run_option.dependOn(&run_step.step);
        return;
    }

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}

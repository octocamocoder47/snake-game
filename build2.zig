const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Native desktop build (unchanged behavior)
    if (!target.result.cpu.arch.isWasm()) {
        const exe = b.addExecutable(.{
            .name = "lsr",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const raylib_dep = b.dependency("raylib", .{
            .target = target,
            .optimize = optimize,
        });

        const raylib = raylib_dep.module("raylib");
        const raygui = raylib_dep.module("raygui");
        const raylib_artifact = raylib_dep.artifact("raylib");

        exe.linkLibrary(raylib_artifact);
        exe.root_module.addImport("raylib", raylib);
        exe.root_module.addImport("raygui", raygui);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
        return;
    }

    // WASM (Emscripten) path
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .cpu_model = .{ .explicit = &std.Target.wasm.cpu.mvp },
        .cpu_features_add = std.Target.wasm.featureSet(&.{
            .atomics,
            .bulk_memory,
        }),
        .os_tag = .emscripten,
    });

    // Raylib Zig bindings (for types/imports). Note: binding package must be declared in build.zig.zon.
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = wasm_target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    // We will still build a Zig static library from your source and then use emcc to link final wasm/html.

    const app_lib = b.addLibrary(.{
        .linkage = .static,
        .name = "lsr_wasm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = wasm_target,
            .optimize = optimize,
        }),
    });

    app_lib.linkLibC();
    app_lib.shared_memory = true;
    app_lib.root_module.addImport("raylib", raylib);
    app_lib.root_module.addImport("raygui", raygui);

    // === IMPORTANT: Path to the libraylib.a you compiled with emscripten ===
    // Replace this with the absolute path where the Emscripten-built libraylib.a exists.
    const raylib_wasm_a = b.path("/absolute/path/to/raylib/src/libraylib.a");

    // Build final output with emcc (link Zig emitted object + libraylib.a)
    const emcc = b.addSystemCommand(&.{"emcc"});

    // Add the zig library .o / emitted bin to be linked by emcc
    emcc.addFileArg(app_lib.getEmittedBin());

    // Add the prebuilt emscripten raylib static library
    emcc.addFileArg(raylib_wasm_a);

    // Add emcc/linker args (tweak as needed)
    emcc.addArgs(&.{
        "-sUSE_GLFW=3",
        "-sSHARED_MEMORY=1",
        "-sALLOW_MEMORY_GROWTH=1",
        "-sASYNCIFY",
        "--shell-file",
        b.path("src/shell.html").getPath(b),
        "--preload-file", "res@/res", // include 'res' folder as /res in final files (change if you have assets)
    });

    // Output index.html
    emcc.addArg("-o");
    const app_html = emcc.addOutputFileArg("index.html");

    // Make sure linking waits for the Zig compile step
    emcc.step.dependOn(&app_lib.step);

    // Install to www
    b.getInstallStep().dependOn(&b.addInstallDirectory(.{
        .source_dir = app_html.dirname(),
        .install_dir = .{ .custom = "www" },
        .install_subdir = "",
    }).step);
}

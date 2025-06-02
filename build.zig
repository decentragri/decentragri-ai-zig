const std = @import("std");

pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});
	const optimize = b.standardOptimizeOption(.{});

	// Tokamak, Dotenv, JWT dependencies
	const tokamak_dep = b.dependency("tokamak", .{});
	const tokamak_module = tokamak_dep.module("tokamak");

	const dotenv_dep = b.dependency("dotenv", .{});
	const dotenv_module = dotenv_dep.module("dotenv");

	const jwt_dep = b.dependency("jwt", .{});
	const jwt_module = jwt_dep.module("jwt");

	// Create a "module" for your library
	const lib_mod = b.createModule(.{
		.root_source_file = b.path("src/root.zig"),
		.target = target,
		.optimize = optimize,
	});

	// Create a module for your executable
	const exe_mod = b.createModule(.{
		.root_source_file = b.path("src/main.zig"),
		.target = target,
		.optimize = optimize,
	});

	// Module relationships
	exe_mod.addImport("decentragri_ai_zig_lib", lib_mod);

	lib_mod.addImport("tokamak", tokamak_module);
	exe_mod.addImport("tokamak", tokamak_module);

	lib_mod.addImport("dotenv", dotenv_module);
	exe_mod.addImport("dotenv", dotenv_module);

	lib_mod.addImport("jwt", jwt_module);
	exe_mod.addImport("jwt", jwt_module);

	// Add mgclient include path to both modules
	const mgclient_include_path: std.Build.LazyPath = .{ .cwd_relative = "/usr/local/include" };
	lib_mod.addIncludePath(mgclient_include_path);
	exe_mod.addIncludePath(mgclient_include_path);
	// Create static library from lib_mod
	const lib = b.addLibrary(.{
		.name = "decentragri_ai_zig",
		.root_module = lib_mod,
		.linkage = .static,
	});

	// Link mgclient C library
	lib.linkSystemLibrary("mgclient");

	// Create the executable
	const exe = b.addExecutable(.{
		.name = "decentragri_ai_zig",
		.root_module = exe_mod,
	});
	exe.linkSystemLibrary("mgclient");
	exe.addIncludePath(mgclient_include_path);

	// Install build artifacts
	b.installArtifact(lib);
	b.installArtifact(exe);

	// Run step
	const run_cmd = b.addRunArtifact(exe);
	run_cmd.step.dependOn(b.getInstallStep());

	if (b.args) |args| {
		run_cmd.addArgs(args);
	}

	const run_step = b.step("run", "Run the app");
	run_step.dependOn(&run_cmd.step);

	// Unit tests
	const lib_unit_tests = b.addTest(.{
		.root_module = lib_mod,
	});
	const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

	const exe_unit_tests = b.addTest(.{
		.root_module = exe_mod,
	});
	const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

	const test_step = b.step("test", "Run unit tests");
	test_step.dependOn(&run_lib_unit_tests.step);
	test_step.dependOn(&run_exe_unit_tests.step);
}

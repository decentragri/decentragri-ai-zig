const std = @import("std");
const tk = @import("tokamak");
const Env = @import("utils/constants.zig").Env;

const routes: []const tk.Route = &.{
	.get("/", hello),
};

var global_env: ?Env = null;

fn hello() ![]const u8 {
	const password = global_env.?.get("PASSWORD") orelse "(unset)";
	return std.fmt.allocPrint(std.heap.page_allocator, "Password is: {s}", .{password});
}

pub fn main() !void {
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();

	const allocator = arena.allocator();

	global_env = try Env.init(allocator);
	std.debug.print("Loaded .env and initialized global_env\n", .{});

	// === ⚠️ Optional: .env value test – disable when not needed ===
	// const password = global_env.?.get("NEO4J_PASSWORD") orelse return error.MissingEnv;
	// std.debug.print("Loaded password from .env: {s}\n", .{password});
	// =============================================================

	std.debug.print("Starting Decentragri server on http://localhost:{}\n", .{8085});
	var server = try tk.Server.init(allocator, routes, .{
		.listen = .{ .port = 8085 }
	});
	try server.start();
}

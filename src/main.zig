const std = @import("std");
const tk = @import("tokamak");
const Env = @import("utils/constants.zig").Env;
const memgraph = @import("db.services/memgraph.zig");

const routes: []const tk.Route = &.{
	.get("/", hello),
};

var global_env: ?Env = null;

fn hello() ![]const u8 {
	return "hello there";
}

pub fn main() !void {
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();

	const allocator = arena.allocator();

	global_env = try Env.init(allocator);
	std.debug.print("Loaded .env and initialized global_env\n", .{});
	try memgraphInit(global_env);

	// const password = global_env.?.get("NEO4J_PASSWORD") orelse return error.MissingEnv;
	// std.debug.print("Loaded password from .env: {s}\n", .{password});

	std.debug.print("Starting Decentragri server on http://localhost:{}\n", .{8085});
	var server = try tk.Server.init(allocator, routes, .{
		.listen = .{ .port = 8085 }
	});
	try server.start();
}



fn memgraphInit(env: ?Env) !void {
	const uri = env.?.get("MEMGRAPH_URI") orelse return error.MissingEnv;
	const username = env.?.get("MEMGRAPH_USERNAME") orelse return error.MissingEnv;
	const password = env.?.get("MEMGRAPH_PASSWORD") orelse return error.MissingEnv;

	std.debug.print(
		"🔐 Connecting to Memgraph with:\n  URI: {s}\n  USER: {s}\n  PASSWORD: {s}\n",
		.{ uri, username, password },
	);

	try memgraph.initMemgraph(uri, username, password);
	std.debug.print("✅ Memgraph initialized successfully\n", .{});
}

const std = @import("std");
const c = @cImport({ @cInclude("mgclient.h"); });
const constants = @import("../utils/constants.zig");

fn toNullTerminated(allocator: std.mem.Allocator, input: []const u8) ![:0]u8 {
	var buf = try allocator.allocSentinel(u8, input.len, 0);
	std.mem.copyForwards(u8, buf[0..input.len], input);
	return buf;
}

pub fn initMemgraph(uri: []const u8, username: []const u8, password: []const u8) !void {
	if (uri.len == 0 or username.len == 0 or password.len == 0) {
		std.debug.print("❌ One or more Memgraph credentials are empty\n", .{});
		return error.MissingEnv;
	}

	const scheme_sep = std.mem.indexOf(u8, uri, "://") orelse return error.InvalidUri;
	const addr_port = uri[scheme_sep + 3..];
	const colon_idx = std.mem.indexOfScalar(u8, addr_port, ':') orelse return error.InvalidUri;

	const host = addr_port[0..colon_idx];
	const port_str = addr_port[colon_idx + 1..];
	const port = try std.fmt.parseInt(u16, port_str, 10);

	const allocator = std.heap.page_allocator;

	const c_host_buf = try toNullTerminated(allocator, host);
	const c_username_buf = try toNullTerminated(allocator, username);
	const c_password_buf = try toNullTerminated(allocator, password);

	defer allocator.free(c_host_buf);
	defer allocator.free(c_username_buf);
	defer allocator.free(c_password_buf);

	const c_host: [*:0]const u8 = @as([*:0]const u8, c_host_buf.ptr);
	const c_username: [*:0]const u8 = @as([*:0]const u8, c_username_buf.ptr);
	const c_password: [*:0]const u8 = @as([*:0]const u8, c_password_buf.ptr);

	_ = c.mg_init();

	const params = c.mg_session_params_make() orelse return error.AllocationFailed;
	defer c.mg_session_params_destroy(params);

	_ = c.mg_session_params_set_host(params, c_host);
	_ = c.mg_session_params_set_port(params, port);
	_ = c.mg_session_params_set_username(params, c_username);
	_ = c.mg_session_params_set_password(params, c_password);
	_ = c.mg_session_params_set_sslmode(params, c.MG_SSLMODE_DISABLE);

	var session: ?*c.mg_session = null;
	if (c.mg_connect(params, &session) < 0 or session == null) {
		std.debug.print("❌ Failed to connect to Memgraph\n", .{});
		return error.ConnectionFailed;
	}
	defer c.mg_session_destroy(session);

	std.debug.print("✅ Connected to Memgraph at {s}:{d}\n", .{ host, port });

	_ = c.mg_finalize();
}

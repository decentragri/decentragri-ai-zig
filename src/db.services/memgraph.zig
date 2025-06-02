const std = @import("std");
const c = @cImport({ @cInclude("mgclient.h"); });
const constants = @import("../utils/constants.zig");



const env_file = @embedFile("../.env");

pub fn initMemgraph() !void {
	// Extract the full URI: "bolt://decentragri-memgraph:7687"
	const uri:[]const u8 = try constants.neo4j_uri;
	const username:[]const u8 = try constants.neo4j_username;
	const password:[]const u8 = try constants.neo4j_password;



	// Parse host and port from the URI
	const scheme_sep = std.mem.indexOf(u8, uri, "://") orelse return error.InvalidUri;
	const addr_port = uri[scheme_sep + 3..];
	const colon_idx = std.mem.indexOfScalar(u8, addr_port, ':') orelse return error.InvalidUri;

	const host = addr_port[0..colon_idx];
	const port_str = addr_port[colon_idx + 1..];

	const port = try std.fmt.parseInt(u16, port_str, 10);

	// Initialize Memgraph client
	_ = c.mg_init();

	const params = c.mg_session_params_make() orelse return error.AllocationFailed;
	defer c.mg_session_params_destroy(params);

	_ = c.mg_session_params_set_host(params, host.ptr);
	_ = c.mg_session_params_set_port(params, port);
	_ = c.mg_session_params_set_username(username);
	_ = c.mg_session_params_set_password(password);
	_ = c.mg_session_params_set_sslmode(params, c.MG_SSLMODE_DISABLE);

	var session: ?*c.mg_session = null;
	if (c.mg_connect(params, &session) < 0 or session == null) {
		return error.ConnectionFailed;
	}
	defer c.mg_session_destroy(session);

	std.debug.print("✅ Successfully connected to Memgraph at {s}:{d}\n", .{ host, port });

	_ = c.mg_finalize();
}

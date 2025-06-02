const std = @import("std");
const dotenv = @import("dotenv");

// Load the .env file content
const env_path = ".env";
const env_file = @embedFile(env_path);
const secret_key: []const u8 = dotenv.parse_key("SECRET_KEY", env_file) orelse "";





const headers_const = [_]struct { key: []const u8, value: []const u8 }{
    .{ .key = "Content-Type", .value = "application/json" },
    .{ .key = "X-Secret-Key", .value = secret_key },
};

pub fn create(label: []const u8, allocator: std.mem.Allocator) ![]u8 {
    if (secret_key.len == 0) {
        return error.MissingSecretKey;
    }

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const url = "https://engine.thirdweb.com/v1/accounts";
    var req = try client.request(.POST, url, .{});
    defer req.deinit();

    try req.headers.append("Content-Type", "application/json");
    try req.headers.append("X-Secret-Key", secret_key);

    // Build JSON body
    var json_stream = std.json.StringifyStream.init(allocator);
    defer json_stream.deinit();

    try json_stream.beginObject();
    try json_stream.objectField("label");
    try json_stream.emitString(label);
    try json_stream.endObject();

    const body = json_stream.toOwnedSlice();
    defer allocator.free(body);

    // Use httpPostJson
    const res_body = try httpPostJson(allocator, url, &headers_const, body);
    defer allocator.free(res_body);

    // Parse JSON response
    const Result = struct {
        result: struct {
            address: []const u8,
            label: []const u8,
            smartAccountAddress: []const u8,
        },
    };

    var parsed = try std.json.parseFromSlice(Result, allocator, res_body, .{});
    defer parsed.deinit();

    return try allocator.dupe(u8, parsed.value.result.smartAccountAddress);
}


pub fn httpPostJson(
    allocator: std.mem.Allocator,
    url: []const u8,
    headers: []const struct { key: []const u8, value: []const u8 },
    json_body: []const u8,
) ![]u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var req = try client.request(.POST, url, .{});
    defer req.deinit();

    for (headers) |header| {
        try req.headers.append(header.key, header.value);
    }

    try req.writeAll(json_body);
    try req.finish();

    var res = try req.response();
    defer res.deinit();

    return try res.bodyAsAlloc(allocator, 10 * 1024); // up to 10KB
}

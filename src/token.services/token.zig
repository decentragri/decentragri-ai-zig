const std = @import("std");
const jwt = @import("jwt");
const dotenv = @import("dotenv");

const env_path = ".env";
const env_file = @embedFile(env_path);
const jwt_secret: []const u8 = dotenv.parse_key("JWT_SECRET", env_file) orelse "";



const Tokens = struct {
    accessToken: []const u8,
    refreshToken: []const u8,
};
















pub fn generateTokens(username: []const u8, allocator: std.mem.Allocator) !Tokens {
    // Prepare payloads
    const access_payload = try std.fmt.allocPrint(allocator, "{{\"sub\":\"{s}\",\"type\":\"access\"}}", .{username});
    defer allocator.free(access_payload);

    const refresh_payload = try std.fmt.allocPrint(allocator, "{{\"sub\":\"{s}\",\"type\":\"refresh\"}}", .{username});
    defer allocator.free(refresh_payload);

    // Generate tokens
    const access_token = try generateAccessToken(username, allocator);

    const refresh_token = try jwt.generate_signature(
        .HS256,
        jwt_secret,
        null, // default header
        refresh_payload,
        allocator,
    );

    return Tokens{
        .accessToken = access_token,
        .refreshToken = refresh_token,
    };
}


fn generateAccessToken(username: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    // Prepare payload
    const payload = try std.fmt.allocPrint(allocator, "{{\"sub\":\"{s}\",\"type\":\"access\"}}", .{username});
    defer allocator.free(payload);

    // Generate access token
    return try jwt.generate_signature(
        .HS256,
        jwt_secret,
        null, // default header
        payload,
        allocator,
    );
}


pub fn verifyAccessToken(accessToken: []const u8, allocator: std.mem.Allocator) !Tokens {
    // Validate the access token
    const result = try jwt.validate(accessToken, jwt_secret, allocator);
    defer allocator.free(result.payload);

    // Parse the payload to extract the username ("sub")
    const payload = result.payload;
    const sub_key = "\"sub\":\"";
    const sub_start = std.mem.indexOf(u8, payload, sub_key) orelse return error.InvalidToken;
    const sub_value_start = sub_start + sub_key.len;
    const sub_end = std.mem.indexOfScalar(u8, payload[sub_value_start..], '"') orelse return error.InvalidToken;
    const username = payload[sub_value_start .. sub_value_start + sub_end];

    			const result = await session.run(
				`MATCH (u:User {username: $userName}) RETURN u.username AS username`,
				{ userName }
			);

}


pub fn verifyRefreshToken(refreshToken: []const u8, allocator: std.mem.Allocator) !Tokens {
    // Validate the refresh token
    const result = try jwt.validate(refreshToken, jwt_secret, allocator);
    defer allocator.free(result.payload);

    // Parse the payload to extract the username ("sub")
    const payload = result.payload;
    const sub_key = "\"sub\":\"";
    const sub_start = std.mem.indexOf(u8, payload, sub_key) orelse return error.InvalidToken;
    const sub_value_start = sub_start + sub_key.len;
    const sub_end = std.mem.indexOfScalar(u8, payload[sub_value_start..], '"') orelse return error.InvalidToken;
    const username = payload[sub_value_start .. sub_value_start + sub_end];

    // Generate new tokens for the username
    return try generateTokens(username, allocator);
}

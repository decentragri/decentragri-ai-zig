const std = @import("std");
const dotenv = @import("dotenv");

pub const Env = struct {
	env: dotenv.Env,

	pub fn init(allocator: std.mem.Allocator) !Env {
		var file = try std.fs.cwd().openFile(".env", .{});
		defer file.close();

		const content = try file.readToEndAlloc(allocator, 1024 * 1024);
		return Env{
			.env = try dotenv.init(allocator, content),
		};
	}

	pub fn get(self: *const Env, key: []const u8) ?[]const u8 {
		return @constCast(&self.env).get(key);
	}

};

const std = @import("std");
const engine = @import("../engine/engine.zig");




pub fn createWallet(username: []const u8) ![]const u8 {
    const wallet_address = try engine.create(username, std.heap.page_allocator);
    return wallet_address;
}
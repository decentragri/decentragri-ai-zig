const std = @import("std");
const wallet = @import("../wallet.services/wallet.struct.zig");


pub const UserRegistration = struct {
    username: []const u8,
    password: []const u8,
    device_id: []const u8,
};


pub const UserLoginResponse = struct {
    username: []const u8,
    walletAddress: []const u8,
    accessToken: []const u8,
    refreshToken: []const u8,
    loginType: "decentragri",
    walletData: wallet.WalletData,
};
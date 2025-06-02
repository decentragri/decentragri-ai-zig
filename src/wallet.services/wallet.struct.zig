

pub const WalletData = struct {
    smartWalletAddress: []const u8,
    dagriBalance: []const u8,
    rsWETHBalance: []const u8,
    ethBalance: []const u8,
    swellBalance: []const u8,

    dagriPriceUSD: f64,
    ethPriceUSD: f64,
    swellPriceUSD: f64,

};
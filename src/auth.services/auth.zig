const std = @import("std");
const structs = @import("../auth.services/auth.struct.zig");





pub fn register(user:  structs.UserRegistration) structs.UserRegistration {
    const user_data = structs.UserRegistration{
        .username = user.username,
        .email = user.email,
        .password = user.password,
    };
    













}
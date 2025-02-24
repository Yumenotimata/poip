const std = @import("std");
const testing = std.testing;

comptime {
    std.testing.refAllDecls(@This());
}

pub const type_ = @import("type.zig");

const std = @import("std");
const testing = std.testing;

const pretty = @import("pretty.zig");

const KindTag = enum { star, kfun };

pub const Kind = union(KindTag) {
    star: void,
    kfun: struct { lhs: *const Kind, rhs: *const Kind },

    pub fn star(allocator: std.mem.Allocator) error{OutOfMemory}!*const Kind {
        const new = try allocator.create(Kind);
        new.* = Kind{ .star = {} };
        return new;
    }

    pub fn kfun(allocator: std.mem.Allocator, lhs: *const Kind, rhs: *const Kind) error{OutOfMemory}!*const Kind {
        const new = try allocator.create(Kind);
        new.* = Kind{ .kfun = .{ .lhs = lhs, .rhs = rhs } };
        return new;
    }
};

const TypeTag = enum { tvar, tcon, tapp };

pub const Type = union(TypeTag) {
    tvar: TVar,
    tcon: TCon,
    tapp: struct { *Type, *Type },

    pub fn apply(self: @This(), subst: Subst) Type {
        switch (self) {
            .tvar => |tvar| try subst.get(tvar.id),
            else => |t| t,
        }
    }
};

const TVar = struct { id: []const u8, kind: Kind };

const TCon = struct { id: []const u8, kind: Kind };

const Subst = std.StringHashMap(Type);

test "Type Test" {
    std.debug.print("Running Type Test", .{});

    const allocator = std.heap.page_allocator;
    const t1 = try Kind.star(allocator);
    const t2 = try Kind.kfun(allocator, try Kind.star(allocator), t1);
    // _ = t1;
    _ = t2;
}

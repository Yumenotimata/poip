const std = @import("std");
const testing = std.testing;

const pretty = @import("pretty.zig");

const TypeError = error{
    UndefinedTypeVariable,
};

const KindTag = enum { star, kfun };

pub const Kind = union(KindTag) {
    star: void,
    kfun: struct { lhs: *Kind, rhs: *Kind },
};

pub const KindF = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) KindF {
        return KindF{ .allocator = allocator };
    }

    pub fn star(self: @This()) error{OutOfMemory}!*Kind {
        const new = try self.allocator.create(Kind);
        new.* = Kind{ .star = {} };
        return new;
    }

    pub fn kfun(self: @This(), lhs: *Kind, rhs: *Kind) error{OutOfMemory}!*Kind {
        const new = try self.allocator.create(Kind);
        new.* = Kind{ .kfun = .{ .lhs = lhs, .rhs = rhs } };
        return new;
    }
};

const TypeTag = enum { tvar, tcon, tapp };

pub const Type = union(TypeTag) {
    tvar: TVar,
    tcon: TCon,
    tapp: struct { lhs: *Type, rhs: *Type },

    pub fn apply(self: *@This(), subst: *Subst) TypeError!void {
        switch (self.*) {
            .tvar => |v| {
                const t = try subst.lookup(v.id);
                self.* = t.*;
            },
            .tapp => |app| {
                try app.lhs.apply(subst);
                try app.rhs.apply(subst);
            },
            else => {},
        }
    }
};

pub const TypeF = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TypeF {
        return TypeF{ .allocator = allocator };
    }

    pub fn tvar(self: @This(), v: TVar) error{OutOfMemory}!*Type {
        const new = try self.allocator.create(Type);
        new.* = Type{ .tvar = v };
        return new;
    }

    pub fn tcon(self: @This(), c: TCon) error{OutOfMemory}!*Type {
        const new = try self.allocator.create(Type);
        new.* = Type{ .tcon = c };
        return new;
    }

    pub fn tapp(self: @This(), lhs: *Type, rhs: *Type) error{OutOfMemory}!*Type {
        const new = try self.allocator.create(Type);
        new.* = Type{ .tapp = .{ .lhs = lhs, .rhs = rhs } };
        return new;
    }
};

const TVar = struct { id: []const u8, kind: *Kind };

const TCon = struct { id: []const u8, kind: *Kind };

const Subst = struct {
    inner: std.StringHashMap(*Type),

    pub fn init(allocator: std.mem.Allocator) Subst {
        return Subst{ .inner = std.StringHashMap(*Type).init(allocator) };
    }

    pub fn lookup(self: *@This(), id: []const u8) TypeError!*Type {
        if (self.inner.get(id)) |t| {
            return t;
        } else {
            return TypeError.UndefinedTypeVariable;
        }
    }

    pub fn append(self: *@This(), id: []const u8, t: *Type) error{OutOfMemory}!void {
        try self.inner.put(id, t);
    }

    pub fn appendix(self: *@This(), pairs: []const struct { id: []const u8, t: *Type }) error{OutOfMemory}!void {
        for (pairs) |pair| {
            try self.append(pair.id, pair.t);
        }
    }
};

pub const SubstF = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) SubstF {
        return SubstF{ .allocator = allocator };
    }

    pub fn empty(self: @This()) error{OutOfMemory}!Subst {
        return Subst.init(self.allocator);
    }

    pub fn from(self: @This(), pairs: []const struct { id: []const u8, t: *Type }) error{OutOfMemory}!Subst {
        const subst = Subst.init(self.allocator);
        try subst.appendix(pairs);
        return subst;
    }
};

test "Type Test" {
    std.debug.print("Running Type Test", .{});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const tf = TypeF.init(allocator);
    const kf = KindF.init(allocator);
    const sf = SubstF.init(allocator);

    
}

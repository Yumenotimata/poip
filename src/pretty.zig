const Showable = struct {
    ptr: *anyopaque,
    showFn: *const fn (ptr: *anyopaque) anyerror!void,

    fn show(self: Showable) !void {
        return self.showFn(self.ptr);
    }
};

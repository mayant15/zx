const std = @import("std");

const List = @This();

allocator: std.mem.Allocator,
data: std.ArrayList(u8),
template: []const u8 = @embedFile("../templates/list.html"),

pub fn view(self: *List) ![]const u8 {
    var html: []u8 = "";
    for (self.data.items) |_| {
        html = try std.fmt.allocPrint(self.allocator, "{s}\n{s}", .{ html, self.template });
    }
    return html;
}

pub fn update(self: *List, target: []const u8) !void {
    _ = target;
    try self.data.append(0);
}

pub fn init() List {
    const allocator = std.heap.page_allocator;
    return .{
        .allocator = allocator,
        .data = std.ArrayList(u8).init(allocator),
    };
}

pub fn deinit(self: *List) void {
    self.data.deinit();
}

pub fn reset(self: *List) void {
    self.data.clearAndFree();
}

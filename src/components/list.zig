const std = @import("std");
const Db = @import("../db.zig");

const List = @This();

allocator: std.mem.Allocator,
template: []const u8 = @embedFile("../templates/list.html"),
data: *Db,

pub fn view(self: *List) ![]const u8 {
    var html: []u8 = "";
    const tasks = try self.data.get_all_tasks();
    for (tasks) |t| {
        html = try std.fmt.allocPrint(self.allocator, "{s}\n<p>{s}</p>", .{ html, t.description });
    }
    return html;
}

pub fn update(self: *List, target: []const u8, body: []const u8) !void {
    _ = target;

    var parsed = try std.json.parseFromSlice(struct { description: []const u8 }, self.allocator, body, .{});
    defer parsed.deinit();

    try self.data.add_new_task(parsed.value.description);
}

pub fn init(db: *Db) List {
    const allocator = std.heap.page_allocator;
    return .{
        .allocator = allocator,
        .data = db,
    };
}

pub fn deinit(self: *List) void {
    self.data.deinit();
}

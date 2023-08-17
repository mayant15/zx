const std = @import("std");

const sqlite = @import("sqlite");
const models = @import("./models.zig");

const Task = models.Task;

const Db = @This();

db: sqlite.Db,
allocator: std.mem.Allocator,

pub fn init() !Db {
    const db = try sqlite.Db.init(.{
        .mode = .{ .File = "store.db" },
        .open_flags = .{
            .write = true,
        },
    });
    return .{
        .db = db,
        .allocator = std.heap.page_allocator,
    };
}

pub fn deinit(self: *Db) void {
    self.db.deinit();
}

pub fn get_all_tasks(self: *Db) ![]Task {
    const query =
        \\SELECT description FROM tasks
    ;
    var diags = sqlite.Diagnostics{};
    var stmt = self.db.prepareWithDiags(query, .{ .diags = &diags }) catch |err| {
        std.log.err("unable to prepare statement, got error {}. diagnostics: {s}", .{ err, diags });
        return err;
    };
    defer stmt.deinit();

    return stmt.all(Task, self.allocator, .{}, .{});
}

pub fn add_new_task(self: *Db, description: []const u8) !void {
    const query =
        \\INSERT INTO tasks(description) VALUES($description)
    ;
    var diags = sqlite.Diagnostics{};
    var stmt = self.db.prepareWithDiags(query, .{ .diags = &diags }) catch |err| {
        std.log.err("unable to prepare statement, got error {}. diagnostics: {s}", .{ err, diags });
        return err;
    };
    defer stmt.deinit();

    return stmt.exec(.{}, .{
        .description = description,
    });
}

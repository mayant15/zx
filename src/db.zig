const std = @import("std");

const sqlite = @import("sqlite");
const models = @import("./models.zig");

const Todo = models.Todo;

const Db = @This();

db: sqlite.Db,

pub fn init() !Db {
    const db = try sqlite.Db.init(.{
        .mode = sqlite.Db.Mode{ .File = "store.db" },
    });
    return .{
        .db = db,
    };
}

pub fn deinit(self: *Db) void {
    self.db.deinit();
}

pub fn get_one_todo(self: *Db) !?Todo {
    const query =
        \\SELECT contents FROM todos
    ;
    var diags = sqlite.Diagnostics{};
    var stmt = self.db.prepareWithDiags(query, .{ .diags = &diags }) catch |err| {
        std.log.err("unable to prepare statement, got error {}. diagnostics: {s}", .{ err, diags });
        return err;
    };
    defer stmt.deinit();

    return stmt.one(Todo, .{}, .{});
}

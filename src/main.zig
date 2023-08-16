const std = @import("std");

const List = @import("./components/list.zig");
const Root = @import("./components/root.zig");

const Db = @import("./db.zig");

const allocator = std.heap.page_allocator;

fn clicked(list: *List) ![]const u8 {
    try list.update("/clicked");
    return list.view();
}

fn root(list: *List) ![]const u8 {
    _ = list;
    return Root.view();
}

fn router(target: []const u8, list: *List) ![]const u8 {
    if (std.mem.eql(u8, target, "/")) {
        return root(list);
    } else if (std.mem.eql(u8, target, "/clicked")) {
        return clicked(list);
    } else {
        return "";
    }
}

pub fn main() !void {
    var server = std.http.Server.init(allocator, .{});
    defer server.deinit();

    const address = try std.net.Address.parseIp("127.0.0.1", 9000);
    try server.listen(address);
    std.log.info("Listening on {}", .{address});

    var db = try Db.init();
    var list = List.init(&db);

    while (server.accept(.{ .allocator = allocator })) |res| {
        var response = res;
        defer response.deinit();
        defer _ = response.reset();

        try response.wait();

        std.log.info("TARGET: {s}", .{response.request.target});

        const server_body = try router(response.request.target, &list);
        response.transfer_encoding = .{ .content_length = server_body.len };
        try response.headers.append("content-type", "text/html");
        try response.headers.append("connection", "close");
        try response.do();

        _ = try response.writer().writeAll(server_body);
        try response.finish();
    } else |err| {
        std.log.err("ERROR: {}", .{err});
    }

    list.deinit();
    db.deinit();
}

const std = @import("std");

const List = @import("./components/list.zig");
const Root = @import("./components/root.zig");

const Db = @import("./db.zig");
const models = @import("./models.zig");

const allocator = std.heap.page_allocator;

fn router(response: *std.http.Server.Response, list: *List) ![]const u8 {
    const target = response.request.target;

    var buf: [1024]u8 = undefined;
    const size = try response.request.parser.read(&response.connection, &buf, false);
    const body = buf[0..size];

    if (std.mem.eql(u8, target, "/")) {
        return Root.view();
    } else if (std.mem.eql(u8, target, "/add")) {
        try list.update("/add", body);
        return list.view();
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

        const server_body = try router(&response, &list);
        response.transfer_encoding = .{ .content_length = server_body.len };
        try response.headers.append("content-type", "text/html");
        try response.headers.append("connection", "close");
        try response.do();

        _ = try response.writer().writeAll(server_body);
        try response.finish();
    } else |err| {
        std.log.err("{}", .{err});
    }

    list.deinit();
    db.deinit();
}

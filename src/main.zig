const std = @import("std");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var server = std.http.Server.init(allocator, .{});
    defer server.deinit();

    const address = try std.net.Address.parseIp("127.0.0.1", 9000);
    try server.listen(address);
    std.log.info("Listening on {}", .{address});

    while (server.accept(.{ .allocator = allocator })) |res| {
        var response = res;
        defer response.deinit();
        defer _ = response.reset();

        try response.wait();

        const server_body: []const u8 = "message from server!\n";
        response.transfer_encoding = .{ .content_length = server_body.len };
        try response.headers.append("content-type", "text/plain");
        try response.headers.append("connection", "close");
        try response.do();

        _ = try response.writer().writeAll(server_body);
        try response.finish();
    } else |err| {
        std.log.err("ERROR: {}", .{err});
    }
}

const std = @import("std");

const allocator = std.heap.page_allocator;

fn get_page_html(path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const buf = try file.readToEndAlloc(std.heap.page_allocator, 1_000_000);
    return buf;
}

fn clicked() ![]const u8 {
    const html = try get_page_html("templates/clicked.html");
    return html;
}

fn root() ![]const u8 {
    const html = try get_page_html("templates/index.html");
    return html;
}

fn router(target: []const u8) ![]const u8 {
    if (std.mem.eql(u8, target, "/")) {
        return root();
    } else if (std.mem.eql(u8, target, "/clicked")) {
        return clicked();
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

    while (server.accept(.{ .allocator = allocator })) |res| {
        var response = res;
        defer response.deinit();
        defer _ = response.reset();

        try response.wait();

        std.log.info("TARGET: {s}", .{response.request.target});

        const server_body = try router(response.request.target);
        response.transfer_encoding = .{ .content_length = server_body.len };
        try response.headers.append("content-type", "text/html");
        try response.headers.append("connection", "close");
        try response.do();

        _ = try response.writer().writeAll(server_body);
        try response.finish();
    } else |err| {
        std.log.err("ERROR: {}", .{err});
    }
}

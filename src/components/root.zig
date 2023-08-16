const std = @import("std");

pub fn view() []const u8 {
    return @embedFile("../templates/index.html");
}

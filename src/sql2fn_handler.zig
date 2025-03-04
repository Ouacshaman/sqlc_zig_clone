const std = @import("std");

pub fn createFn(name: []const u8, query: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try list.appendSlice(name);
    const end_of_name = std.mem.indexOf(u8, name[11..], ":");

    const signature = try std.fmt.allocPrint(allocator, "\npub fn {s}(stream: std.net.Stream, allocator: std.mem.Allocator) ![]const u8{s}\n", .{ name[11 .. 11 + end_of_name.? - 1], "{" });
    try list.appendSlice(signature);
    defer allocator.free(signature);

    const query_line = try std.fmt.allocPrint(allocator, "    const res = try query.sendQuery(stream, allocator, \"{s}\");\n    return res;\n{s}\n", .{ query, "}" });
    try list.appendSlice(query_line);
    defer allocator.free(query_line);

    return try list.toOwnedSlice();
}

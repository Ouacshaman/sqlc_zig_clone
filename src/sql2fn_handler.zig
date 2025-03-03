const std = @import("std");

pub fn createFn(name: []const u8, query: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try list.appendSlice(name);
    const end_of_name = std.mem.indexOf(u8, name[11..], ":");

    const signature = try std.fmt.allocPrint(allocator, "\npub fn {s}(stream: std.net.Stream, allocator: std.mem.Allocator) !void{s}\n", .{ name[11 .. 11 + end_of_name.? - 1], "{" });
    defer allocator.free(signature);
    try list.appendSlice(signature);

    const query_line = try std.fmt.allocPrint(allocator, "    try query.sendQuery(stream, allocator, \"{s}\");\n{s}\n", .{ query, "}" });
    defer allocator.free(query_line);
    try list.appendSlice(query_line);

    const joined = try list.toOwnedSlice();
    defer allocator.free(joined);
    const res = try alloc.dupe(u8, joined);

    return res;
}

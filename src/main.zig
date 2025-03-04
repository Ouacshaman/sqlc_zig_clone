const std = @import("std");
const connect = @import("connect.zig");
const Startup = @import("pg_proto_startup.zig");
const Query = @import("pg_proto_query.zig");
const Json = @import("json.zig");
const ReadQL = @import("read_sql.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    defer _ = gpa.detectLeaks();
    const allocator = gpa.allocator();

    const value = Json.readConfig(allocator) catch return error.UnableToReadJSON;
    defer {
        allocator.free(value.default_user);
        allocator.free(value.default_database);
        allocator.free(value.default_host);
        allocator.free(value.default_port);
    }

    const args = std.os.argv;

    if (args.len < 1) {
        std.debug.print("Usage: {s} <query>\n", .{args[0]});
        return error.NoQuery;
    }

    const port = try std.fmt.parseInt(u16, value.default_port, 10);

    const stream = try connect.connect(value.default_host, port);
    defer stream.close();

    std.debug.print("User: {s}, Database: {s}\n", .{ value.default_user, value.default_database });

    try Startup.sendStartup(stream, allocator, value.default_user, value.default_database);

    const first_arg = args[1][0..std.mem.len(args[1])];
    const multi_queries = try ReadQL.read(allocator);
    defer allocator.free(multi_queries.content);
    defer allocator.free(multi_queries.queries);

    if (std.mem.eql(u8, first_arg, "generate")) {
        var i: usize = 0;
        while (i < multi_queries.queries.len) : (i += 1) {
            if (std.mem.startsWith(u8, multi_queries.queries[i], "--") or std.mem.eql(u8, multi_queries.queries[i], "")) {
                continue;
            }
            const output_1 = try Query.sendQuery(stream, allocator, multi_queries.queries[i]);
            defer allocator.free(output_1);
            std.debug.print("Queries Response from SQL file: {s}\n", .{output_1});
        }
    } else {
        const single = try Query.sendQuery(stream, allocator, args[1][0..std.mem.len(args[1])]);
        defer allocator.free(single);
        std.debug.print("Singular Query Response: {s}\n", .{single});
    }
}

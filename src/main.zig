const std = @import("std");
const db = @import("database.zig");
const connect = @import("connect.zig");
const Startup = @import("pg_proto_startup.zig");
const Query = @import("pg_proto_query.zig");

pub fn main() !void {
    const args = std.os.argv;

    if (args.len < 4) {
        std.debug.print("Usage: {s} <username> <password> <query>\n", .{args[0]});
        return error.NotEnoughArguments;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const localhost = "127.0.0.1";
    const host = std.posix.getenv("HOST") orelse localhost;
    const string_port = std.posix.getenv("PORT") orelse "5432";
    const port = try std.fmt.parseInt(u16, string_port, 10);

    const stream = try connect.connect(host, port);
    defer stream.close();

    try Startup.sendStartup(stream, allocator, args[1][0..std.mem.len(args[1])], args[2][0..std.mem.len(args[2])]);
    try Query.sendQuery(stream, allocator, args[3][0..std.mem.len(args[3])]);
}

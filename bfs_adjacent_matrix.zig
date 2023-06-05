const std = @import("std");
const expect = std.testing.expect;
const log = std.log;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Queue = @import("queue.zig").Queue;

fn printMatrix(mat: anytype) void {
    const nrows = mat.len;
    const ncols = mat[0].len;
    log.warn("print {}x{} matrix", .{ nrows, ncols });
    for (mat) |row| {
        for (row) |item| {
            print(" {} ", .{item});
        }
        print("\n", .{});
    }
}

fn bfs(allocator: Allocator, graph: anytype, source: u8, needle: u8) ![]u8 {
    var seen = try ArrayList(bool).initCapacity(allocator, graph.len);
    for (graph, 0..) |_, i| {
        try seen.insert(i, false);
    }

    var previous = try ArrayList(i16).initCapacity(allocator, graph.len);
    for (graph, 0..) |_, i| {
        try previous.insert(i, -1);
    }

    var q = Queue(u8).init(allocator);
    try q.enqueue(source);
    seen.items[source] = true;

    while (q.len > 0) {
        const current = q.deque();
        if (current == null) {
            continue;
        }
        if (current == needle) {
            break;
        }

        for (graph[@intCast(usize, current.?)], 0..) |v, i| {
            if (seen.items[i] == true or v == 0) {
                continue;
            }

            const num = @intCast(u8, i);
            seen.items[i] = true;
            previous.items[i] = current.?;
            q.enqueue(num) catch log.err("Cannot enqueue", .{});
        }
        seen.items[current.?] = true;
    }

    // build path backwards

    var curr_previous = needle;
    var path = ArrayList(u8).init(allocator);

    while (previous.items[curr_previous] != -1) {
        curr_previous = @intCast(u8, previous.items[curr_previous]);
        try path.append(curr_previous);
    }

    if (path.items.len > 0) {
        var result = path.items;
        std.mem.reverse(u8, result);
        return result;
    }

    return path.items;
}

test "bfs" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const graph = [_][5]u32{
        [_]u32{ 0, 1, 1, 0, 0 },
        [_]u32{ 0, 0, 0, 1, 0 },
        [_]u32{ 0, 0, 0, 0, 0 },
        [_]u32{ 0, 0, 1, 0, 1 },
        [_]u32{ 0, 0, 0, 0, 0 },
    };
    printMatrix(graph);

    const path = try bfs(arena.allocator(), graph, 0, 4);
    log.warn("path = {any}", .{path});
    try expect(path[0] == 0);
    try expect(path[1] == 1);
    try expect(path[2] == 3);
}

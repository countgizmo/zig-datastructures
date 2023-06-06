const std = @import("std");
const expect = std.testing.expect;
const log = std.log;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

fn printAdjacentLit(graph: anytype) void {
    print("printing adjacent list\n", .{});
    for (graph, 0..) |row, i| {
        print("Vertex {d} ", .{i});
        if (row) |r| {
            print("{any}", .{r.items});
        } else {
            print("---", .{});
        }
        print("\n", .{});
    }
}

fn walk(graph: anytype, current: ?u8, needle: u8, seen: ArrayList(bool), path: *ArrayList(u8)) bool {
    if (current == null) {
        return false;
    }

    const current_idx = @intCast(usize, current.?);
    if (seen.items[current_idx]) {
        return false;
    }

    seen.items[current_idx] = true;
    path.append(current.?) catch log.err("Could not append to path", .{});

    if (current == needle) {
        return true;
    }

    if (graph[current_idx]) |list| {
        var i: usize = 0;
        while (i < list.items.len) : (i += 1) {
            if (walk(graph, list.items[i], needle, seen, path)) {
                return true;
            }
        }
    }
    _ = path.pop();

    return false;
}

pub fn dfs(allocator: Allocator, graph: anytype, source: u8, needle: u8) ![]u8 {
    var seen = try ArrayList(bool).initCapacity(allocator, graph.len);
    for (graph, 0..) |_, i| {
        try seen.insert(i, false);
    }

    var path = ArrayList(u8).init(allocator);
    _ = walk(graph, source, needle, seen, &path);
    return path.items;
}

test "dfs" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var v0 = ArrayList(u8).init(arena.allocator());
    try v0.append(1);
    try v0.append(2);
    var v1 = ArrayList(u8).init(arena.allocator());
    try v1.append(3);
    var v3 = ArrayList(u8).init(arena.allocator());
    try v3.append(2);
    try v3.append(4);

    const graph = [_]?ArrayList(u8){ v0, v1, null, v3, null };

    printAdjacentLit(graph);
    const path = try dfs(arena.allocator(), graph, 0, 4);
    log.warn("path = {any}", .{path});
    try expect(path[0] == 0);
    try expect(path[1] == 1);
    try expect(path[2] == 3);
    try expect(path[3] == 4);
}

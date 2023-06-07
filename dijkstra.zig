const std = @import("std");
const expect = std.testing.expect;
const log = std.log;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const math = std.math;

const Edge = struct {
    to: u8,
    weight: u8,
};

// We can use a heap instead all of this

fn getUnvisited(allocator: Allocator, seen: ArrayList(bool), dists: ArrayList(u16)) ArrayList(u8) {
    var v = ArrayList(u8).init(allocator);
    for (seen.items, 0..) |_, i| {
        if (seen.items[i] == false and dists.items[i] < math.maxInt(u16)) {
            v.append(@intCast(u8, i)) catch log.err("Could not append to unvisited", .{});
        }
    }

    return v;
}

fn closestUnvisited(seen: ArrayList(bool), dists: ArrayList(u16)) ?u8 {
    var lowest_distance: u16 = math.maxInt(u16);
    var lowest_idx: ?u8 = null;
    for (dists.items, 0..) |dist, i| {
        if (seen.items[i]) {
            continue;
        }
        if (lowest_distance > dist) {
            lowest_distance = dist;
            lowest_idx = @intCast(u8, i);
        }
    }

    return lowest_idx;
}

pub fn djikstraList(allocator: Allocator, graph: anytype, source: u8, needle: u8) ![]u8 {
    var seen = try ArrayList(bool).initCapacity(allocator, graph.len);
    var previous = try ArrayList(i16).initCapacity(allocator, graph.len);
    var dists = try ArrayList(u16).initCapacity(allocator, graph.len);
    for (graph, 0..) |_, i| {
        try seen.insert(i, false);
        try previous.insert(i, -1);
        try dists.insert(i, math.maxInt(u16));
    }

    dists.items[source] = 0;

    var unvisited = getUnvisited(allocator, seen, dists);

    while (unvisited.items.len > 0) {
        const current = closestUnvisited(seen, dists);

        if (current == null) {
            break; //something went wrong
        }

        const current_idx = @intCast(usize, current.?);
        seen.items[current_idx] = true;

        if (graph[current_idx]) |list| {
            for (list.items) |edge| {
                if (seen.items[edge.to]) {
                    continue;
                }

                const dist = dists.items[current_idx] + edge.weight;
                if (dist < dists.items[edge.to]) {
                    dists.items[edge.to] = dist;
                    previous.items[edge.to] = @intCast(i16, current.?);
                }
            }
        }
    }

    var curr_previous = needle;
    var path = ArrayList(u8).init(allocator);

    while (previous.items[curr_previous] > -1) {
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

test "path finding" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var v0 = ArrayList(Edge).init(arena.allocator());
    try v0.append(.{ .to = 1, .weight = 2 });
    try v0.append(.{ .to = 3, .weight = 5 });
    var v1 = ArrayList(Edge).init(arena.allocator());
    try v1.append(.{ .to = 3, .weight = 1 });
    var v2 = ArrayList(Edge).init(arena.allocator());
    try v2.append(.{ .to = 4, .weight = 1 });
    var v3 = ArrayList(Edge).init(arena.allocator());
    try v3.append(.{ .to = 2, .weight = 1 });
    try v3.append(.{ .to = 4, .weight = 3 });

    const graph = [_]?ArrayList(Edge){ v0, v1, v2, v3, null };
    const path = try djikstraList(arena.allocator(), graph, 0, 4);
    log.warn("path = {any}", .{path});
    try expect(path[0] == 0);
    try expect(path[1] == 1);
    try expect(path[2] == 3);
    try expect(path[3] == 2);
}

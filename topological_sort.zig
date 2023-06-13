const std = @import("std");
const expect = std.testing.expect;
const log = std.log;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Queue = @import("queue.zig").Queue;

const Vertex = enum {
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
};

fn printAdjacentLit(graph: anytype) void {
    print("printing adjacent list\n", .{});
    for (graph, 0..) |row, i| {
        print("Vertex {s}: ", .{@tagName(@intToEnum(Vertex, i))});
        if (row) |r| {
            for (r.items) |item| {
                print("{c}", .{@tagName(item)});
            }
        } else {
            print("---", .{});
        }
        print("\n", .{});
    }
}

fn bfsWalk(allocator: Allocator, graph: anytype, indegrees: *ArrayList(u8)) !?[]Vertex {
    var order = ArrayList(Vertex).init(allocator);
    var q = Queue(Vertex).init(allocator);
    try q.enqueue(.A);
    indegrees.items[0] = 1; //pretend we've landed at the root from ... somewhere

    while (q.len > 0) {
        const current = q.deque();

        if (current == null) {
            continue;
        }

        const current_idx = @enumToInt(current.?);

        try order.append(current.?);

        if (graph[current_idx] == null) {
            continue;
        }

        for (graph[current_idx].?.items) |item| {
            const item_idx = @enumToInt(item);
            indegrees.items[item_idx] -= 1;
            if (indegrees.items[item_idx] == 0) {
                try q.enqueue(item);
            }
        }
    }

    return order.items;
}

pub fn topologicalSort(allocator: Allocator, graph: anytype) !?[]Vertex {
    var indegrees = try ArrayList(u8).initCapacity(allocator, graph.len);

    for (graph, 0..) |_, idx| {
        try indegrees.insert(idx, 0);
    }

    for (graph) |row| {
        if (row) |r| {
            for (r.items) |item| {
                const item_idx = @enumToInt(item);
                indegrees.items[item_idx] += 1;
            }
        }
    }

    return bfsWalk(allocator, graph, &indegrees);
}

test "topological sorting" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var vA = ArrayList(Vertex).init(arena.allocator());
    try vA.append(.B);
    try vA.append(.C);
    try vA.append(.D);

    var vB = ArrayList(Vertex).init(arena.allocator());
    try vB.append(.C);
    try vB.append(.E);

    const vC = null;

    var vD = ArrayList(Vertex).init(arena.allocator());
    try vD.append(.F);
    try vD.append(.G);

    var vE = ArrayList(Vertex).init(arena.allocator());
    try vE.append(.H);
    try vE.append(.I);
    try vE.append(.F);

    var vF = ArrayList(Vertex).init(arena.allocator());
    try vF.append(.I);
    try vF.append(.J);

    var vG = ArrayList(Vertex).init(arena.allocator());
    try vG.append(.K);

    const vH = null;
    const vI = null;
    const vJ = null;

    var vK = ArrayList(Vertex).init(arena.allocator());
    try vK.append(.J);

    const graph = [_]?ArrayList(Vertex){ vA, vB, vC, vD, vE, vF, vG, vH, vI, vJ, vK };

    printAdjacentLit(graph);

    const order = try topologicalSort(arena.allocator(), graph);
    const expected_order = [_]Vertex{ .A, .B, .D, .C, .E, .G, .H, .F, .K, .I, .J };

    log.warn("Order: ", .{});
    for (expected_order, 0..) |expected_vertex, i| {
        log.warn("{c}", .{@tagName(expected_vertex)});
        try expect(expected_vertex == order.?[i]);
    }
}

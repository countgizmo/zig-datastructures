const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const Queue = @import("queue.zig").Queue;

pub fn Tree(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            value: T,
            left: ?*Node = null,
            right: ?*Node = null,
        };

        root: ?*Node = null,
        allocator: Allocator,

        fn newNode(self: Self, value: T) ?*Node {
            const node = self.allocator.create(Node) catch null;
            if (node) |n| {
                n.right = null;
                n.left = null;
                n.value = value;
                return n;
            }

            return null;
        }

        pub fn init(allocator: Allocator) !Self {
            return .{
                .allocator = allocator,
            };
        }

        fn compareNodes(n1: ?*Node, n2: ?*Node) bool {
            if (n1 == null and n2 == null) return true;
            if (n1 == null or n2 == null) return false;
            if (n1.?.value != n2.?.value) return false;

            return compareNodes(n1.?.left, n2.?.left) and compareNodes(n1.?.right, n2.?.right);
        }

        pub fn compare(a: *Self, b: *Self) bool {
            return compareNodes(a.root, b.root);
        }

        pub fn insertAt(self: *Self, node: ?*Node, value: T) ?*Node {
            const new_node = self.newNode(value);

            if (new_node == null) return null;

            if (self.root == null) {
                self.root = new_node;
                return new_node;
            }

            if (node == null) return null;

            if (value <= node.?.value) {
                node.?.left = new_node;
            } else {
                node.?.right = new_node;
            }

            return new_node;
        }

        fn dfsRecursive(self: *Self, node: ?*Node, needle: T) bool {
            if (node == null) {
                return false;
            }

            std.log.warn("Visiting node {d}", .{node.?.value});
            if (node.?.value == needle) {
                return true;
            }

            return self.dfsRecursive(node.?.left, needle) or self.dfsRecursive(node.?.right, needle);
        }
        pub fn dfs(self: *Self, needle: T) bool {
            return self.dfsRecursive(self.root, needle);
        }

        pub fn bfs(self: *Self, needle: T) bool {
            if (self.root == null) {
                return false;
            }

            var queue = Queue(?*Node).init(self.allocator);
            var current: ?*Node = undefined;
            queue.enqueue(self.root) catch std.log.err("Cannot enque", .{});

            while (queue.len > 0) {
                current = queue.deque().?;

                if (current == null) continue;
                std.log.warn("Visiting node {d}", .{current.?.value});
                if (current.?.value == needle) return true;

                queue.enqueue(current.?.left) catch std.log.err("Cannot enque", .{});
                queue.enqueue(current.?.right) catch std.log.err("Cannot enque", .{});
            }

            return false;
        }
    };
}

test "insert" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var treeOfInts = try Tree(i16).init(arena.allocator());

    var node = treeOfInts.insertAt(treeOfInts.root, 4);
    try expect(treeOfInts.root.?.value == 4);
    try expect(node.?.value == 4);

    node = treeOfInts.insertAt(node, 5);
    try expect(treeOfInts.root.?.value == 4);
    try expect(node.?.value == 5);

    node = treeOfInts.insertAt(node, 2);
    try expect(treeOfInts.root.?.value == 4);
    try expect(node.?.value == 2);
}

test "dfs" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var treeOfInts = try Tree(i16).init(arena.allocator());

    var root = treeOfInts.insertAt(treeOfInts.root, 4);
    var node5 = treeOfInts.insertAt(root, 5);

    var node = treeOfInts.insertAt(root, 2);
    node = treeOfInts.insertAt(node, 6);
    node = treeOfInts.insertAt(node5, 1);
    try expectEqual(true, treeOfInts.dfs(6));
    try expectEqual(false, treeOfInts.dfs(16));
}

test "bfs" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var treeOfInts = try Tree(i16).init(arena.allocator());

    var root = treeOfInts.insertAt(treeOfInts.root, 4);
    var node5 = treeOfInts.insertAt(root, 5);

    var node = treeOfInts.insertAt(root, 2);
    node = treeOfInts.insertAt(node, 6);
    node = treeOfInts.insertAt(node5, 1);
    try expectEqual(true, treeOfInts.bfs(6));
    try expectEqual(false, treeOfInts.dfs(16));
}

test "compare null" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var tree1 = try Tree(i16).init(arena.allocator());
    var tree2 = try Tree(i16).init(arena.allocator());

    try expect(Tree(i16).compare(&tree1, &tree2) == true);
}

test "compare true" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var tree1 = try Tree(i16).init(arena.allocator());
    var root = tree1.insertAt(tree1.root, 4);
    var node5 = tree1.insertAt(root, 5);
    var node = tree1.insertAt(root, 2);
    node = tree1.insertAt(node, 6);
    node = tree1.insertAt(node5, 1);

    var tree2 = try Tree(i16).init(arena.allocator());
    root = tree2.insertAt(tree2.root, 4);
    node5 = tree2.insertAt(root, 5);
    node = tree2.insertAt(root, 2);
    node = tree2.insertAt(node, 6);
    node = tree2.insertAt(node5, 1);

    try expect(Tree(i16).compare(&tree1, &tree2) == true);
}

test "compare false" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var tree1 = try Tree(i16).init(arena.allocator());
    var root = tree1.insertAt(tree1.root, 4);
    var node5 = tree1.insertAt(root, 5);
    var node = tree1.insertAt(root, 2);
    node = tree1.insertAt(node, 6);
    node = tree1.insertAt(node5, 1);

    var tree2 = try Tree(i16).init(arena.allocator());
    root = tree2.insertAt(tree2.root, 4);
    node5 = tree2.insertAt(root, 5);
    node = tree2.insertAt(root, 2);
    node = tree2.insertAt(node, 1);
    node = tree2.insertAt(node5, 6);

    try expect(Tree(i16).compare(&tree1, &tree2) == false);
}

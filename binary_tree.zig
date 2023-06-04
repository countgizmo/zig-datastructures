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

        fn insert(self: *Self, node: ?*Node, value: T) ?*Node {
            if (node == null) {
                return self.newNode(value);
            }

            if (value <= node.?.value) {
                node.?.left = self.insert(node.?.left, value);
            } else if (value > node.?.value) {
                node.?.right = self.insert(node.?.right, value);
            }

            return node;
        }

        pub fn add(self: *Self, value: T) void {
            self.root = self.insert(self.root, value);
        }

        pub fn findAt(self: *Self, node: ?*Node, needle: T) bool {
            if (node == null) return false;

            if (node.?.value == needle) return true;

            if (node.?.value < needle) {
                return self.findAt(node.?.right, needle);
            }

            return self.findAt(node.?.left, needle);
        }

        pub fn find(self: *Self, needle: T) bool {
            if (self.root == null) return false;

            return self.findAt(self.root, needle);
        }
    };
}

test "insert" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var treeOfInts = try Tree(i16).init(arena.allocator());

    treeOfInts.add(4);
    try expect(treeOfInts.root.?.value == 4);

    treeOfInts.add(5);
    try expect(treeOfInts.root.?.right.?.value == 5);

    treeOfInts.add(2);
    try expect(treeOfInts.root.?.left.?.value == 2);

    treeOfInts.add(6);
    try expect(treeOfInts.root.?.right.?.right.?.value == 6);
}

test "find" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var treeOfInts = try Tree(i16).init(arena.allocator());

    treeOfInts.add(4);
    treeOfInts.add(5);
    treeOfInts.add(2);
    treeOfInts.add(6);
    try expectEqual(true, treeOfInts.find(2));
}

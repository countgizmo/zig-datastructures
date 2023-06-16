const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const Queue = @import("queue.zig").Queue;
const log = std.log;

pub fn Trie(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            children: ?AutoHashMap(T, *Node),
            end_of_word: bool = false,
        };
        allocator: Allocator,
        root: *Node,

        fn newNode(self: Self) ?*Node {
            const node = self.allocator.create(Node) catch null;
            if (node) |n| {
                const new_map = AutoHashMap(T, *Node).init(self.allocator);
                n.children = new_map;
                return n;
            }

            return null;
        }

        pub fn init(allocator: Allocator) !Self {
            const map = AutoHashMap(T, *Node).init(allocator);
            const root = try allocator.create(Node);
            root.* = .{ .children = map };

            return .{
                .allocator = allocator,
                .root = root,
            };
        }

        pub fn insert(self: Self, value: []const u8) !void {
            var cur: ?*Node = self.root;

            for (value) |ch| {
                if (cur == null) {
                    continue;
                }
                if (cur.?.children == null) {
                    continue;
                }

                if (!cur.?.children.?.contains(ch)) {
                    if (self.newNode()) |new_node| {
                        try cur.?.children.?.put(ch, new_node);
                    }
                }
                cur = cur.?.children.?.get(ch);
            }

            cur.?.end_of_word = true;
        }

        pub fn search(self: Self, value: []const u8) bool {
            var cur: ?*Node = self.root;

            for (value) |ch| {
                if (cur == null) {
                    continue;
                }
                if (cur.?.children == null) {
                    continue;
                }

                if (!cur.?.children.?.contains(ch)) {
                    return false;
                } else {
                    cur = cur.?.children.?.get(ch);
                }
            }

            return cur.?.end_of_word;
        }

        pub fn startsWith(self: Self, value: []const u8) bool {
            var cur: ?*Node = self.root;

            for (value) |ch| {
                if (cur == null) {
                    continue;
                }
                if (cur.?.children == null) {
                    continue;
                }

                if (!cur.?.children.?.contains(ch)) {
                    return false;
                } else {
                    cur = cur.?.children.?.get(ch);
                }
            }

            return true;
        }
    };
}

test "insert, search and startsWith" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var trie = try Trie(u8).init(arena.allocator());

    try trie.insert("apple");
    var good_result = trie.search("apple");
    try expect(good_result == true);

    const bad_result = trie.search("app");
    const starts_with = trie.startsWith("app");
    try expect(bad_result == false);
    try expect(starts_with == true);

    try trie.insert("ape");
    good_result = trie.search("ape");
    try expect(good_result == true);
}

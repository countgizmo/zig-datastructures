const std = @import("std");
const log = std.log;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;

pub fn LRU(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            value: V,
            next: ?*Node = null,
            prev: ?*Node = null,
        };

        allocator: Allocator,
        len: usize,
        head: ?*Node,
        tail: ?*Node,
        lookup: AutoHashMap(K, *Node),
        reverseLookup: AutoHashMap(*Node, K),
        capacity: usize,

        fn newNode(self: Self, value: V) ?*Node {
            const node = self.allocator.create(Node) catch null;
            if (node) |n| {
                n.next = null;
                n.prev = null;
                n.value = value;
                return n;
            }

            return null;
        }

        pub fn init(allocator: Allocator, capacity: usize) Self {
            return .{
                .capacity = capacity,
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = allocator,
                .lookup = AutoHashMap(K, *Node).init(allocator),
                .reverseLookup = AutoHashMap(*Node, K).init(allocator),
            };
        }

        fn trimCache(self: *Self) void {
            if (self.len <= self.capacity) {
                return;
            }

            const tail = self.tail;
            self.detach(self.tail);

            const key = self.reverseLookup.get(tail.?);
            _ = self.lookup.remove(key.?);
            _ = self.reverseLookup.remove(tail.?);
            self.len -= 1;
        }

        pub fn update(self: *Self, key: K, value: V) !void {
            var node = self.lookup.get(key);

            if (node == null) {
                node = self.newNode(value);
                self.len += 1;
                self.prepend(node);
                self.trimCache();
                if (node != null) {
                    try self.lookup.put(key, node.?);
                    try self.reverseLookup.put(node.?, key);
                }
            } else {
                self.detach(node);
                self.prepend(node);
                node.?.value = value;
            }
        }

        fn detach(self: *Self, node: ?*Node) void {
            if (node == null) {
                return;
            }

            if (node.?.prev) |prev| {
                prev.next = node.?.next;
            }

            if (node.?.next) |next| {
                next.prev = node.?.prev;
            }

            // If we are detaching head
            // we need to have a new head.
            if (self.head == node) {
                self.head = self.head.?.next;
            }

            // If we are detaching tail
            // we need to have a new tabil.
            if (self.tail == node) {
                self.tail = self.tail.?.prev;
            }

            node.?.next = null;
            node.?.prev = null;
        }

        fn prepend(self: *Self, node: ?*Node) void {
            if (self.head == null) {
                self.head = node;
                self.tail = node;
            } else if (node != null) {
                node.?.next = self.head;
                self.head.?.prev = node;
                self.head = node;
            }
        }

        pub fn get(self: *Self, key: K) ?V {
            if (self.lookup.get(key)) |node| {
                self.detach(node);
                self.prepend(node);
                return node.value;
            }

            return null;
        }
    };
}

test "init" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();

    var lru = LRU([10]u8, i16).init(arena.allocator(), 10);
    try expect(lru.len == 0);
}

test "lru" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();

    var lru = LRU(u8, i16).init(arena.allocator(), 3);

    try expect(lru.get(1) == null);
    try lru.update(1, 11111);
    try expect(lru.get(1).? == 11111);

    try lru.update(2, 22222);
    try expect(lru.get(2).? == 22222);

    try lru.update(3, 333);
    try expect(lru.get(3).? == 333);
    try expect(lru.len == 3);

    try lru.update(4, 444);
    try expect(lru.get(2).? == 22222);
    try expect(lru.get(3).? == 333);
    try expect(lru.get(1) == null);
}

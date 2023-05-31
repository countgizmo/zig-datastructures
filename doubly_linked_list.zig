const std = @import("std");
const expect = std.testing.expect;
const mem = std.mem;
const Allocator = mem.Allocator;

const LinkeListError = error{
    OutOfBounds,
};

fn DoublyLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            prev: ?*Node = null,
            next: ?*Node = null,
            key: T,
        };

        len: usize,
        head: ?*Node,
        tail: ?*Node,
        allocator: Allocator,

        fn getAt(self: Self, index: usize) ?*Node {
            var i: usize = 0;
            var current = self.head;
            while (i < index) : (i += 1) {
                if (current) |curr| {
                    current = curr.next;
                }
            }

            return current;
        }

        pub fn init(allocator: Allocator) Self {
            return Self{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = allocator,
            };
        }

        pub fn prepend(self: *Self, key: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{ .key = key, .prev = null };

            if (self.head) |head| {
                head.prev = node;
                node.next = head;
            } else {
                self.tail = node;
            }

            self.head = node;
            self.len += 1;
        }

        pub fn append(self: *Self, key: T) !void {
            const node = try self.allocator.create(Node);
            node.key = key;
            node.next = null;

            if (self.tail) |tail| {
                node.prev = tail;
                tail.next = node;
            } else {
                self.head = node;
            }

            self.tail = node;
            self.len += 1;
        }

        pub fn insertAt(self: *Self, key: T, index: usize) !void {
            if (index > self.len) {
                return error.OutOfBounds;
            }

            if (index == 0) {
                return self.prepend(key);
            }

            if (index == self.len) {
                return self.append(key);
            }

            const node = try self.allocator.create(Node);
            node.key = key;

            var current = self.getAt(index);
            node.next = current;
            node.prev = current.?.prev;
            current.?.prev.?.next = node;
            current.?.prev = node;

            self.len += 1;
        }

        pub fn removeAt(self: *Self, index: usize) !T {
            if (index >= self.len) {
                return error.OutOfBounds;
            }

            var current = self.getAt(index);

            self.len -= 1;

            if (self.len == 0) {
                const old_head = self.head;
                self.allocator.destroy(self.tail.?);
                self.allocator.destroy(self.head.?);
                self.tail = null;
                self.head = null;

                return old_head.?.key;
            }

            if (current == self.tail) {
                const old_tail = self.tail;
                self.tail = current.?.prev;
                self.tail.?.next = null;
                self.allocator.destroy(old_tail.?);

                return old_tail.?.key;
            }

            if (current == self.head) {
                const old_head = self.head;
                self.head = self.head.?.next;
                self.head.?.prev = null;
                self.allocator.destroy(old_head.?);

                return old_head.?.key;
            }

            if (current.?.prev != null) {
                current.?.prev.?.next = current.?.next;
            }

            if (current.?.next != null) {
                current.?.next.?.prev = current.?.prev;
            }

            self.allocator.destroy(current.?);
            return current.?.key;
        }

        pub fn remove(self: *Self, key: T) ?T {
            var i: usize = 0;
            var current = self.head;

            while (i < self.len) : (i += 1) {
                if (current) |curr| {
                    if (curr.key == key) {
                        break;
                    }
                    current = curr.next;
                }
            }

            if (current == null) {
                return null;
            }

            self.len -= 1;

            if (self.len == 0) {
                const old_head = self.head;
                self.allocator.destroy(self.tail.?);
                self.allocator.destroy(self.head.?);
                self.tail = null;
                self.head = null;

                return old_head.?.key;
            }

            if (current == self.tail) {
                const old_tail = self.tail;
                self.tail = current.?.prev;
                self.tail.?.next = null;
                self.allocator.destroy(old_tail.?);

                return old_tail.?.key;
            }

            if (current == self.head) {
                const old_head = self.head;
                self.head = self.head.?.next;
                self.head.?.prev = null;
                self.allocator.destroy(old_head.?);

                return old_head.?.key;
            }

            if (current.?.prev != null) {
                current.?.prev.?.next = current.?.next;
            }

            if (current.?.next != null) {
                current.?.next.?.prev = current.?.prev;
            }

            self.allocator.destroy(current.?);
            return current.?.key;
        }

        pub fn get(self: Self, index: usize) !T {
            if (index >= self.len) {
                return error.OutOfBounds;
            }

            const current = self.getAt(index);

            return current.?.key;
        }

        pub fn print(self: *Self) void {
            var current = self.head;
            while (current) |cur| {
                std.log.warn("item = {c}", .{cur.key});
                current = cur.next;
            }
        }
    };
}

test "init doubly linked list" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try expect(listOfChars.len == 0);
    try expect(listOfChars.head == null);
    try expect(listOfChars.tail == null);
}

test "prepend" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.prepend('a');
    try listOfChars.prepend('b');

    try expect(listOfChars.len == 2);
    try expect(listOfChars.head.?.key == 'b');
    try expect(listOfChars.tail.?.key == 'a');
}

test "append" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.prepend('a');
    try listOfChars.prepend('b');

    try listOfChars.append('c');

    try expect(listOfChars.len == 3);
    try expect(listOfChars.head.?.key == 'b');
    try expect(listOfChars.tail.?.key == 'c');
    try expect(listOfChars.tail.?.prev.?.key == 'a');
}

test "insertAt" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.append('a');
    try listOfChars.append('b');
    try listOfChars.append('c');
    try listOfChars.insertAt('x', 2);

    try expect(listOfChars.len == 4);
    try expect(listOfChars.head.?.key == 'a');
    const item_x = try listOfChars.get(2);

    try expect(item_x == 'x');
    try expect(listOfChars.tail.?.key == 'c');

    try listOfChars.insertAt('O', 0);
    try expect(listOfChars.len == 5);
    try expect(listOfChars.head.?.key == 'O');

    try listOfChars.insertAt('z', 5);
    try expect(listOfChars.len == 6);
    try expect(listOfChars.tail.?.key == 'z');
}

test "removeAt" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.append('a');
    try listOfChars.append('b');
    try listOfChars.append('c');
    try listOfChars.append('d');
    const removed = try listOfChars.removeAt(1);
    const item2 = try listOfChars.get(1);

    try expect(listOfChars.len == 3);
    try expect(listOfChars.head.?.key == 'a');
    try expect(listOfChars.tail.?.key == 'd');
    try expect(removed == 'b');
    try expect(item2 == 'c');

    const removed_last = try listOfChars.removeAt(2);
    try expect(listOfChars.len == 2);
    try expect(listOfChars.head.?.key == 'a');
    try expect(listOfChars.tail.?.key == 'c');
    try expect(removed_last == 'd');

    const removed_first = try listOfChars.removeAt(0);
    try expect(listOfChars.len == 1);
    try expect(listOfChars.head.?.key == 'c');
    try expect(listOfChars.tail.?.key == 'c');
    try expect(removed_first == 'a');
}

test "remove" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.append('a');
    try listOfChars.append('b');
    try listOfChars.append('c');
    try listOfChars.append('d');
    const removed = listOfChars.remove('c');

    try expect(listOfChars.len == 3);
    try expect(listOfChars.head.?.key == 'a');
    try expect(listOfChars.tail.?.key == 'd');
    try expect(removed.? == 'c');

    const removed_last = listOfChars.remove('d');
    try expect(listOfChars.len == 2);
    try expect(listOfChars.head.?.key == 'a');
    try expect(listOfChars.tail.?.key == 'b');
    try expect(removed_last.? == 'd');

    const removed_first = listOfChars.remove('a');
    try expect(listOfChars.len == 1);
    try expect(listOfChars.head.?.key == 'b');
    try expect(listOfChars.tail.?.key == 'b');
    try expect(removed_first.? == 'a');
}

test "get" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var listOfChars = DoublyLinkedList(u8).init(arena.allocator());

    try listOfChars.prepend('a');
    try listOfChars.prepend('b');

    try expect(listOfChars.len == 2);
    const item1 = try listOfChars.get(0);
    const item2 = try listOfChars.get(1);
    try expect(item1 == 'b');
    try expect(item2 == 'a');

    const item3 = listOfChars.get(2);
    try expect(item3 == error.OutOfBounds);
}

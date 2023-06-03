const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;
const Allocator = std.mem.Allocator;

pub fn Queue(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            key: T,
            next: ?*Node = null,
        };

        allocator: Allocator,
        head: ?*Node,
        tail: ?*Node,
        len: usize,

        pub fn init(allocator: Allocator) This {
            return This{
                .allocator = allocator,
                .head = null,
                .tail = null,
                .len = 0,
            };
        }

        pub fn enqueue(this: *This, value: T) !void {
            const node = try this.allocator.create(Node);
            node.* = .{ .key = value, .next = null };

            if (this.tail) |tail| {
                tail.next = node;
            } else {
                this.head = node;
            }

            this.tail = node;
            this.len += 1;
        }

        pub fn deque(this: *This) ?T {
            var current: ?T = null;
            if (this.head) |head| {
                defer this.allocator.destroy(head);
                this.head = head.next;
                current = head.key;
            }

            if (this.len == 1) {
                this.head = this.tail;
            }

            if (this.len == 0 and this.tail != null) {
                defer this.allocator.destroy(this.tail.?);
                this.tail = null;
                this.head = null;
                return null;
            }

            this.len -= 1;
            return current;
        }

        pub fn peek(this: *This) ?T {
            if (this.head) |head| {
                return head.key;
            }
            return null;
        }
    };
}

test "init" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    var queue = Queue(i32).init(arena.allocator());
    try expect(null == queue.head);
    try expect(null == queue.tail);
}

test "enqueue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init(arena.allocator());

    try queue.enqueue(1);

    try expect(1 == queue.head.?.key);
    try expect(1 == queue.tail.?.key);

    try queue.enqueue(2);

    try expect(queue.head.?.key == 1);
    try expect(queue.tail.?.key == 2);
}

test "peek" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init(arena.allocator());
    try queue.enqueue(1);

    var value = queue.peek();
    try expect(1 == value);
    try expect(queue.head.?.key == value); //The head didn't move
}

test "deque" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init(arena.allocator());

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);

    try expect(queue.head.?.key == 1);
    try expect(queue.tail.?.key == 3);

    var value = queue.deque();

    try expect(queue.head.?.key == 2);
    try expect(queue.tail.?.key == 3);
    try expect(value.? == 1);

    value = queue.deque();

    try expect(queue.tail.?.key == 3);
    try expect(value.? == 2);
}

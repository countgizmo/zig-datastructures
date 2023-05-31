const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;

fn Queue(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            key: T,
            next: ?*Node = null,
        };

        head: ?*Node,
        tail: ?*Node,
        len: usize,

        pub fn init() This {
            return This{
                .head = null,
                .tail = null,
                .len = 0,
            };
        }

        pub fn enqueue(this: *This, value: T) !void {
            const node = try std.heap.page_allocator.create(Node);
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
            if (this.head) |head| {
                defer std.heap.page_allocator.destroy(head);
                this.head = head.next;
                this.len -= 1;
                return head.key;
            }

            if (this.len == 0 and this.tail != null) {
                defer std.heap.page_allocator.destroy(this.tail.?);
                this.tail = null;
                this.head = null;
            }

            return null;
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
    var queue = Queue(i32).init();
    try expect(null == queue.head);
    try expect(null == queue.tail);
}

test "enqueue" {
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init();

    try queue.enqueue(1);

    try expect(1 == queue.head.?.key);
    try expect(1 == queue.tail.?.key);

    try queue.enqueue(2);

    try expect(queue.head.?.key == 1);
    try expect(queue.tail.?.key == 2);
}

test "peek" {
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init();
    try queue.enqueue(1);

    var value = queue.peek();
    try expect(1 == value);
    try expect(queue.head.?.key == value); //The head didn't move
}

test "deque" {
    const QueueOfNumbers = Queue(i32);
    var queue = QueueOfNumbers.init();

    try queue.enqueue(1);
    try queue.enqueue(2);
    try queue.enqueue(3);

    try expect(queue.head.?.key == 1);
    try expect(queue.tail.?.key == 3);

    const value = queue.deque();

    try expect(queue.head.?.key == 2);
    try expect(queue.tail.?.key == 3);
    try expect(value.? == 1);
}

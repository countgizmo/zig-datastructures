const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;
const allocator = std.heap.page_allocator;

fn Stack(comptime T: type) type {
    return struct {
        const This = @This();
        const Node = struct {
            key: T,
            prev: ?*Node = null,
        };

        head: ?*Node,
        len: usize,

        pub fn init() This {
            return This{
                .head = null,
                .len = 0,
            };
        }

        pub fn push(this: *This, value: T) !void {
            const node = try allocator.create(Node);
            node.* = .{ .key = value };

            if (this.head) |head| {
                node.prev = head;
            }

            this.head = node;
            this.len += 1;
        }

        pub fn pop(this: *This) ?T {
            if (this.head) |head| {
                defer allocator.destroy(head);
                this.head = head.prev;
                this.len -= 1;
                return head.key;
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

test "push" {
    var stack = Stack(i32).init();
    try expect(stack.head == null);

    try stack.push(1);

    try expect(stack.head.?.key == 1);

    try stack.push(2);

    try expect(stack.head.?.key == 2);
}

test "pop" {
    var stack = Stack(i32).init();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    try expect(stack.head.?.key == 3);
    try expect(stack.len == 3);

    const value = stack.pop();

    try expect(stack.len == 2);
    try expect(value.? == 3);
    try expect(stack.head.?.key == 2);

    _ = stack.pop();
    const last_value = stack.pop();

    try expect(stack.len == 0);
    try expect(last_value.? == 1);
    try expect(stack.head == null);

    const no_value = stack.pop();
    try expect(no_value == null);
    try expect(stack.len == 0);
    try expect(stack.head == null);
}

test "peek" {
    var stack = Stack(i32).init();
    try stack.push(1);
    try stack.push(2);

    try expect(stack.head.?.key == 2);
    try expect(stack.len == 2);

    const value = stack.peek();

    try expect(stack.len == 2);
    try expect(value.? == 2);
    try expect(stack.head.?.key == 2);
}

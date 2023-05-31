const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;

const Node = struct {
    key: i32,
    next: ?*Node = null,
};

const LinkedList = struct {
    head: *Node,
    tail: *Node,
    len: usize = 1,

    pub fn insertAt(self: *LinkedList, item: *Node, index: usize) void {
        var i: usize = 0;
        var cur = self.head;

        while (cur.next != null and i < index) {
            cur = cur.next.?;
            i += 1;
        }

        if (i == index) {
            item.next = cur.next;
            cur.next = item;
            self.len += 1;

            if (item.next == null) {
                self.tail = item;
            }
        }
    }

    pub fn findByKey(self: *LinkedList, key: i32) ?*Node {
        var cur = self.head;

        while (cur.next != null) {
            if (cur.key == key) {
                return cur;
            }
            cur = cur.next.?;
        }

        return null;
    }
};

test "init" {
    var head_node = Node{
        .key = 42,
    };

    var list = LinkedList{
        .head = &head_node,
        .tail = &head_node,
    };

    try expect(1 == list.len);
    try expect(42 == list.head.key);
    try expect(42 == list.tail.key);
}

test "insert" {
    var head_node = Node{
        .key = 42,
    };

    var list = LinkedList{
        .head = &head_node,
        .tail = &head_node,
    };

    var item = Node{
        .key = 33,
    };

    list.insertAt(&item, 0);

    try expect(2 == list.len);
    try expect(list.tail.key == item.key);
}

test "findByKey" {
    var head_node = Node{
        .key = 42,
    };

    var list = LinkedList{
        .head = &head_node,
        .tail = &head_node,
    };

    var item1 = Node{
        .key = 33,
    };

    var item2 = Node{
        .key = 575,
    };

    list.insertAt(&item1, 0);
    list.insertAt(&item2, 1);

    var item = list.findByKey(33);
    try expect(3 == list.len);
    try expect(33 == item.?.key);
}

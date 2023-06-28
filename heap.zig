const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// This is a min heap
pub fn Heap(comptime T: type) type {
    return struct {
        const Self = @This();

        len: usize = 0,
        data: std.ArrayList(T),

        pub fn init(allocator: Allocator) Self {
            return .{
                .data = std.ArrayList(T).init(allocator),
            };
        }

        fn parent(idx: usize) usize {
            return (idx - 1) / 2;
        }

        fn leftChild(idx: usize) usize {
            return (2 * idx) + 1;
        }

        fn rightChild(idx: usize) usize {
            return (2 * idx) + 2;
        }

        fn heapifyUp(self: Self, idx: usize) void {
            if (idx == 0) {
                return;
            }

            const p_idx = parent(idx);
            const p_value = self.data.items[p_idx];
            const value = self.data.items[idx];

            if (p_value > value) {
                self.data.items[p_idx] = value;
                self.data.items[idx] = p_value;
                self.heapifyUp(p_idx);
            }
        }

        fn heapifyDown(self: Self, idx: usize) void {
            const l_idx = leftChild(idx);
            const r_idx = rightChild(idx);

            if (idx >= self.len or l_idx >= self.len) {
                return;
            }

            const value = self.data.items[idx];
            const l_value = self.data.items[l_idx];
            const r_value = self.data.items[r_idx];

            if (l_value > r_value and value > r_value) {
                self.data.items[r_idx] = value;
                self.data.items[idx] = r_value;
                self.heapifyDown(r_idx);
            } else if (r_value > l_value and value > l_value) {
                self.data.items[l_idx] = value;
                self.data.items[idx] = l_value;
                self.heapifyDown(l_idx);
            }
        }

        pub fn insert(self: *Self, value: T) !void {
            try self.data.append(value);
            self.heapifyUp(self.len);
            self.len += 1;
        }

        pub fn delete(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const out = self.data.items[0];

            self.len -= 1;
            if (self.len == 0) {
                self.data.clearAndFree();
                return out;
            }

            self.data.items[0] = self.data.items[self.len];
            self.heapifyDown(0);
            return out;
        }
    };
}

test "init" {
    var allocator = std.testing.allocator;
    const heap = Heap(i16).init(allocator);
    try expect(heap.data.items.len == 0);
}

test "insert" {
    var allocator = std.testing.allocator;
    var heap = Heap(i16).init(allocator);
    defer heap.data.deinit();
    try heap.insert(27);
    try heap.insert(5);
    try heap.insert(10);
    try expect(heap.len == 3);
}

test "delete" {
    var allocator = std.testing.allocator;
    var heap = Heap(i16).init(allocator);
    defer heap.data.deinit();

    try heap.insert(27);
    try heap.insert(5);
    try heap.insert(10);

    var value = heap.delete();
    try expect(value.? == 5);
    try expect(heap.len == 2);

    value = heap.delete();
    try expect(value.? == 10);
    try expect(heap.len == 1);

    value = heap.delete();
    try expect(value.? == 27);
    try expect(heap.len == 0);
}

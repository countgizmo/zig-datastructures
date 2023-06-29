const std = @import("std");
const ArrayList = std.ArrayList;
const log = std.log;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

pub fn MaxPriorityQueue(comptime T: type) type {
    return struct {
        const Self = @This();

        const Error = error{
            NewKeyIsSmaller,
        };

        len: usize = 0,
        data: ArrayList(T),

        fn left(idx: usize) usize {
            return (idx * 2) + 1;
        }

        fn right(idx: usize) usize {
            return (idx * 2) + 2;
        }

        fn parent(idx: usize) usize {
            return (idx - 1) / 2;
        }

        fn maxHeapify(self: *Self, idx: usize) void {
            var largest = idx;

            const l = left(idx);
            const r = right(idx);

            if (l < self.len and self.data.items[l] > self.data.items[largest]) {
                largest = l;
            }

            if (r < self.len and self.data.items[r] > self.data.items[largest]) {
                largest = r;
            }

            if (largest != idx) {
                const temp = self.data.items[idx];
                self.data.items[idx] = self.data.items[largest];
                self.data.items[largest] = temp;
                return self.maxHeapify(largest);
            }

            return;
        }

        pub fn init(allocator: Allocator) Self {
            return .{
                .data = ArrayList(T).init(allocator),
            };
        }

        pub fn deinit(self: Self) void {
            self.data.deinit();
        }

        pub fn maximum(self: Self) ?T {
            if (self.len == 0) {
                return null;
            }

            return self.data.items[0];
        }

        pub fn extractMax(self: *Self) ?T {
            if (self.len == 0) {
                return null;
            }

            const max = self.data.items[0];
            self.data.items[0] = self.data.items[self.len - 1];
            self.maxHeapify(0);
            self.len -= 1;

            return max;
        }

        pub fn increaseKey(self: *Self, idx: usize, newKey: T) !void {
            if (newKey < self.data.items[idx]) {
                return error.NewKeyIsSmaller;
            }

            self.data.items[idx] = newKey;

            var i = idx;
            while (i > 0 and self.data.items[parent(i)] < self.data.items[i]) {
                const temp = self.data.items[i];
                self.data.items[i] = self.data.items[parent(i)];
                self.data.items[parent(i)] = temp;
                i = parent(i);
            }
        }

        pub fn insert(self: *Self, newKey: T) !void {
            self.len += 1;
            try self.data.append(-@bitCast(T, std.math.inf(f16)));
            try self.increaseKey(self.len - 1, newKey);
        }
    };
}

test "insert" {
    const allocator = std.testing.allocator;
    var maxPriorityQueue = MaxPriorityQueue(i16).init(allocator);
    defer maxPriorityQueue.deinit();

    try maxPriorityQueue.insert(2);
    try maxPriorityQueue.insert(4);
    try maxPriorityQueue.insert(1);
    try maxPriorityQueue.insert(8);
    try maxPriorityQueue.insert(7);
    try maxPriorityQueue.insert(9);
    try maxPriorityQueue.insert(3);
    try maxPriorityQueue.insert(14);
    try maxPriorityQueue.insert(10);
    try maxPriorityQueue.insert(16);

    const expected = [_]i16{ 16, 14, 10, 9, 8, 7, 4, 3, 2, 1 };
    var i: usize = 0;
    while (maxPriorityQueue.len > 0) : (i += 1) {
        if (maxPriorityQueue.extractMax()) |max| {
            try expect(expected[i] == max);
        }
    }
}

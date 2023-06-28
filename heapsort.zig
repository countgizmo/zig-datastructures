const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const log = std.log;

pub fn MaxHeap(comptime T: type) type {
    return struct {
        const Self = @This();

        len: usize = 0,
        data: ArrayList(T),

        pub fn init(allocator: Allocator) Self {
            return .{
                .data = ArrayList(T).init(allocator),
            };
        }

        fn left(idx: usize) usize {
            return (idx * 2) + 1;
        }

        fn right(idx: usize) usize {
            return (idx * 2) + 2;
        }

        fn parent(idx: usize) usize {
            return (idx - 1) / 2;
        }

        fn maxHeapify(self: Self, idx: usize) void {
            var largest = idx;

            const l_idx = left(idx);
            const r_idx = right(idx);

            if (l_idx < self.len and self.data.items[l_idx] > self.data.items[largest]) {
                largest = l_idx;
            }

            if (r_idx < self.len and self.data.items[r_idx] > self.data.items[largest]) {
                largest = r_idx;
            }

            if (largest != idx) {
                const temp = self.data.items[idx];
                self.data.items[idx] = self.data.items[largest];
                self.data.items[largest] = temp;

                return self.maxHeapify(largest);
            }

            return;
        }

        fn buildMaxHeap(self: *Self, rawData: []T) !void {
            try self.data.appendSlice(rawData);
            self.len = rawData.len;

            var i = (self.len / 2) - 1;
            // The first leaf starts at n/2.
            // Starting with the first non-leaf call maxHeapify on every node including root.
            while (i > 0) : (i -= 1) {
                self.maxHeapify(i);
            }

            // Last maxHeapify for i = 0 (the root)
            // Cause of usize restricitons to not be negative.
            // Otherwise we could've looped till i < 0;
            self.maxHeapify(i);
        }

        pub fn sort(self: *Self, rawData: []T) ![]T {
            try self.buildMaxHeap(rawData);

            while (self.len > 1) {
                const temp = self.data.items[0];
                self.data.items[0] = self.data.items[self.len - 1];
                self.data.items[self.len - 1] = temp;
                self.len -= 1;
                self.maxHeapify(0);
            }

            return self.data.items;
        }
    };
}

test "maxHeapify" {
    var allocator = std.testing.allocator;
    var heap = MaxHeap(i16).init(allocator);
    defer heap.data.deinit();

    // Cheating. In the name of tests!
    heap.len = 10;
    try heap.data.append(16);
    try heap.data.append(4); // this one is not in its place
    try heap.data.append(10);
    try heap.data.append(14);
    try heap.data.append(7);
    try heap.data.append(9);
    try heap.data.append(3);
    try heap.data.append(2);
    try heap.data.append(8);
    try heap.data.append(1);

    heap.maxHeapify(1);
    try expect(heap.data.items[0] == 16);
    try expect(heap.data.items[1] == 14);
    try expect(heap.data.items[2] == 10);
    try expect(heap.data.items[3] == 8);
    try expect(heap.data.items[4] == 7);
    try expect(heap.data.items[5] == 9);
    try expect(heap.data.items[6] == 3);
    try expect(heap.data.items[7] == 2);
    try expect(heap.data.items[8] == 4);
    try expect(heap.data.items[9] == 1);
}

test "buildMaxHeap" {
    var allocator = std.testing.allocator;
    var heap = MaxHeap(i16).init(allocator);
    defer heap.data.deinit();

    var data = [_]i16{ 4, 1, 3, 2, 16, 9, 10, 14, 8, 7 };
    try heap.buildMaxHeap(&data);

    try expect(heap.data.items[0] == 16);
    try expect(heap.data.items[1] == 14);
    try expect(heap.data.items[2] == 10);
    try expect(heap.data.items[3] == 8);
    try expect(heap.data.items[4] == 7);
    try expect(heap.data.items[5] == 9);
    try expect(heap.data.items[6] == 3);
    try expect(heap.data.items[7] == 2);
    try expect(heap.data.items[8] == 4);
    try expect(heap.data.items[9] == 1);
}

test "sort" {
    var allocator = std.testing.allocator;
    var heap = MaxHeap(i16).init(allocator);
    defer heap.data.deinit();

    var data = [_]i16{ 4, 1, 3, 2, 16, 9, 10, 14, 8, 7 };

    const sorted = try heap.sort(&data);

    try expect(sorted[0] == 1);
    try expect(sorted[1] == 2);
    try expect(sorted[2] == 3);
    try expect(sorted[3] == 4);
    try expect(sorted[4] == 7);
    try expect(sorted[5] == 8);
    try expect(sorted[6] == 9);
    try expect(sorted[7] == 10);
    try expect(sorted[8] == 14);
    try expect(sorted[9] == 16);
}

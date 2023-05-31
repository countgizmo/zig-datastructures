const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const info = std.debug.print;

fn partition(arr: []i32, lo: usize, hi: usize) usize {
    const pivot = arr[hi];

    var idx: i32 = @intCast(i32, lo) - 1;
    var i = lo;
    while (i < hi) : (i += 1) {
        if (arr[i] <= pivot) {
            idx += 1;
            const arr_idx = @intCast(usize, idx);
            const temp = arr[i];
            arr[i] = arr[arr_idx];
            arr[arr_idx] = temp;
        }
    }

    idx += 1;
    const arr_idx = @intCast(usize, idx);

    arr[hi] = arr[arr_idx];
    arr[arr_idx] = pivot;

    return arr_idx;
}

fn qs(arr: []i32, lo: usize, hi: usize) void {
    if (lo >= hi) {
        return;
    }

    const pivot_idx = partition(arr, lo, hi);

    if (pivot_idx > 0) qs(arr, lo, pivot_idx - 1);
    qs(arr, pivot_idx + 1, hi);
}

pub fn sort(arr: []i32) void {
    qs(arr, 0, arr.len - 1);
}

test "sort array" {
    var my_array = [_]i32{ 3, 1, 5, 6, 9, 4, 15, 11 };
    var expected = [_]i32{ 1, 3, 4, 5, 6, 9, 11, 15 };
    sort(&my_array);
    try expectEqual(expected, my_array);
}

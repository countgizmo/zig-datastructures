const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

fn partition(arr: []i32, p: usize, r: usize) usize {
    var pivot = arr[r];
    var i: i32 = @intCast(i32, p) - 1;
    var j = p;

    while (j < r) : (j += 1) {
        if (arr[j] <= pivot) {
            i += 1;
            const idx = @intCast(usize, i);
            const temp = arr[j];
            arr[j] = arr[idx];
            arr[idx] = temp;
        }
    }

    const idx = @intCast(usize, i + 1);
    arr[r] = arr[idx];
    arr[idx] = pivot;

    return idx;
}

fn quickSort(arr: []i32, p: usize, r: usize) void {
    if (p < r) {
        var q = partition(arr, p, r);
        if (q > 0) {
            quickSort(arr, p, q - 1);
        }
        quickSort(arr, q + 1, r);
    }
}

pub fn sort(arr: []i32) void {
    quickSort(arr, 0, arr.len - 1);
}

test "partition" {
    var my_array = [_]i32{ 3, 1, 5, 6, 9, 4, 15, 11 };
    var expected = [_]i32{ 3, 1, 5, 6, 9, 4, 11, 15 };
    const new_pivot = partition(&my_array, 0, my_array.len - 1);
    try expect(new_pivot == 6);
    try expectEqual(expected, my_array);

    my_array = [_]i32{ 2, 8, 7, 1, 3, 5, 6, 4 };
    expected = [_]i32{ 2, 1, 3, 4, 7, 5, 6, 8 };
    const new_pivot2 = partition(&my_array, 0, my_array.len - 1);
    try expect(new_pivot2 == 3);
    try expectEqual(expected, my_array);
}

test "sort array" {
    var my_array = [_]i32{ 3, 1, 5, 6, 9, 4, 15, 11 };
    var expected = [_]i32{ 1, 3, 4, 5, 6, 9, 11, 15 };
    sort(&my_array);
    try expectEqual(expected, my_array);
}

test "sort 2" {
    var my_array = [_]i32{ 2, 8, 7, 1, 3, 5, 6, 4 };
    var expected = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    sort(&my_array);
    try expectEqual(expected, my_array);
}

test "nothing to sort" {
    var my_array = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    var expected = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 };
    sort(&my_array);
    try expectEqual(expected, my_array);
}

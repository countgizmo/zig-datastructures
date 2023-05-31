const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;

fn sort(arr: []i32) void {
    var i: usize = 0;

    while (i < arr.len) {
        var j: usize = 0;
        while (j < arr.len - 1 - i) {
            if (arr[j] > arr[j + 1]) {
                var temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
            j += 1;
        }
        i += 1;
    }
}

test "sort an array" {
    var my_array = [_]i32{ 3, 1, 5, 6, 9, 4, 15, 11 };
    var expected = [_]i32{ 1, 3, 4, 5, 6, 9, 11, 15 };
    sort(&my_array);
    try expectEqual(expected, my_array);
}

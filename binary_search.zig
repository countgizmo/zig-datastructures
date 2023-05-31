const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const print = std.debug.print;

const Error = error{
    NotFound,
};

fn search(data: []const u8, value: u8) !usize {
    var lo: usize = 0;
    var hi = data.len;

    while (lo < hi) {
        const middle = lo + (hi - lo) / 2;

        if (value == data[middle]) {
            return middle;
        } else if (value > data[middle]) {
            lo = middle + 1;
        } else if (value < data[middle]) {
            hi = middle;
        }
    }

    return Error.NotFound;
}

test "find element in an array with odd size" {
    const data = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 };
    const index = try search(&data, 3);
    try expect(index == 2);
}

test "find element in an array with even size" {
    const data = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
    const index = try search(&data, 5);
    try expect(index == 4);
}

test "cannot find element too big" {
    const data = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 };
    const index = search(&data, 55) catch |err| err;
    try expect(index == Error.NotFound);
}

test "cannot find element too small" {
    const data = [_]u8{ 6, 7, 8, 9, 10, 11, 12 };
    const index = search(&data, 5) catch |err| err;
    try expect(index == Error.NotFound);
}

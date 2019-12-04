// zig run 4.zig

const std = @import("std");
const warn = std.debug.warn;

pub fn main() anyerror!void {
    var part1: i32 = 0;
    var part2: i32 = 0;
    var n: i32 = 245182;
    var digits: [20]i8 = undefined;
    while (n <= 790572) : (n += 1) {
        var i: usize = 0;
        var x = n;
        while (x > 0) : (x = @divTrunc(x, 10)) {
            digits[i] = @truncate(i8, @mod(x, 10));
            i += 1;
        }
        var diffs = digits[0..i];
        std.mem.reverse(i8, digits[0..i]);
        for (diffs[0 .. diffs.len - 1]) |diff, di| {
            diffs[di] = diffs[di + 1] - diff;
        }
        var is_inc = true;
        var is_consec1 = false;
        var is_consec2 = false;
        for (diffs) |diff, di| {
            if (diff < 0) {
                is_inc = false;
                if (is_consec1 and is_consec2) break;
            }
            if (diff == 0) {
                is_consec1 = true;
                if ((di == 0 or diffs[di - 1] != 0) and
                    (di == diffs.len - 1 or diffs[di + 1] != 0))
                {
                    is_consec2 = true;
                    if (!is_inc) break;
                }
            }
        }

        if (is_inc and is_consec1) part1 += 1;
        if (is_inc and is_consec2) part2 += 1;
    }
    warn("part1: {} part2: {}\n", part1, part2);
}

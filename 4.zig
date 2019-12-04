// zig run 4.zig

const std = @import("std");
const warn = std.debug.warn;

pub fn main() anyerror!void {
    var part1: i32 = 0;
    var part2: i32 = 0;
    var n: i32 = 245182;
    var buf: [20]u8 = undefined;
    // var buf: [20]i8 = undefined;
    while (n <= 790572) : (n += 1) {
        const s = try std.fmt.bufPrint(&buf, "{d}", n);
        var inc = true;
        var consec1 = false;
        var consec2 = false;
        for (s[0 .. s.len - 1]) |c, si| {
            if (c > s[si + 1]) {
                inc = false;
                break;
            }
        }

        for ("0123456789") |c| {
            const two_consec = std.mem.indexOf(u8, s, &[_]u8{ c, c }) != null;
            if (two_consec) consec1 = true;
            if (two_consec and std.mem.indexOf(u8, s, &[_]u8{ c, c, c }) == null) consec2 = true;
            if (consec1 and consec2) break;
        }
        if (inc and consec1) part1 += 1;
        if (inc and consec2) part2 += 1;
    }
    warn("part1: {} part2: {}\n", part1, part2);
}

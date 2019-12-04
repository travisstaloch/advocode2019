// cat ../../julia-play/challenges/advocode2019/1.in | zig run 1.zig

const std = @import("std");
const warn = std.debug.warn;

pub fn main() anyerror!void {
    const file = std.io.getStdIn();
    const stream = &file.inStream().stream;
    var buf: [20]u8 = undefined;
    var sum: usize = 0;
    var sum2: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var mass = try std.fmt.parseInt(usize, line, 10);
        sum += (mass / 3) - 2;
        while (mass > 6) {
            mass = (mass / 3) - 2;
            sum2 += mass;
        }
    }
    warn("part 1: {}\npart 2: {}\n", sum, sum2);
}

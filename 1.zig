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
        const mass = try std.fmt.parseInt(usize, line, 10);
        sum += (mass / 3) - 2;
        var fuel = mass;
        while (fuel > 6) {
            fuel = (fuel / 3) - 2;
            sum2 += fuel;
        }
    }
    warn("part 1: {}\n", sum);
    warn("part 2: {}\n", sum2);
}

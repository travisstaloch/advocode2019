// cat ../../julia-play/challenges/advocode2019/3.in | zig run 3.zig

const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;

const Pt = struct {
    x: i32,
    y: i32,
};
const PtLenMap = std.AutoHashMap(Pt, u32);
const PtSet = std.AutoHashMap(Pt, void);

fn intersect(a: *PtLenMap, b: *PtLenMap) !PtSet {
    var pts = PtSet.init(a.allocator);
    var ita = a.iterator();
    while (ita.next()) |kva| {
        const ak = kva.key;
        if (b.get(ak)) |_| {
            _ = try pts.put(ak, {});
        }
    }
    return pts;
}

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    var points = [2]PtLenMap{ PtLenMap.init(allocator), PtLenMap.init(allocator) };
    defer points[0].deinit();
    defer points[1].deinit();

    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;

    var line_i: u8 = 0;
    var linebuf: [2024]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&linebuf, '\n')) |line| : (line_i += 1) {
        var cur = Pt{ .x = 0, .y = 0 };
        var length: u32 = 0;

        var lineit = std.mem.separate(line, ",");
        while (lineit.next()) |segment| {
            const trimmed = std.mem.trim(u8, segment[1..], " \n");
            var n = try std.fmt.parseInt(i32, trimmed, 10);
            const dxy = switch (segment[0]) {
                'U' => [2]i32{ 0, -1 },
                'D' => [2]i32{ 0, 1 },
                'L' => [2]i32{ -1, 0 },
                'R' => [2]i32{ 1, 0 },
                else => return error.InvalidDirection,
            };

            while (n > 0) : (n -= 1) {
                cur.x += dxy[0];
                cur.y += dxy[1];
                length += 1;
                _ = try points[line_i].put(Pt{ .x = cur.x, .y = cur.y }, length);
            }
        }
    }

    const both = try intersect(&points[0], &points[1]);
    defer both.deinit();
    var ib = both.iterator();
    var min_md = @as(i32, std.math.maxInt(i32));
    var min_len = @as(u32, std.math.maxInt(u32));
    while (ib.next()) |it| {
        const bk = it.key;
        const md = (try std.math.absInt(bk.x)) + (try std.math.absInt(bk.y));
        if (md < min_md) {
            min_md = md;
        }
        const len = points[0].get(bk).?.value + points[1].get(bk).?.value;
        if (len < min_len) {
            min_len = len;
        }
    }
    warn("part1: {}\npart2: {}\n", min_md, min_len);
}

// cat ../../julia-play/challenges/advocode2019/3.in | zig run 3.zig

const std = @import("std");
const warn = std.debug.warn;

const Pt = struct {
    x: i32,
    y: i32,
};
const PtLenMap = std.AutoHashMap(Pt, u32);
const PtSet = std.AutoHashMap(Pt, void);

fn intersect(a: *PtLenMap, b: *PtLenMap) !PtSet {
    var pts = PtSet.init(a.allocator);
    var it = a.iterator();
    while (it.next()) |kv| {
        if (b.get(kv.key)) |_|
            _ = try pts.put(kv.key, {});
    }
    return pts;
}

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    var wires = [2]PtLenMap{ PtLenMap.init(allocator), PtLenMap.init(allocator) };
    defer for (wires) |w| w.deinit();

    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;

    var line_i: u8 = 0;
    var linebuf: [2024]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&linebuf, '\n')) |line| : (line_i += 1) {
        var cur = Pt{ .x = 0, .y = 0 };
        var wire_len: u32 = 0;

        var it = std.mem.separate(line, ",");
        while (it.next()) |segment| {
            var n = try std.fmt.parseInt(i32, std.mem.trim(u8, segment[1..], " \n"), 10);
            const dxy = switch (segment[0]) {
                'U' => Pt{ .x = 0, .y = -1 },
                'D' => Pt{ .x = 0, .y = 1 },
                'L' => Pt{ .x = -1, .y = 0 },
                'R' => Pt{ .x = 1, .y = 0 },
                else => return error.InvalidDirection,
            };

            while (n > 0) : (n -= 1) {
                cur.x += dxy.x;
                cur.y += dxy.y;
                wire_len += 1;
                _ = try wires[line_i].put(Pt{ .x = cur.x, .y = cur.y }, wire_len);
            }
        }
    }

    const both = try intersect(&wires[0], &wires[1]);
    defer both.deinit();
    var it = both.iterator();
    var min_dist = @as(i32, std.math.maxInt(i32));
    var min_len = @as(u32, std.math.maxInt(u32));
    while (it.next()) |kv| {
        const bk = kv.key;
        const dist = (try std.math.absInt(bk.x)) + (try std.math.absInt(bk.y));
        if (dist < min_dist) min_dist = dist;
        const len = wires[0].get(bk).?.value + wires[1].get(bk).?.value;
        if (len < min_len) min_len = len;
    }
    warn("part1: {}\npart2: {}\n", min_dist, min_len);
}

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
    while (it.next()) |kva| {
        const ak = kva.key;
        if (b.get(ak)) |_| {
            _ = try pts.put(ak, {});
        }
    }
    return pts;
}

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    var wires = [2]PtLenMap{ PtLenMap.init(allocator), PtLenMap.init(allocator) };
    defer wires[0].deinit();
    defer wires[1].deinit();

    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;

    var line_i: u8 = 0;
    var linebuf: [2024]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&linebuf, '\n')) |line| : (line_i += 1) {
        var cur = Pt{ .x = 0, .y = 0 };
        var wire_len: u32 = 0;

        var lineit = std.mem.separate(line, ",");
        while (lineit.next()) |segment| {
            const trimmed = std.mem.trim(u8, segment[1..], " \n");
            var n = try std.fmt.parseInt(i32, trimmed, 10);
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
    var min_md = @as(i32, std.math.maxInt(i32));
    var min_len = @as(u32, std.math.maxInt(u32));
    while (it.next()) |kv| {
        const bk = kv.key;
        const md = (try std.math.absInt(bk.x)) + (try std.math.absInt(bk.y));
        if (md < min_md) min_md = md;
        const len = wires[0].get(bk).?.value + wires[1].get(bk).?.value;
        if (len < min_len) min_len = len;
    }
    warn("part1: {}\npart2: {}\n", min_md, min_len);
}

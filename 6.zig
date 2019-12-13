const std = @import("std");
const warn = std.debug.warn;

const StrGraph = std.StringHashMap(std.ArrayList([]const u8));

fn insert(a: *std.mem.Allocator, graph: *StrGraph, k: []const u8, v: []const u8) !void {
    if (graph.contains(k)) {
        try graph.get(k).?.value.append(v);
    } else {
        var list = std.ArrayList([]const u8).init(a);
        _ = try list.append(v);
        _ = try graph.put(k, list);
    }
}

fn traverse(graph: *StrGraph, k: []const u8, dcount: isize, icount: isize, dist: *isize) void {
    dist.* += dcount + icount - 1;
    if (graph.get(k)) |kv| for (kv.value.toSliceConst()) |v| traverse(graph, v, 1, icount + 1, dist);
}

pub fn main() !void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [20]u8 = undefined;
    const a = std.heap.page_allocator;
    var graph = &StrGraph.init(a);
    var graph_bidir = &StrGraph.init(a);
    defer graph.deinit();
    defer graph_bidir.deinit();
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const _i = std.mem.indexOf(u8, line, ")");
        if (_i) |i| {
            const l = try std.mem.dupe(a, u8, line[0..i]);
            const r = try std.mem.dupe(a, u8, line[i + 1 ..]);
            try insert(a, graph, l, r);
            try insert(a, graph_bidir, l, r);
            try insert(a, graph_bidir, r, l);
        } else return error.UnexpectedInput;
    }

    var dist: isize = 0;
    traverse(graph, "COM", 0, 0, &dist);
    warn("part1: {}\n", dist + 1);

    var dists = std.StringHashMap(usize).init(a);

    const E = struct {
        e: []const u8,
        d: usize,
    };
    var curs = std.ArrayList(E).init(a);
    defer curs.deinit();
    _ = try curs.append(.{ .e = "YOU", .d = 0 });
    while (curs.len > 0) {
        const cur = curs.orderedRemove(0); // pop left
        if (dists.contains(cur.e)) continue;
        _ = try dists.put(cur.e, cur.d);
        if (graph_bidir.get(cur.e)) |_y| {
            for (_y.value.toSliceConst()) |y|
                _ = try curs.append(E{ .e = y, .d = cur.d + 1 });
        }
    }
    if (dists.get("SAN")) |d| warn("part2: {}\n", d.value - 2);

    var it = graph.iterator();
    while (it.next()) |kv| kv.value.deinit();
    it = graph_bidir.iterator();
    while (it.next()) |kv| kv.value.deinit();
}

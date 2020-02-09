const std = @import("std");
const warn = std.debug.warn;

const Point = struct {
    x: i16,
    y: i16,
};

const PointSet = std.AutoHashMap(Point, void);

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [50]u8 = undefined;
    var y: i16 = 0;
    const a = std.heap.page_allocator;
    var points = std.ArrayList(Point).init(a);
    var point_set = PointSet.init(a);
    defer {
        points.deinit();
        point_set.deinit();
    }
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (y += 1) {
        for (line) |c, x| {
            if (c == '#') {
                const p = Point{ .x = @intCast(i16, x), .y = y };
                _ = try points.append(p);
                _ = try point_set.put(p, {});
            }
        }
    }

    const station_info = try max_detectable(points.toSliceConst(), point_set);
    warn("part1: {}\n", .{station_info.y});

    const part2 = try nth_scanned(a, 199, &points, station_info.x, point_set);
    warn("part2: {}\n", .{part2});
}

// returns x = station_i, y = detectable asteroids
fn max_detectable(asteroids: []const Point, point_set: PointSet) !Point {
    var index: usize = undefined;
    var max_detected: i16 = 0;
    for (asteroids) |a, i| {
        const detected = try detectable_count(a, asteroids, point_set);
        if (detected > max_detected) {
            max_detected = detected;
            index = i;
        }
    }
    return Point{ .x = @intCast(i16, index), .y = max_detected };
}

fn detectable_count(a: Point, asteroids: []const Point, point_set: PointSet) !i16 {
    var count: i16 = 0;
    outer: for (asteroids) |b| {
        if (std.meta.eql(a, b)) continue :outer;
        var p = try stride_towards(a, b);
        while (!std.meta.eql(p, b)) {
            if (point_set.contains(p)) continue :outer;
            p = try stride_towards(p, b);
        }
        count += 1;
    }
    return count;
}

fn stride_towards(p: Point, q: Point) !Point {
    if (std.meta.eql(p, q)) return p;
    const dx = q.x - p.x;
    const dy = q.y - p.y;
    const g = try gcd(try std.math.absInt(dx), try std.math.absInt(dy));
    return Point{ .x = p.x + @divTrunc(dx, g), .y = p.y + @divTrunc(dy, g) };
}

fn gcd(a: var, b: @TypeOf(a)) !@TypeOf(a) {
    var aa = try std.math.absInt(a);
    var ab = try std.math.absInt(b);
    while (ab != 0) {
        var t = aa;
        aa = ab;
        ab = @rem(t, ab);
    }
    return aa;
}

test "gcd" {
    std.testing.expect((try gcd(@as(i16, 32), 48)) == 16);
}

fn nth_scanned(al: *std.mem.Allocator, nth: usize, asteroids: *std.ArrayList(Point), station_i: i16, point_set: PointSet) !i16 {
    const station = asteroids.orderedRemove(@intCast(usize, station_i));
    var strides = std.AutoHashMap(Point, i16).init(al);
    defer strides.deinit();

    for (asteroids.toSliceConst()) |a| {
        var n: i16 = 0;
        var p = try stride_towards(a, station);
        while (!std.meta.eql(p, station)) : (p = try stride_towards(p, station)) {
            if (point_set.contains(p)) n += 1;
        }
        _ = try strides.put(a, n);
    }
    const AngPt = struct {
        ang: f32,
        a: Point,
        const Self = @This();
        pub fn ang_less_than(a: Self, b: Self) bool {
            return a.ang < b.ang;
        }
    };
    var angles = std.ArrayList(AngPt).init(al);
    for (asteroids.toSliceConst()) |a|
        _ = try angles.append(AngPt{ .ang = angle_between(a, station, strides), .a = a });

    std.sort.sort(AngPt, angles.toSlice(), AngPt.ang_less_than);
    const a = angles.at(nth).a;
    return a.x * 100 + a.y;
}

fn angle_between(a: Point, station: Point, strides: std.AutoHashMap(Point, i16)) f32 {
    var phi = std.math.atan2(f32, @intToFloat(f32, a.y - station.y), @intToFloat(f32, a.x - station.x));
    if (phi < -std.math.pi / 2.0) phi += 2.0 * std.math.pi;
    phi += 2.0 * std.math.pi * @intToFloat(f32, strides.getValue(a) orelse unreachable);
    return phi;
}

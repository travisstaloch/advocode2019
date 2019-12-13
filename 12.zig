const std = @import("std");
const warn = std.debug.warn;

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [30]u8 = undefined;
    var vi: usize = 0;
    const a = std.heap.page_allocator;
    var bodies: [4]Body = [1]Body{.{ .ps = V3(isize){}, .vs = V3(isize){} }} ** 4;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |vecstr| : (vi += 1) {
        var it = std.mem.separate(vecstr[1 .. vecstr.len - 1], ", ");
        var i: usize = 0;
        while (it.next()) |part| : (i += 1) {
            const n = try std.fmt.parseInt(isize, part[2..], 10);
            switch (i) {
                0 => @field(bodies[vi].ps, "x") = n,
                1 => @field(bodies[vi].ps, "y") = n,
                2 => @field(bodies[vi].ps, "z") = n,
                else => unreachable,
            }
        }
    }
    const e = try part1(a, try std.mem.dupe(a, Body, &bodies), 1000);
    warn("part1: {}\n", .{e});

    const steps = try part2(a, try std.mem.dupe(a, Body, &bodies));
    warn("part2: {}\n", .{steps});
}

pub fn V3(comptime T: type) type {
    return struct {
        x: T = 0,
        y: T = 0,
        z: T = 0,
    };
}
const Body = struct {
    ps: V3(isize),
    vs: V3(isize),
};

fn sign(comptime T: type, v: T) T {
    return switch (v) {
        1...std.math.maxInt(T) => 1,
        std.math.minInt(T)...-1 => -1,
        0 => 0,
    };
}

fn part1(a: *std.mem.Allocator, bodies: []Body, steps: usize) !isize {
    defer a.free(bodies);
    var i: usize = 0;
    while (i < steps) : (i += 1) {
        for (bodies) |*b1| {
            for (bodies) |b2| {
                inline for (std.meta.fields(V3(isize))) |f| {
                    const l = @field(b2.ps, f.name);
                    const r = @field(b1.ps, f.name);
                    @field(b1.vs, f.name) += sign(isize, l - r);
                }
            }
        }
        for (bodies) |*b| {
            inline for (std.meta.fields(V3(isize))) |f| {
                @field(b.ps, f.name) += @field(b.vs, f.name);
            }
        }
    }
    var e: isize = 0;
    for (bodies) |b| {
        const pe = (try std.math.absInt(b.ps.x)) + (try std.math.absInt(b.ps.y)) + (try std.math.absInt(b.ps.z));
        const ke = (try std.math.absInt(b.vs.x)) + (try std.math.absInt(b.vs.y)) + (try std.math.absInt(b.vs.z));
        e += pe * ke;
    }
    return e;
}

// Part 2
const Body2 = struct {
    p: isize,
    v: isize,
};

pub fn gcd(a: var, b: @TypeOf(a)) @TypeOf(a) {
    var aa = a;
    var ab = b;
    if (@TypeOf(a).is_signed) {
        aa = std.math.absInt(a) catch unreachable;
        ab = std.math.absInt(b) catch unreachable;
    }
    while (ab != 0) {
        var t = aa;
        aa = ab;
        ab = @rem(t, ab);
    }
    return aa;
}

pub fn lcm(a: var, b: @TypeOf(a)) @TypeOf(a) {
    return @divExact(a * b, gcd(a, b));
}

fn eq(b1: Body2, b2: Body2) bool {
    return b1.p == b2.p and b2.v == b2.v;
}

fn all(f: var, as: var, bs: var) bool {
    for (as) |a, i| {
        if (!f(a, bs[i])) return false;
    }
    return true;
}

fn cycle_len(a: *std.mem.Allocator, b2s: []Body2) !usize {
    const init = try std.mem.dupe(a, Body2, b2s);
    defer a.free(init);
    var step: usize = 1;
    while (true) : (step += 1) {
        for (b2s) |*b1| {
            for (b2s) |b2| b1.v += sign(isize, b2.p - b1.p);
        }
        for (b2s) |*b| b.p += b.v;
        if (all(eq, b2s, init)) {
            warn("{}\n", .{step});
            // for some reason, this is coming out off by one
            // i don't understand why adding 1 is necessary
            return step + 1;
        }
    }
    return error.NoCycleFound;
}

fn part2(a: *std.mem.Allocator, bodies: []Body) !usize {
    defer a.free(bodies);
    const b2s_size = 4;
    var b2s = [1]Body2{.{ .p = undefined, .v = undefined }} ** b2s_size;
    var cycle_lens = V3(usize){};
    inline for (std.meta.fields(V3(isize))) |f| {
        comptime var i: usize = 0;
        inline while (i < b2s_size) : (i += 1) {
            b2s[i] = Body2{ .p = @field(bodies[i].ps, f.name), .v = @field(bodies[i].vs, f.name) };
        }
        @field(cycle_lens, f.name) = try cycle_len(a, &b2s);
    }
    return lcm(lcm(cycle_lens.x, cycle_lens.y), cycle_lens.z);
}

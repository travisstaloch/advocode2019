const std = @import("std");
const warn = std.debug.warn;
pub const io_mode = .evented;

const argParser = struct {
    const Self = @This();
    p: []i32 = undefined,
    i: usize = undefined,
    flags: [3]u1 = undefined,
    fn get(s: Self, n: usize) i32 {
        if (s.i + n >= s.p.len) return -0xaa;
        var a = s.p[s.i + n];
        return if (s.flags[n - 1] == 1) a else if (a >= s.p.len) -0xaa else s.p[@intCast(usize, a)];
    }
    fn imm(s: Self, n: usize) usize {
        return @intCast(usize, s.p[s.i + n]);
    }
    fn init(p: []i32, i: usize) Self {
        var s = Self{ .p = p, .i = i };
        for (s.flags) |_, fi| {
            const exp = std.math.powi(usize, 10, fi + 2) catch unreachable;
            s.flags[fi] = @intCast(u1, (@intCast(usize, p[i]) / exp) % 10);
        }
        return s;
    }
};

const IntChan = std.event.Channel(i32);

const machine = struct {
    const Self = @This();
    p: []i32 = undefined,
    i: usize = 0,
    in: *IntChan,
    out: *IntChan,
    done: *std.event.Channel(bool),
    id: usize,

    fn run(self: *Self) void {
        while (self.i < self.p.len) {
            var op = @mod(self.p[self.i], 100);
            var args = argParser.init(self.p, self.i);

            switch (op) {
                // stores
                1 => self.p[args.imm(3)] = args.get(1) + args.get(2),
                2 => self.p[args.imm(3)] = args.get(1) * args.get(2),
                7 => self.p[args.imm(3)] = if (args.get(1) < args.get(2)) 1 else 0,
                8 => self.p[args.imm(3)] = if (args.get(1) == args.get(2)) 1 else 0,
                // conditional jumps
                5 => self.i = if (args.get(1) != 0) @intCast(usize, args.get(2)) else self.i + 3,
                6 => self.i = if (args.get(1) == 0) @intCast(usize, args.get(2)) else self.i + 3,
                // I/O
                3 => self.p[args.imm(1)] = self.in.get(),
                4 => self.out.put(args.get(1)),
                // halt
                99 => {
                    self.done.put(true);
                    return;
                },
                else => @panic("error.InvalidOpCode"),
            }
            self.i += switch (op) {
                1, 2, 7, 8 => @intCast(usize, 4),
                5, 6 => 0, // already jumped
                3, 4 => 2,
                99 => 1,
                else => @panic("error.InvalidOpCode"),
            };
        }
        unreachable;
    }
};

fn unique(xs: var, map: var) !bool {
    map.clear();
    for (xs) |x| _ = try map.put(x, {});
    return xs.len == map.count();
}

fn perms5(lo: i32, hi: i32, perm_ch: *std.event.Channel(?[5]i32)) void {
    const al = std.heap.page_allocator;
    var map = std.AutoHashMap(i32, void).init(al);
    defer map.deinit();
    var a: i32 = lo;
    while (a <= hi) : (a += 1) {
        var b: i32 = lo;
        while (b <= hi) : (b += 1) {
            var c: i32 = lo;
            while (c <= hi) : (c += 1) {
                var d: i32 = lo;
                while (d <= hi) : (d += 1) {
                    var e: i32 = lo;
                    while (e <= hi) : (e += 1) {
                        const candidate = [_]i32{ a, b, c, d, e };
                        const u = unique(candidate, &map) catch @panic("no memory");
                        if (u)
                            perm_ch.put(candidate);
                    }
                }
            }
        }
    }
    perm_ch.put(null);
}

pub fn main() !void {
    const allr = std.heap.page_allocator;
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [20]u8 = undefined;
    var prog: [2024]i32 = undefined;
    var numi: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |num| : (numi += 1) {
        prog[numi] = try std.fmt.parseInt(i32, num, 10);
    }

    var perm_ch: std.event.Channel(?[5]i32) = undefined;
    perm_ch.init(&[_]?[5]i32{});
    _ = async perms5(0, 4, &perm_ch);

    // part 1
    var max: i32 = -1;
    var machines: [5]machine = undefined;
    var frames: [5]@Frame(machine.run) = undefined;
    var chans: [6]IntChan = undefined;
    var done: std.event.Channel(bool) = undefined;

    while (perm_ch.get()) |perm| {
        for (chans) |*chan| chan.init(&[_]i32{});
        done.init(&[_]bool{});
        for (machines) |*m, i| {
            m.* = machine{
                .p = try std.mem.dupe(allr, i32, prog[0..numi]),
                .in = &chans[i],
                .out = &chans[i + 1],
                .done = &done,
                .id = i,
            };
            frames[i] = async machines[i].run();
        }

        for (perm) |p, i| chans[i].put(p);
        chans[0].put(0);
        for (machines[0..4]) |_, i| _ = done.get();
        const out = chans[5].get();
        _ = done.get();
        max = std.math.max(max, out);
    }
    warn("{}\n", .{max});

    // part 2
    perm_ch.init(&[_]?[5]i32{});
    _ = async perms5(5, 9, &perm_ch);
    max = -1;
    while (perm_ch.get()) |perm| {
        for (chans) |*chan| chan.init(&[_]i32{});
        done.init(&[_]bool{});
        for (machines) |*m, i| {
            m.* = machine{
                .p = try std.mem.dupe(allr, i32, prog[0..numi]),
                .in = &chans[(4 + i) % 5],
                .out = &chans[i],
                .done = &done,
                .id = i,
            };
            frames[i] = async machines[i].run();
        }

        for (machines) |_, i| chans[(4 + i) % 5].put(perm[i]);
        chans[4].put(0);
        for (machines[0..4]) |_, i| _ = done.get();
        const out = chans[4].get();
        _ = done.get();
        max = std.math.max(max, out);
    }
    warn("{}\n", .{max});
}

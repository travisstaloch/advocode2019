const std = @import("std");
const warn = std.debug.warn;

pub const io_mode = .evented;

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [20]u8 = undefined;
    var program: [2024]i32 = undefined;
    var numi: usize = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |num| : (numi += 1) {
        program[numi] = try std.fmt.parseInt(i32, num, 10);
    }

    const a = std.heap.page_allocator;
    const part1 = try find_settings(a, program[0..numi], run_settings, [_]i32{ 0, 4 });
}

/// break a number into individual digits. return length
pub fn digits(comptime T: type, n: T, buf: []T) usize {
    var x = n;
    var i: usize = 0;
    while (x > 0) : (x = @divTrunc(x, 10)) {
        buf[i] = @truncate(T, @mod(x, 10));
        i += 1;
    }
    return i;
}

fn asu(n: i32) usize {
    return @intCast(usize, n);
}

const Channel = std.event.Channel;
const IntChan = Channel(i32);

const Amp = struct {
    prog: []i32,
    ip: usize,
    input: *IntChan,
    output: *IntChan,
    halt: *Channel(bool),
    id: usize,
};
const IntChanThreaded = [2]i32;
const AmpThreaded = struct {
    prog: []i32,
    ip: usize,
    input: IntChanThreaded,
    output: IntChanThreaded,
    halt: IntChanThreaded,
    id: usize,
};

fn keys(a: *std.mem.Allocator, comptime T: type, m: T, comptime R: type) ![]const R {
    var ks = std.ArrayList(R).init(a);
    var it = m.iterator();
    while (it.next()) |kv| _ = try ks.append(kv.key);
    // warn("\n");
    // for (ks.toSliceConst()) |k| warn(" {},", k);
    return ks.toSliceConst();
}

fn unique(a: *std.mem.Allocator, comptime T: type, slice: []const T) ![]const T {
    var m = std.AutoHashMap(T, void).init(a);
    for (slice) |e| _ = try m.put(e, {});
    return keys(a, std.AutoHashMap(T, void), m, T);
}

fn threadRun(a: *Amp) void {
    if (run(a)) {} else |err|
        std.debug.warn("Amp {} failed to run successfully: {}\n", a.id, err);
}

fn read(dev: [2]i32) !i32 {
    const fd = dev[0]; // Read from the pipe
    var store: [4]u8 = undefined;

    // std.debug.warn("{}: __in({} <- {})\n", self.idx, dev[0], dev[1]);
    var frame = async std.os.read(fd, &store);
    var n = try await frame;
    std.debug.assert(n == 4); // TODO: handle partial reads

    return std.mem.readIntNative(i32, &store);
}

fn write(dev: [2]i32, val: i32) !void {
    const fd = dev[1]; // Write to the pipe
    const bytes = std.mem.asBytes(&val);

    // std.debug.warn("{}: __out({} -> {}, {})\n", self.idx, dev[1], dev[0], val);
    try std.os.write(fd, bytes);
}

fn run_settings(a: *std.mem.Allocator, program: []i32, settings: []const i32) !i32 {
    std.debug.assert((try unique(a, i32, settings)).len == 5);
    warn("run settings \n");
    const chans = [_]*IntChan{
        try a.create(IntChan),
        try a.create(IntChan),
        try a.create(IntChan),
        try a.create(IntChan),
        try a.create(IntChan),
        try a.create(IntChan),
    };
    for (chans) |chan| chan.init(&[0]i32{});
    const halt = try a.create(Channel(bool));
    halt.init(&[0]bool{});

    const dupe = std.mem.dupe;
    // (try a.create(@Frame(run))).* = async run(&Amp{ .prog = try dupe(a, i32, program), .ip = 1, .input = chans[0], .output = chans[1], .halt = halt, .id = 0 });
    // (try a.create(@Frame(run))).* = async run(&Amp{ .prog = try dupe(a, i32, program), .ip = 1, .input = chans[1], .output = chans[2], .halt = halt, .id = 1 });
    // (try a.create(@Frame(run))).* = async run(&Amp{ .prog = try dupe(a, i32, program), .ip = 1, .input = chans[2], .output = chans[3], .halt = halt, .id = 2 });
    // (try a.create(@Frame(run))).* = async run(&Amp{ .prog = try dupe(a, i32, program), .ip = 1, .input = chans[3], .output = chans[4], .halt = halt, .id = 3 });
    // (try a.create(@Frame(run))).* = async run(&Amp{ .prog = try dupe(a, i32, program), .ip = 1, .input = chans[4], .output = chans[5], .halt = halt, .id = 4 });
    // warn("{}\n", t0);
    var amps: [5]*Amp = undefined;
    amps[0] = &Amp{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[0], .output = chans[0 + 1], .halt = halt, .id = 0 };
    amps[1] = &Amp{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[1], .output = chans[1 + 1], .halt = halt, .id = 1 };
    amps[2] = &Amp{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[2], .output = chans[2 + 1], .halt = halt, .id = 2 };
    amps[3] = &Amp{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[3], .output = chans[3 + 1], .halt = halt, .id = 3 };
    amps[4] = &Amp{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[4], .output = chans[4 + 1], .halt = halt, .id = 4 };

    // var f0 = async run(amps[0]);
    // var f1 = async run(amps[1]);
    // var f2 = async run(amps[2]);
    // var f3 = async run(amps[3]);
    // var f4 = async run(amps[4]);
    (try a.create(@Frame(run))).* = async run(amps[0]);
    (try a.create(@Frame(run))).* = async run(amps[1]);
    (try a.create(@Frame(run))).* = async run(amps[2]);
    (try a.create(@Frame(run))).* = async run(amps[3]);
    (try a.create(@Frame(run))).* = async run(amps[4]);

    for (amps) |amp, i| _ = amps[i].input.put(settings[i]);
    _ = amps[0].input.put(0);
    // try run(amps[0]);

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        _ = halt.get();
    }
    return chans[5].get();
}

fn run_settings_threads(a: *std.mem.Allocator, program: []i32, settings: []const i32) !i32 {
    std.debug.assert((try unique(a, i32, settings)).len == 5);
    warn("run settings \n");
    const chans = [_]IntChanThreaded{
        try std.os.pipe(),
        try std.os.pipe(),
        try std.os.pipe(),
        try std.os.pipe(),
        try std.os.pipe(),
        try std.os.pipe(),
    };
    const halt = try std.os.pipe();

    const dupe = std.mem.dupe;
    var amps: [5]*Amp = undefined;
    amps[0] = &AmpThreaded{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[0], .output = chans[0 + 1], .halt = halt, .id = 0 };
    amps[1] = &AmpThreaded{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[1], .output = chans[1 + 1], .halt = halt, .id = 1 };
    amps[2] = &AmpThreaded{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[2], .output = chans[2 + 1], .halt = halt, .id = 2 };
    amps[3] = &AmpThreaded{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[3], .output = chans[3 + 1], .halt = halt, .id = 3 };
    amps[4] = &AmpThreaded{ .prog = try dupe(a, i32, program), .ip = 0, .input = chans[4], .output = chans[4 + 1], .halt = halt, .id = 4 };

    for (amps) |amp, i| _ = try write(amps[i].input, settings[i]);
    _ = try write(amps[0].input, 0);

    const t0 = try std.Thread.spawn(amps[0], threadRun);
    const t1 = try std.Thread.spawn(amps[1], threadRun);
    const t2 = try std.Thread.spawn(amps[2], threadRun);
    const t3 = try std.Thread.spawn(amps[3], threadRun);
    const t4 = try std.Thread.spawn(amps[4], threadRun);
    t0.wait();
    t1.wait();
    t2.wait();
    t3.wait();
    t4.wait();
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        _ = try read(amps[i].halt);
    }
    return try read(amps[4].output);
}

fn find_settings(allocator: *std.mem.Allocator, program: []i32, run_settings_fn: var, rg: [2]i32) !i32 {
    var ret: i32 = 0;
    var a: i32 = rg[0];
    while (a <= rg[1]) : (a += 1) {
        var b: i32 = rg[0];
        while (b <= rg[1]) : (b += 1) {
            var c: i32 = rg[0];
            while (c <= rg[1]) : (c += 1) {
                var d: i32 = rg[0];
                while (d <= rg[1]) : (d += 1) {
                    var e: i32 = rg[0];
                    while (e <= rg[1]) : (e += 1) {
                        const settings = [_]i32{ a, b, c, d, e };
                        if ((try unique(allocator, i32, settings[0..])).len != 5) continue;
                        warn("settings ");
                        for (settings) |s| warn(" {},", s);
                        const out = try run_settings_fn(allocator, program, settings[0..]);
                        if (out > ret) ret = out;
                    }
                }
            }
        }
    }

    warn("{}\n", ret);
    return ret;
}

pub fn run(a: *Amp) !void {
    warn("running {}\n", a.id);
    const op_arg_lens = [_]usize{ 0, 4, 4, 2, 2, 3, 3, 4, 4 };

    while (true) {
        var digs_buf: [10]i32 = [_]i32{0} ** 10;
        const ndigs = digits(i32, a.prog[a.ip], digs_buf[0..]);
        const opcode = digs_buf[0] + (if (ndigs > 1) digs_buf[1] else 0) * 10;
        std.debug.assert(1 <= opcode and opcode <= 8);
        const args_len = op_arg_lens[asu(opcode)] - 1;
        var digs = digs_buf[2 .. 2 + args_len];

        var args_buf: [3]i32 = [_]i32{0} ** 3;
        const args = args_buf[0..args_len];
        var argi: usize = 0;
        while (argi < args_len) : (argi += 1) {
            var dig = if (argi < ndigs) digs[argi] else 0;
            if (argi == args_len - 1 and (opcode == 1 or opcode == 2 or opcode == 7 or opcode == 8))
                dig = 1;
            args[argi] = if (dig == 0) a.prog[asu(a.prog[a.ip + argi + 1])] else a.prog[a.ip + argi + 1];
        }
        warn("{}::{}-{} :", a.id, a.ip, opcode);
        for (args) |arg| warn(" {},", arg);
        warn("\n");

        switch (opcode) {
            1 => a.prog[asu(args[2])] = args[0] + args[1],
            2 => a.prog[asu(args[2])] = args[0] * args[1],
            // 3 => a.prog[asu(a.prog[a.ip + 1])] = try read(a.input),
            // 4 => try write(a.output, args[0]),
            3 => a.prog[asu(a.prog[a.ip + 1])] = a.input.get(),
            4 => a.output.put(args[0]),
            5 => if (args[0] != 0) {
                a.ip = asu(args[1]);
                continue;
            },
            6 => if (args[0] == 0) {
                a.ip = asu(args[1]);
                continue;
            },
            7 => if (args[0] < args[1]) {
                a.prog[asu(args[2])] = 1;
            } else {
                a.prog[asu(args[2])] = 0;
            },
            8 => if (args[0] == args[1]) {
                a.prog[asu(args[2])] = 1;
            } else {
                a.prog[asu(args[2])] = 0;
            },
            // 99 => try write(a.halt, 1),
            99 => a.halt.put(true),
            else => return error.InvalidOpCode,
        }
        a.ip += args_len + 1;
    }
}

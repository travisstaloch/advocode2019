const std = @import("std");
const warn = std.debug.warn;

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
    const prog1 = try std.mem.dupe(a, i32, program[0..numi]);
    defer a.free(prog1);
    try run(prog1, 1);
    const prog2 = try std.mem.dupe(a, i32, program[0..numi]);
    defer a.free(prog2);
    try run(prog2, 5);
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

pub fn run(prog: []i32, input: i32) !void {
    var ip: usize = 0;
    const op_arg_lens = [_]usize{ 0, 4, 4, 2, 2, 3, 3, 4, 4 };

    while (true) {
        if (prog[ip] == 99) return;
        var digs_buf: [10]i32 = [_]i32{0} ** 10;
        const ndigs = digits(i32, prog[ip], digs_buf[0..]);
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
            args[argi] = if (dig == 0) prog[asu(prog[ip + argi + 1])] else prog[ip + argi + 1];
        }

        switch (opcode) {
            1 => prog[asu(args[2])] = args[0] + args[1],
            2 => prog[asu(args[2])] = args[0] * args[1],
            3 => prog[asu(prog[ip + 1])] = input,
            4 => warn("{}\n", args[0]),
            5 => if (args[0] != 0) {
                ip = asu(args[1]);
                continue;
            },
            6 => if (args[0] == 0) {
                ip = asu(args[1]);
                continue;
            },
            7 => if (args[0] < args[1]) {
                prog[asu(args[2])] = 1;
            } else {
                prog[asu(args[2])] = 0;
            },
            8 => if (args[0] == args[1]) {
                prog[asu(args[2])] = 1;
            } else {
                prog[asu(args[2])] = 0;
            },
            else => return error.InvalidOpCode,
        }
        ip += args_len + 1;
    }
}

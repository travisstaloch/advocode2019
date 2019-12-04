// cat ../../julia-play/challenges/advocode2019/2.in | zig run 2.zig

const std = @import("std");
const warn = std.debug.warn;

fn run(program: []u32, noun: u32, verb: u32) !u32 {
    var pc: usize = 0;
    program[1] = noun;
    program[2] = verb;
    while (true) : (pc += 4) {
        const op1 = program[pc + 1];
        const op2 = program[pc + 2];
        const dest = program[pc + 3];
        switch (program[pc]) {
            1 => program[dest] = program[op1] + program[op2],
            2 => program[dest] = program[op1] * program[op2],
            99 => break,
            else => return error.InvalidOperation,
        }
    }
    return program[0];
}

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream().stream;
    var buf: [20]u8 = undefined;
    var i: usize = 0;
    var init_program: [1024]u32 = undefined;
    var program: [1024]u32 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |num_str| {
        const trimmed = std.mem.trim(u8, num_str, " \n");
        const num = try std.fmt.parseInt(u32, trimmed, 10);
        init_program[i] = num;
        i += 1;
    }
    std.mem.copy(u32, program[0..i], init_program[0..i]);
    warn("part 1: {}\n", try run(program[0..i], 12, 2));

    var noun: u32 = 0;
    while (noun < 100) : (noun += 1) {
        var verb: u32 = 0;
        while (verb < 100) : (verb += 1) {
            std.mem.copy(u32, program[0..i], init_program[0..i]);
            if ((try run(program[0..i], noun, verb)) == 19690720) {
                warn("part 2: {}\n", noun * 100 + verb);
                return;
            }
        }
    }
    return error.NoSolution;
}

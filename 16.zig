const std = @import("std");

pub fn main() anyerror!void {
    const stdin = std.io.getStdIn();
    const stream = &stdin.inStream();
    const a = std.heap.page_allocator;
    var input = std.ArrayList(u8).init(a);
    defer input.deinit();
    try stream.readAllArrayList(&input, 1024 * 10);
    var signal = std.mem.trim(u8, input.span(), "\n");
    std.debug.warn("answer {}\n", .{try fft(a, try std.mem.dupe(a, u8, signal), 100)});
    std.debug.warn("answer offset {}\n", .{try fft_offset(a, signal, 100)});
}

const coeffs = [_]i8{ 0, 1, 0, -1 };

fn fft(a: *std.mem.Allocator, _signal: []const u8, nphases: usize) !isize {
    var signal = @bitCast([]i8, _signal);
    var scratch = try a.alloc(i8, _signal.len);
    defer a.free(scratch);
    var phases = nphases;
    for (signal) |*c| c.* = c.* - '0';
    while (phases > 0) : (phases -= 1) {
        for (signal[0.._signal.len]) |_, i| {
            var sum: isize = 0;
            for (signal[0.._signal.len]) |c, j| {
                const coef = coeffs[((j + 1) / (i + 1)) % 4];
                sum += coef * c;
            }
            scratch[i] = @truncate(i8, @mod(try std.math.absInt(sum), 10));
        }
        var tmp = signal;
        signal = scratch;
        scratch = tmp;
    }

    return numberFromDigits(signal[0..8]);
}

fn numberFromDigits(digits: []i8) isize {
    var result: isize = 0;
    for (digits) |c, i| {
        result += c * std.math.pow(isize, 10, @intCast(i8, digits.len - i - 1));
    }
    return result;
}

fn repeat(a: *std.mem.Allocator, comptime T: type, input: []T, n: usize) ![]T {
    const result = try a.alloc(T, input.len * n);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const offset = i * input.len;
        std.mem.copy(T, result[offset .. offset + input.len], input);
    }
    return result;
}

fn fft_offset(a: *std.mem.Allocator, _signal: []const u8, nphases: usize) !isize {
    const offset = try std.fmt.parseInt(usize, _signal[0..7], 10);
    var signal = @bitCast([]i8, _signal);
    var scratch = try a.alloc(i8, _signal.len);
    defer a.free(scratch);
    var phases = nphases;
    for (signal) |*c| c.* = c.* - '0';
    var numbers = try repeat(a, i8, signal, 10000);
    while (phases > 0) : (phases -= 1) {
        var sum: isize = 0;
        var pos = numbers.len;
        while (pos > 0) : (pos -= 1) {
            sum += numbers[pos - 1];
            numbers[pos - 1] = @truncate(i8, @mod(try std.math.absInt(sum), 10));
        }
    }
    return numberFromDigits(numbers[offset .. offset + 8]);
}

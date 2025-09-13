const std = @import("std");
const posix = std.posix;

// Color enum with methods
const Color = enum {
    target,
    correct,
    error_fg,
    error_bg,
    reset,

    fn toString(self: Color) []const u8 {
        return switch (self) {
            .target => "\x1b[38;2;150;150;150m",
            .correct => "\x1b[38;2;226;183;20m",
            .error_fg => "\x1b[38;2;202;71;84m",
            .error_bg => "\x1b[48;2;156;51;63m",
            .reset => "\x1b[0m",
        };
    }
};

fn disableEcho() !void {
    var termios = try posix.tcgetattr(std.fs.File.stdin().handle);
    termios.lflag.ECHO = false;
    termios.lflag.ICANON = false;
    termios.iflag.ICRNL = false;
    try posix.tcsetattr(std.fs.File.stdin().handle, .NOW, termios);
}

fn enableEcho() !void {
    var termios = try posix.tcgetattr(std.fs.File.stdin().handle);
    termios.lflag.ECHO = true;
    termios.lflag.ICANON = true;
    try posix.tcsetattr(std.fs.File.stdin().handle, .NOW, termios);
}

// Tests
test "all colors have valid toString output" {
    // Test all enum values
    inline for (std.meta.fields(Color)) |field| {
        const color = @field(Color, field.name);
        const color_string = color.toString();
        try std.testing.expect(color_string.len > 0);
        // Verify ANSI escape sequence starts correctly
        try std.testing.expect(color_string[0] == '\x1b');
    }
}

fn printColoredChar(color: Color, char: u8) void {
    std.debug.print("{s}{c}{s}", .{ color.toString(), char, Color.reset.toString() });
}

fn printColoredString(color: Color, string: []const u8) void {
    std.debug.print("{s}{s}{s}", .{ color.toString(), string, Color.reset.toString() });
}

pub fn main() !void {
    try disableEcho();
    defer enableEcho() catch {};

    // Generate random seed and create RNG
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();
    
    // Select 10 random words from ALL_WORDS
    const words: [10][]const u8 = blk: {
        var result: [10][]const u8 = undefined;
        for (&result) |*word| {
            const random_index = random.intRangeAtMost(usize, 0, ALL_WORDS.len - 1);
            word.* = ALL_WORDS[random_index];
        }
        break :blk result;
    };
    
    // Create target string from selected words
    var target_buffer: [256]u8 = undefined;
    var target_len: usize = 0;
    for (words, 0..) |word, i| {
        @memcpy(target_buffer[target_len..target_len + word.len], word);
        target_len += word.len;
        if (i < words.len - 1) {
            target_buffer[target_len] = ' ';
            target_len += 1;
        }
    }
    const target = target_buffer[0..target_len];

    printColoredString(Color.target, target);
    std.debug.print("\x1b[{}D", .{target.len + 1});

    var buffer: [1]u8 = undefined;
    var index: usize = 0;
    while (index < target.len) {
        const bytes_read = try std.fs.File.stdin().read(&buffer);
        if (bytes_read == 0) break;
        const byte = buffer[0];

        // handle return key
        if (byte == 127) {
            if (index > 0) {
                index -= 1;
                std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.target.toString(), target[index], Color.reset.toString() });
            }
            continue;
        }

        if (byte == target[index]) {
            printColoredChar(.correct, byte);
        } else {
            printColoredChar(.error_fg, byte);
        }
        index += 1;
    }
}

const ALL_WORDS = [_][]const u8{ "i", "present", "my", "zig", "first", "program", "all", "software", "ai", "none", "all", "fast", "blazingly", "update", "upgrade", "improve", "understanding", "publication", "contact", "note", "hobby", "intervention", "discovery", "volcano", "trait", "balance", "criminal", "nerve", "dialect", "mutual", "terrace", "post", "lace", "tile", "tie", "exploit", "ancestor", "advance", "exchange", "building", "watch", "appreciate", "detective", "disagreement", "excavate", "experienced ", };
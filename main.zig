const std = @import("std");
const posix = std.posix;

// Color enum with methods
const Color = enum {
    gray,
    correct,
    error_fg,
    error_bg,
    reset,

    fn toString(self: Color) []const u8 {
        return switch (self) {
            .gray => "\x1b[38;2;150;150;150m",
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

fn printGrayedWords(words: []*const  []const u8) void {
    for (words, 0..) |word, i| {
        printColoredString(Color.gray, word.*);
        if (i < words.len - 1) {
            printColoredChar(Color.gray, ' ');
        }
    }
}

test "getRandomWords returns correct number of words" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words = try getRandomWords(allocator, 5);
    try std.testing.expect(words.len == 5);

    const single_word = try getRandomWords(allocator, 1);
    try std.testing.expect(single_word.len == 1);

    const many_words = try getRandomWords(allocator, 50);
    try std.testing.expect(many_words.len == 50);
}

test "getRandomWords returns valid word pointers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words = try getRandomWords(allocator, 10);

    // Check each word pointer is valid and points to a word from ALL_WORDS
    for (words) |word_ptr| {
        try std.testing.expect(word_ptr.*.len > 0);

        // Verify the word exists in ALL_WORDS
        var found = false;
        for (ALL_WORDS) |dict_word| {
            if (std.mem.eql(u8, word_ptr.*, dict_word)) {
                found = true;
                break;
            }
        }
        try std.testing.expect(found);
    }
}

test "getRandomWords handles zero words" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words = try getRandomWords(allocator, 0);
    try std.testing.expect(words.len == 0);
}

test "getRandomWords produces different results across calls" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words1 = try getRandomWords(allocator, 10);
    const words2 = try getRandomWords(allocator, 10);

    // While it's theoretically possible for random results to be identical,
    // with 44 words in the dictionary and 10 selections, it's very unlikely
    var identical = true;
    for (words1, words2) |w1, w2| {
        if (!std.mem.eql(u8, w1.*, w2.*)) {
            identical = false;
            break;
        }
    }
    try std.testing.expect(!identical);
}

test "getRandomWords memory allocation" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Test that memory is properly allocated
    const words = try getRandomWords(allocator, 3);
    try std.testing.expect(words.len == 3);

    // Verify we can access all word data
    for (words) |word_ptr| {
        _ = word_ptr.*.len; // Should not crash
        _ = word_ptr.*[0]; // Should not crash if word is non-empty
    }
}
pub fn getRandomWords(allocator: std.mem.Allocator, n: usize) ![]*const []const u8 {
    // Generate random seed and create RNG (classic PNRG instead of CSPRNG)
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });    const random: std.Random = prng.random();    // Calculate total length for cursor positioning

    // Create an array of pointers to string
    const result = try allocator.alloc(*const []const u8, n);
    for (result) |*word_ptr| {
        const random_index = random.intRangeAtMost(usize, 0, ALL_WORDS.len - 1);
        word_ptr.* = &ALL_WORDS[random_index];
    }
    return result;
}

pub fn main() !void {
    var arena  = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try disableEcho();
    defer enableEcho() catch {};

    const numberOfWords: comptime_int = 10;
    const words: []*const []const u8 = try getRandomWords(allocator, numberOfWords);
    printGrayedWords(words);

    var total_len: usize = 0;
    for (words) |word| total_len += word.len;
    total_len += words.len - 1; // spaces between words
    std.debug.print("\x1b[{}D", .{total_len});

    var buffer: [1]u8 = undefined;
    var current_word: usize = 0;
    var char_in_word: usize = 0;
    var overflow_chars: usize = 0;

    while (current_word < words.len) {
        const bytes_read = try std.fs.File.stdin().read(&buffer);
        if (bytes_read == 0) break;
        const byte = buffer[0];

        // Handle backspace
        if (byte == 127) {
            if (overflow_chars > 0) {
                overflow_chars -= 1;
                std.debug.print("\x1b[1D \x1b[1D", .{});
            } else if (char_in_word > 0) {
                char_in_word -= 1;
                const target_char = words[current_word].*[char_in_word];
                std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), target_char, Color.reset.toString() });
            }
            continue;
        }

        // Handle space - move to next word
        if (byte == ' ') {
            if (current_word < words.len - 1) {
                // Skip remaining chars in current word and the space
                const remaining_chars = words[current_word].len - char_in_word;
                if (remaining_chars > 0) {
                    std.debug.print("\x1b[{}C", .{remaining_chars});
                }
                std.debug.print("\x1b[1C", .{}); // skip the space

                current_word += 1;
                char_in_word = 0;
                overflow_chars = 0;
            }
            continue;
        }

        // Handle regular character input
        if (char_in_word < words[current_word].len) {
            // Within word bounds
            if (byte == words[current_word].*[char_in_word]) {
                printColoredChar(.correct, byte);
            } else {
                printColoredChar(.error_fg, byte);
            }
            char_in_word += 1;
        } else {
            // Overflow - beyond word length
            printColoredChar(.error_bg, byte);
            overflow_chars += 1;
        }
    }
}

pub const ALL_WORDS = [_][]const u8{ "i", "present", "my", "zig", "first", "program", "all", "software", "ai", "none", "all", "fast", "blazingly", "update", "upgrade", "improve", "understanding", "publication", "contact", "note", "hobby", "intervention", "discovery", "volcano", "trait", "balance", "criminal", "nerve", "dialect", "mutual", "terrace", "post", "lace", "tile", "tie", "exploit", "ancestor", "advance", "exchange", "building", "watch", "appreciate", "detective", "disagreement", "excavate", "experienced ", };
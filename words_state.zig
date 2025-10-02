const std = @import("std");
const word_state = @import("word_state.zig");
const color = @import("color.zig");
const WordState = word_state.WordState;
const CharState = word_state.CharState;
const Color = color.Color;

pub const ALL_WORDS = [_][]const u8{ "i", "present", "my", "zig", "first", "program", "all", "software", "ai", "none", "all", "fast", "blazingly", "update", "upgrade", "improve", "understanding", "publication", "contact", "note", "hobby", "intervention", "discovery", "volcano", "trait", "balance", "criminal", "nerve", "dialect", "mutual", "terrace", "post", "lace", "tile", "tie", "exploit", "ancestor", "advance", "exchange", "building", "watch", "appreciate", "detective", "disagreement", "excavate", "experienced " };

pub fn getRandomWords(allocator: std.mem.Allocator, n: usize) ![][]const u8 {
    // Generate random seed and create RNG (classic PNRG instead of CSPRNG)
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random: std.Random = prng.random();

    const result: [][]const u8 = try allocator.alloc([]const u8, n);
    for (result, 0..) |_, i| {
        const random_index = random.intRangeAtMost(usize, 0, ALL_WORDS.len - 1);
        result[i] = ALL_WORDS[random_index];
    }
    return result;
}

pub const WordsState = struct {
    word_states: []WordState,
    word_slices: [][]const u8,
    total_length: usize,

    pub fn wordIndexValid(self: *const WordsState, word_idx: usize) bool {
        return 0 <= word_idx and word_idx < self.word_slices.len;
    }

    pub fn getWordState(self: *const WordsState, word_idx: usize) !*const WordState {
    // pub fn getWordState(self: *const WordsState, word_idx: usize) *const WordState {
        if (!self.wordIndexValid(word_idx)) return error.IndexOutOfBounds;
        return &self.word_states[word_idx];
    }

    pub fn setCharStateAt(self: *const WordsState, word_idx: usize, char_idx: usize, char_state: CharState) !void {
        if (!self.wordIndexValid(word_idx)) return error.IndexOutOfBounds;
        return self.word_states[word_idx].setCharStateAt(char_idx, char_state);
    }

    pub fn getLastCharIdxToFill(self: *const WordsState, word_idx: usize) usize {
        if (0 <= word_idx and word_idx < self.word_states.len) return 0;
        const new_char_idx = if (self.getWordState(word_idx)) |ws| ws.getLastCharIdxToFill() else |_| 0;
        return new_char_idx;
    }

    pub fn init(allocator: std.mem.Allocator, number_of_words: usize) !WordsState {
        const word_slices: [][]const u8 = try getRandomWords(allocator, number_of_words);
        errdefer allocator.free(word_slices);
        const word_states: []WordState = try allocator.alloc(WordState, number_of_words);
        errdefer allocator.free(word_states);

        for (word_states, 0..) |*word_state_ptr, i| {
            word_state_ptr.* = try WordState.init(allocator, word_slices[i]);
        }

        return WordsState{
            .word_states = word_states,
            .word_slices = word_slices,
            .total_length = blk: {
                var l: usize = 0;
                // getting all the characters
                for (word_slices) |word_slice| {
                    l += word_slice.len;
                }
                // getting all the spaces
                l += word_states.len - 1;
                break :blk l;
            },
        };
    }

    pub fn deinit(self: *WordsState, allocator: std.mem.Allocator) void {
        for (self.word_states) |*word_state_ptr| {
            word_state_ptr.deinit(allocator);
        }
        allocator.free(self.word_states);
        allocator.free(self.word_slices);
    }

    pub fn print(self: *const WordsState, word_idx: usize, char_idx: usize) void {
        std.debug.print("\x1b[?25l", .{}); // Hide cursor

        // Clear entire line and go to beginning
        std.debug.print("\x1b[2K\x1b[G", .{});

        // Print all words with correct colors
        for (self.word_slices, 0..) |word_slice, word_idx_l| {
            for (word_slice, 0..) |char, char_idx_l| {
                const char_color: Color = switch (self.word_states[word_idx_l].char_states[char_idx_l]) {
                    .toComplete => .gray,
                    .valid => .correct,
                    .invalid => .error_fg,
                };
                color.printColoredChar(char_color, char);
            }

            // Print overflow characters for current word
            if (word_idx_l == word_idx) {
                for (self.word_states[word_idx_l].overflow) |overflow_char| {
                    if (overflow_char != 0) {
                        color.printColoredChar(.error_bg, overflow_char);
                    }
                }
            }

            if (word_idx_l < self.word_slices.len - 1) {
                color.printColoredChar(Color.gray, ' ');
            }
        }

        // Calculate cursor position and move there
        var cursor_pos: usize = 0;
        for (0..word_idx) |i| {
            cursor_pos += self.word_slices[i].len + 1; // +1 for space
        }
        cursor_pos += char_idx;

        // Move to cursor position and show cursor
        std.debug.print("\x1b[G\x1b[{}C\x1b[?25h", .{cursor_pos});
    }

    pub fn print0(self: *const WordsState) void {
        for (self.word_slices, 0..) |word_slice, word_idx_l| {
            for (word_slice) |char| {
                color.printColoredChar(.gray, char);
            }
            if (word_idx_l < self.word_slices.len - 1) {
                color.printColoredChar(Color.gray, ' ');
            }
        }
    }
};
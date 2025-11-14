const std = @import("std");
const color = @import("color.zig");
const Color = color.Color;

pub const CharState = enum {
    toComplete,
    valid,
    invalid,

    pub fn toColor(self: CharState) Color {
        return switch (self) {
            .toComplete => .gray,
            .valid => .correct,
            .invalid => .error_fg_underline,
        };
    }
};


const MAX_CHARS_OVERFLOW: comptime_int = 10;

pub const WordState = struct {
    word_slice: []const u8,
    char_states: []CharState,
    overflow: [MAX_CHARS_OVERFLOW]u8,

    pub fn charIndexValid(self: *const WordState, char_idx: usize) bool {
        return 0 <= char_idx and char_idx < self.word_slice.len;
    }

    /// This function will return the current overflow len of characters
    pub fn getFilledOverFlowLen(self: *WordState) usize {
        var overflow_count: usize = 0;
        for (self.overflow) |char| {
            if (char != 0) overflow_count += 1;
        }
        return overflow_count;
    }

    pub fn getLastCharIdxToFill(self: *const WordState) usize {
        for (self.char_states, 0..) |char_state, char_idx| {
            if (char_state == .toComplete) return char_idx;
        }
        return self.char_states.len;
    }

    pub fn removeLastOverflow(self: *WordState) !void {
        const overFlowLen: usize = self.getLastCharIdxToFill();
        // if (overFlowLen = ) return error.IndexOutOfBounds;
        // if (overFlowLen < 0) return error.IndexOutOfBounds;
        if (overFlowLen < 0 or MAX_CHARS_OVERFLOW <= overFlowLen) return error.IndexOutOfBounds;
        self.overflow[self.getLastCharIdxToFill()] = 0;
        // const
        // for (self.overflow, 0..) |*char, i| {
        //     if (char == 0)
        // }
        // self.overflow[]
    }

    pub fn setCharStateAt(self: *WordState, char_idx: usize, char_state: CharState) !void {
        if (!self.charIndexValid(char_idx)) return error.IndexOutOfBounds;
        self.char_states[char_idx] = char_state;
    }

    pub fn init(allocator: std.mem.Allocator, word_slice: []const u8) !WordState {
        const chars_state: []CharState = try allocator.alloc(CharState, word_slice.len);
        @memset(chars_state, .toComplete);

        return WordState{
            .word_slice = word_slice,
            .char_states = chars_state,
            .overflow = [_]u8{0} ** MAX_CHARS_OVERFLOW,
        };
    }

    pub fn deinit(self: *WordState, allocator: std.mem.Allocator) void {
        allocator.free(self.char_states);
    }

    pub fn updateCharAt(self: *WordState, index: usize, typed_char: u8) !usize {
        if (index < self.word_slice.len) {
            // Update character state within word bounds
            if (self.word_slice[index] == typed_char) {
                self.char_states[index] = .valid;
            } else {
                self.char_states[index] = .invalid;
            }
            return 1;
        } else {
            // Overflow case - increment overflow counter
            // const overflow_idx = index - self.word_slice.len;
            const overflow_idx = self.getFilledOverFlowLen();
            if (overflow_idx >= MAX_CHARS_OVERFLOW - 1) return error.MaxOverflowReached;
            self.overflow[overflow_idx] = typed_char;
            return 0;
        }
    }

    pub fn print(self: WordState) void {
        for (self.word_slice, 0..) |char, i| {
            const char_color = switch (self.char_states[i]) {
                .toComplete => Color.gray,
                .valid => Color.correct,
                .invalid => Color.error_fg,
            };
            color.printColoredChar(char_color, char);
        }

        // Print overflow characters if any
        for (0..self.overflow) |_| {
            color.printColoredChar(.error_bg, 'X'); // Placeholder for overflow
        }
    }
};
const std = @import("std");
const color = @import("color.zig");
const word_state = @import("word_state.zig");
const words_state = @import("words_state.zig");
const Color = color.Color;
const WordState = word_state.WordState;
const CharState = word_state.CharState;
const WordsState = words_state.WordsState;

pub const Printer = struct {
    words_state_ptr: *const WordsState,

    pub fn printBackSpace() void {}
    pub fn printOverflow() void {}

    pub fn printChar(char_color: Color, char: u8) void {
        std.debug.print("{s}{c}{s}", .{ char_color.toString(), char, Color.reset.toString() });
    }

    pub fn printWord(word_state_val: WordState, force_color: ?Color) void {
        for (word_state_val.word_slice, 0..) |char, char_idx| {
            if (force_color) |char_color| {
                printChar(char_color, char);
            } else {
                const char_color: Color = word_state_val.char_states[char_idx].toColor();
                printChar(char_color, char);
            }
        }
    }

    pub fn printCharAt(self: *const Printer, word_idx: usize, char_idx: usize, input: u8) void {
        if (word_idx < self.words_state_ptr.word_slices.len and char_idx < self.words_state_ptr.word_slices[word_idx].len) {
            const char_state: CharState = self.words_state_ptr.word_states[word_idx].char_states[char_idx];
            const char_color: Color = char_state.toColor();
            if (char_state == .invalid) {
                printChar(char_color, input);
            } else {
                printChar(char_color, self.words_state_ptr.word_slices[word_idx][char_idx]);
            }
        }
    }

    pub fn printBackspace(self: *const Printer, word_idx: usize, char_idx: usize) void {
        if (word_idx < self.words_state_ptr.word_slices.len and char_idx < self.words_state_ptr.word_slices[word_idx].len) {
            const original_char = self.words_state_ptr.word_slices[word_idx][char_idx];
            std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), original_char, Color.reset.toString() });
        }
    }

    pub fn printJumpToPrecedentWordAndReturnNewCharIndex(self: *const Printer, word_idx: usize, char_idx: usize) !usize {
        if (self.words_state_ptr.getWordState(word_idx - 1)) |p_word_state| {
            var offset_idx = char_idx;

            const p_offset_set = p_word_state.word_slice.len - p_word_state.getLastCharIdxToFill();
            offset_idx += p_offset_set;
            offset_idx += 1;
            std.debug.print("\x1b[{}D", .{offset_idx});
            return p_word_state.getLastCharIdxToFill();
        } else |e| {
            return e;
        }
    }

    pub fn printJumpToNextWord(self: *const Printer, word_idx: usize, char_idx: usize) void {
        if (word_idx > self.words_state_ptr.word_slices.len) return;
        const remaining_chars = self.words_state_ptr.word_slices[word_idx].len - char_idx;
        if (remaining_chars > 0) {
            std.debug.print("\x1b[{}C", .{remaining_chars});
        }
        std.debug.print("\x1b[1C", .{}); // skip the space
    }

    pub fn printGrayedSentence(self: *const Printer) void {
        for (self.words_state_ptr.word_states, 0..) |word_state_val, word_idx| {
            printWord(word_state_val, .gray);
            // print the space after the word
            if (word_idx < self.words_state_ptr.word_slices.len - 1)
                printChar(.gray, ' ');
        }
    }

    pub fn init(words_state_ptr: *const WordsState) Printer {
        return Printer{
            .words_state_ptr = words_state_ptr,
        };
    }

    pub fn newPrint(self: *const Printer) void {
        std.debug.print("\x1b[2K\x1b[G", .{}); // Clear entire line and go to beginning
        for (self.words_state_ptr.word_states) |word_state_val| {
            printWord(word_state_val, null);
            printChar(.gray, ' ');
        }
        std.debug.print("\x1b[u", .{}); // Restore cursor position
    }

    pub fn printIndexes(self: *const Printer, word_idx: usize, char_idx: usize) void {
        std.debug.print("\x1b[s", .{}); // Save cursor position
        std.debug.print("\x1b[1;1H", .{}); // Move to second line, first column
        std.debug.print("\x1b[K", .{}); // Clear the line
        std.debug.print("w{}-c{} : ", .{ word_idx, char_idx });
        for (self.words_state_ptr.word_states, 0..) |*word_state_val, w_idx| {
            std.debug.print("[{}, {}, {}, {}]  ", .{ w_idx, word_state_val.word_slice.len, word_state_val.getLastCharIdxToFill(), word_state_val.getFilledOverFlowLen() });
        }
        std.debug.print("\x1b[u", .{}); // Restore cursor position
    }
};
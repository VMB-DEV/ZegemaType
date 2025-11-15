const std = @import("std");

const color = @import("color.zig");
const Color = color.Color;
const word_state = @import("word_state.zig");
const WordState = word_state.WordState;
const CharState = word_state.CharState;
const words_state = @import("words_state.zig");
const WordsState = words_state.WordsState;

pub const Printer = struct {
    words_state_ptr: *const WordsState,
    start_time_ms: i64,

    pub fn printChar(char_color: Color, char: u8) void {
        std.debug.print("{s}{c}{s}", .{ char_color.toString(), char, Color.reset.toString() });
    }

    pub fn printWord(word_state_val: WordState, force_color: ?Color) void {
        for (word_state_val.word_slice, 0..) |char, char_idx| {
            if (char_idx > word_state_val.word_slice.len - 1)  break;
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

    pub fn printOverflow(self: *const Printer, word_idx: usize, input: u8) void {
        if (word_idx < self.words_state_ptr.word_slices.len and self.words_state_ptr.word_states[word_idx].getFilledOverFlowLen() > 0) {
            printChar(.error_bg, input);
            Ansi.saveCursorPosition();
            Ansi.hideCursor();
            var offset: usize = 0;
            for (self.words_state_ptr.word_states, 0..) |word_state_val, word_idx_val| {
                if (word_idx_val <= word_idx) continue;
                printChar(.gray, ' ');
                printWord(word_state_val, .gray);
                offset += 1 + word_state_val.word_slice.len;
            }
            printChar(.gray, ' ');
            Ansi.restorCursorPosition();
            Ansi.showCursor();
        }
    }

    pub fn printBackspace(self: *const Printer, word_idx: usize, char_idx: usize) void {
        if (word_idx < self.words_state_ptr.word_slices.len and self.words_state_ptr.word_states[word_idx].getFilledOverFlowLen() > 0) {
            std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), ' ', Color.reset.toString() });
        } else if (word_idx < self.words_state_ptr.word_slices.len and char_idx < self.words_state_ptr.word_slices[word_idx].len) {
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
            .start_time_ms = 0,
        };
    }

    pub fn newPrint(self: *const Printer) void {
        std.debug.print("\x1b[2K\x1b[G", .{}); // Clear entire line and go to beginning
        for (self.words_state_ptr.word_states) |word_state_val| {
            printWord(word_state_val, null);
            printChar(.gray, ' ');
        }
        Ansi.restorCursorPosition();
    }

    pub fn printIndexes(self: *const Printer, word_idx: usize, char_idx: usize) void {
        Ansi.saveCursorPosition();
        std.debug.print("\x1b[1;1H", .{}); // Move to second line, first column
        std.debug.print("\x1b[K", .{}); // Clear the line
        std.debug.print("w{}-c{}-o{}: ", .{ word_idx, char_idx,  self.words_state_ptr.word_states[word_idx].getFilledOverFlowLen()});
        for (self.words_state_ptr.word_states, 0..) |*word_state_val, w_idx| {
            std.debug.print("[{}, {}, {}, {}]  ", .{ w_idx, word_state_val.word_slice.len, word_state_val.getLastCharIdxToFill(), word_state_val.getFilledOverFlowLen() });
        }
        Ansi.restorCursorPosition();
    }

    pub fn printEnd(self: *const Printer) void {
        std.debug.print("\n", .{});
        std.debug.print("wpm: {s}{d}{s}", .{ Color.blue.toString(), self.getWPM(), Color.reset.toString() });
        std.debug.print("\t---\t", .{});
        std.debug.print("time: {d:.1} s", .{ self.getChronoS()});
        std.debug.print("\n", .{});
    }
    pub fn getWPM(self: *const Printer) i64 {
        const ms_time: i64 = self.getChronoMs();
        const numberOfCorrectWords: f64 = @as(f64, @floatFromInt(self.words_state_ptr.getValidWords()));
        const numberOfParialWords: f64 = @as(f64, @floatFromInt(self.words_state_ptr.getPartiallyValidWords()));
        const avgCharsPerWords: f64 = self.words_state_ptr.getAvgCharPerWord();
        if (numberOfCorrectWords == 0) return 0.0;

        const minutes: f64 = @as(f64, @floatFromInt(ms_time)) / @as(f64, std.time.ms_per_min);
        const wpm: f64 = numberOfCorrectWords / minutes;
        const awpm: f64 = (avgCharsPerWords / words_state.AVG_CHAR_PER_WORD) * wpm;
        const pwpm: f64 = numberOfParialWords / minutes;
        const mix = ((wpm * 5) + (awpm) + (pwpm * 3)) / 9;

        return @intFromFloat(mix);
    }
    pub fn startChrono(self: *Printer) void {
        self.start_time_ms = std.time.milliTimestamp();
    }
    pub fn getChronoS(self: *const Printer) f64 {
        const ms: f64 = @floatFromInt(self.getChronoMs());
        return ms / 1000.0;
    }
    pub fn getChronoMs(self: *const Printer) i64 {
        return std.time.milliTimestamp() - self.start_time_ms;
    }
};

pub const Ansi = struct {
    pub fn saveCursorPosition() void {
        std.debug.print("\x1b[s", .{});
    }
    pub fn restorCursorPosition() void {
        std.debug.print("\x1b[u", .{});
    }
    pub fn hideCursor() void {
        std.debug.print("\x1b[?25l", .{});
    }
    pub fn showCursor() void {
        std.debug.print("\x1b[?25h", .{});
    }
};
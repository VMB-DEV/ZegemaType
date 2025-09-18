const std = @import("std");
const posix = std.posix;

// Color enum with methods
const Color = enum {
    gray,
    correct,
    error_fg,
    error_bg,
    reset,
    gray_underline,
    correct_underline,
    error_fg_underline,
    error_bg_underline,

    fn toString(self: Color) []const u8 {
        return switch (self) {
            .gray => "\x1b[38;2;150;150;150m",
            .correct => "\x1b[38;2;226;183;20m",
            .error_fg => "\x1b[38;2;202;71;84m",
            .error_bg => "\x1b[48;2;156;51;63m",
            .reset => "\x1b[0m",
            .gray_underline => "\x1b[4;38;2;150;150;150m",
            .correct_underline => "\x1b[4;38;2;226;183;20m",
            .error_fg_underline => "\x1b[4;38;2;202;71;84m",
            .error_bg_underline => "\x1b[4;48;2;156;51;63m",
        };
    }
};

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

fn printGrayedWords(words: [][]const u8) void {
    for (words, 0..) |word, i| {
        printColoredString(Color.gray, word);
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
    for (words) |word| {
        try std.testing.expect(word.len > 0);

        // Verify the word exists in ALL_WORDS
        var found = false;
        for (ALL_WORDS) |dict_word| {
            if (std.mem.eql(u8, word, dict_word)) {
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
        if (!std.mem.eql(u8, w1, w2)) {
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
    for (words) |word| {
        _ = word.len; // Should not crash
        _ = word[0]; // Should not crash if word is non-empty
    }
}

pub fn getRandomWords(allocator: std.mem.Allocator, n: usize) ![][]const u8 {
    // Generate random seed and create RNG (classic PNRG instead of CSPRNG)
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random: std.Random = prng.random();    // Calculate total length for cursor positioning

    const result: [][]const u8 = try allocator.alloc([]const u8, n);
    for (result, 0..) |_, i| {
        const random_index = random.intRangeAtMost(usize, 0, ALL_WORDS.len - 1);
        result[i] = ALL_WORDS[random_index];
    }
    return result;
}

const CharState = enum {
    toComplete,
    valid,
    invalid,

    fn toColor(self: CharState) Color {
        return switch (self) {
            .toComplete => .gray,
            .valid => .correct,
            .invalid => .error_fg_underline,
        };
    }
};

const WordState = struct {
    word_slice: []const u8,
    char_states: []CharState,
    overflow: [10]u8,


    pub fn getFilledOverFlowLen(self: *WordState) usize {
        var overflow_count: usize = 0;
        for (self.overflow) |char| {
            if (char != 0) overflow_count += 1;
        }
        return overflow_count;
    }
    pub fn getLastCharIdxToFill() usize {

    }
    // pub fn removeLastOverFlowChar(self: *WordsState) usize {
    //
    // }
    pub fn init(allocator: std.mem.Allocator, word_slice: []const u8) !WordState {
        const chars_state: []CharState = try allocator.alloc(CharState, word_slice.len);
        @memset(chars_state, .toComplete);

        return WordState{
            .word_slice = word_slice,
            .char_states = chars_state,
            .overflow = [_]u8{0} ** 10,
        };
    }

    pub fn deinit(self: *WordState, allocator: std.mem.Allocator) void {
        allocator.free(self.char_states);
    }

    pub fn updateCharAt(self: *WordState, index: usize, typed_char: u8) void {
        if (index < self.word_slice.len) {
            // Update character state within word bounds
            if (self.word_slice[index] == typed_char) {
                self.char_states[index] = .valid;
            } else {
                self.char_states[index] = .invalid;
            }
        } else {
            // Overflow case - increment overflow counter
            const overflow_idx = index - self.word_slice.len;
            if (overflow_idx > 9) return;
            self.overflow[overflow_idx] = typed_char;
        }
    }

    pub fn print(self: WordState) void {
        for (self.word_slice, 0..) |char, i| {
            const color = switch (self.char_states[i]) {
                .toComplete => Color.gray,
                .valid => Color.correct,
                .invalid => Color.error_fg,
            };
            printColoredChar(color, char);
        }

        // Print overflow characters if any
        for (0..self.overflow) |_| {
            printColoredChar(.error_bg, 'X'); // Placeholder for overflow
        }
    }
};

const Printer = struct {
    words_state_ptr: *const WordsState,

    pub fn printBackSpace() void {}
    pub fn printOverflow() void {}
    // pub fn printWord(self: *Printer, word_idx: usize, force_color: ?Color = null) void {
    // fn printWord(self: *Printer, word_slice: []const u8, force_color: ?Color) void {
    // pub fn printChar(self: *const Printer, color: Color, char: u8) void {
    pub fn printChar(color: Color, char: u8) void {
        std.debug.print("{s}{c}{s}", .{ color.toString(), char, Color.reset.toString() });
    }
    pub fn printWord(word_state: WordState, force_color: ?Color) void {
        for (word_state.word_slice, 0..) |char, char_idx| {
            if (force_color) |color| {
                printChar(color, char);
            } else {
                const color: Color = word_state.char_states[char_idx].toColor();
                printChar(color, char);
            }
        }
    }

    pub fn printCharAt(self: *const Printer, word_idx: usize, char_idx: usize, input: u8) void {
        if (word_idx < self.words_state_ptr.word_slices.len and char_idx < self.words_state_ptr.word_slices[word_idx].len) {
            const char_state: CharState = self.words_state_ptr.word_states[word_idx].char_states[char_idx];
            const color: Color = char_state.toColor();
            if (char_state == .invalid) {
                printChar(color, input);
            } else {
                printChar(color, self.words_state_ptr.word_slices[word_idx][char_idx]);
            }
        }
    }

    pub fn printBackspace(self: *const Printer, word_idx: usize, char_idx: usize) void {
        if (word_idx < self.words_state_ptr.word_slices.len and char_idx < self.words_state_ptr.word_slices[word_idx].len) {
            const original_char = self.words_state_ptr.word_slices[word_idx][char_idx];
            std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), original_char, Color.reset.toString() });
        }
    }

    pub fn printJumpToPrecedentWord(self: *const Printer, word_idx: usize, char_idx: usize) void {
        _ = char_idx;
        _ = word_idx;
        _ = self;
        std.debug.print("\x1b[{}D", .{2});
    }

    pub fn printJumpToNextWord(self: *const Printer, word_idx: usize, char_idx: usize) void {
        if (word_idx >= self.words_state_ptr.word_slices.len) return;
        const remaining_chars = self.words_state_ptr.word_slices[word_idx].len - char_idx;
        if (remaining_chars > 0) {
            std.debug.print("\x1b[{}C", .{remaining_chars});
        }
        std.debug.print("\x1b[1C", .{}); // skip the space
    }

    pub fn printGrayedSentence(self: *const Printer) void {
        for (self.words_state_ptr.word_states, 0..) |word_state, word_idx| {
            printWord(word_state, .gray);
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
};

const WordsState = struct {
    word_states: []WordState,
    word_slices: [][]const u8,
    total_length: usize,

    pub fn init(allocator: std.mem.Allocator, number_of_words: usize) !WordsState {
        const word_slices: [][]const u8 = try getRandomWords(allocator, number_of_words);
        errdefer allocator.free(word_slices);
        const word_states: []WordState = try allocator.alloc(WordState, number_of_words);
        errdefer allocator.free(word_states);

        for (word_states, 0..) |*word_state, i| {
            word_state.* =  try WordState.init(allocator, word_slices[i]);
        }

        return WordsState{
            .word_states = word_states,
            .word_slices = word_slices,
            .total_length = blk: {
                var l: usize = 0;
                // getting all the characters
                for (word_slices) |word_slice| { l += word_slice.len ;}
                // getting all the spaces
                l += word_states.len - 1;
                break :blk l;
            },
        };
    }
    pub fn deinit(self: *WordsState, allocator: std.mem.Allocator) void {
        for (self.word_states) |*word_state| {
            word_state.deinit(allocator);
        }
        allocator.free(self.word_states);
        allocator.free(self.word_slices);
    }

    pub fn newPrint(self: *const WordsState, word_idx: usize, char_idx: usize) void {
        if (word_idx < self.word_slices.len and char_idx < self.word_slices[word_idx].len) {
            const color: Color = switch (self.word_states[word_idx].char_states[char_idx]) {
                .toComplete => .gray,
                .valid => .correct,
                .invalid => .error_fg,
            };
            printColoredChar(color, self.word_slices[word_idx][char_idx]);
        }
    }
    pub fn print(self: *const WordsState, word_idx: usize, char_idx: usize) void {
        std.debug.print("\x1b[?25l", .{}); // Hide cursor

        // Clear entire line and go to beginning
        std.debug.print("\x1b[2K\x1b[G", .{});

        // Print all words with correct colors
        for (self.word_slices, 0..) |word_slice, word_idx_l| {
            for (word_slice, 0..) |char, char_idx_l| {
                const color: Color = switch (self.word_states[word_idx_l].char_states[char_idx_l]) {
                    .toComplete => .gray,
                    .valid => .correct,
                    .invalid => .error_fg,
                };
                printColoredChar(color, char);
            }

            // Print overflow characters for current word
            if (word_idx_l == word_idx) {
                for (self.word_states[word_idx_l].overflow) |overflow_char| {
                    if (overflow_char != 0) {
                        printColoredChar(.error_bg, overflow_char);
                    }
                }
            }

            if (word_idx_l < self.word_slices.len - 1) {
                printColoredChar(Color.gray, ' ');
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
            for (word_slice) | char | {
                // const color: Color = switch (self.word_states[word_idx_l].char_states[char_idx_l]) {
                //     .toComplete => .gray,
                //     .valid => .correct,
                //     .invalid => .error_fg,
                // };
                printColoredChar(.gray, char);
            }
            if (word_idx_l < self.word_slices.len - 1) {
                printColoredChar(Color.gray, ' ');
            }
        }
        //
        // var cursor_pos: usize = char_idx;
        // for (0..word_idx) |i| {
        //     cursor_pos += self.word_slices[i].len;
        //     if (i < word_idx) cursor_pos += 1; // Add space after each completed word
        //   }
        // std.debug.print("\x1b[{}D", .{self.total_length - cursor_pos});
        // std.debug.print("\x1b[?25h", .{}); // Show cursor
    }
    // pub fn print(self: *const WordsState, word_idx: usize, char_idx: usize) void {
    //         // std.debug.print("\x1b[?25l", .{}); // Hide cursor
    //         // \x1b[2K clear the entire line \x1b[G mvoe the cursor to the left
    //     // std.debug.print("\x1b[2K", .{});
    //     // \x1b[1K - Clear from beginning of line to cursor
    //     // \x1b[0K or \x1b[K - Clear from cursor to end of lin
    //     // if (char_idx > 2) {
    //     // std.debug.print("\x1b[K", .{});
    //     // }
    //     // else {
    //     std.debug.print("\x1b[2K\x1b[G", .{});
    //     // }
    //
    //     // const c1: Color = switch (self.word_states[word_idx].char_states[char_idx]) {
    //     //     .toComplete => .gray,
    //     //     .valid => .correct,
    //     //     .invalid => .error_fg,
    //     // };
    //     // printColoredChar(c1, self.word_states[word_idx].word_slice[char_idx]);
    //     for (self.word_slices, 0..) |word_slice, word_idx_l| {
    //         // if (word_idx > 0 and word_idx > word_idx_l) continue;
    //         for (word_slice, 0..) | char, char_idx_l | {
    //             // if (char_idx > 0 and char_idx > char_idx_l) continue;
    //             // if (char_idx_l < char_idx) continue;
    //             const color: Color = switch (self.word_states[word_idx_l].char_states[char_idx_l]) {
    //                 .toComplete => .gray,
    //                 .valid => .correct,
    //                 .invalid => .error_fg,
    //             };
    //             printColoredChar(color, char);
    //         }
    //         if (word_idx_l < self.word_slices.len - 1) {
    //             printColoredChar(Color.gray, ' ');
    //         }
    //     }
    //
    //     var cursor_pos: usize = char_idx;
    //     for (0..word_idx) |i| {
    //         cursor_pos += self.word_slices[i].len;
    //         if (i < word_idx) cursor_pos += 1; // Add space after each completed word
    //       }
    //     std.debug.print("\x1b[{}D", .{self.total_length - cursor_pos});
    //     std.debug.print("\x1b[?25h", .{}); // Show cursor
    // }
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
pub fn main() !void {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator: std.mem.Allocator = arena.allocator();

    try disableEcho();
    defer enableEcho() catch {};

    const number_of_words: comptime_int = 3;
    const words_state: WordsState = try WordsState.init(allocator, number_of_words);
    const printer: Printer = Printer.init(&words_state);


    var buffer: [1]u8 = undefined;
    var esc_count: usize = 0;
    var word_idx: usize = 0;
    var char_idx: usize = 0;

    // words_state.print(word_idx, char_idx);
    // words_state.print0();
    printer.printGrayedSentence();
    std.debug.print("\x1b[{}D", .{words_state.total_length});

    while (esc_count < 2) {
        const bytes_read = try std.fs.File.stdin().read(&buffer);
        if (bytes_read == 0) break;
        const byte = buffer[0];

        // escape key
        if (byte == '\x1b') {
            esc_count += 1;
        }
        // backspace
        // if (byte == '\x7f') {
        // if (byte == '\x08') {
        if (byte == 127) {
            // if (words_state.word_states[word_idx].overflow.len > 0) {
            if (words_state.word_states[word_idx].getFilledOverFlowLen() > 0) {
                // char_idx -= 1;
                // printer.printBackspace(word_idx, char_idx);
                // overflow_chars -= 1;
                // std.debug.print("\x1b[1D \x1b[1D", .{});
            } else if (char_idx > 0) {
                char_idx -= 1;
                printer.printBackspace(word_idx, char_idx);
                // char_in_word -= 1;
                // const target_char = words[current_word][char_in_word];
                // std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), target_char, Color.reset.toString() });
            } else if (char_idx <= 0) {
                if (word_idx <= 0) {
                    continue;
                } else {
                    printer.printJumpToPrecedentWord(word_idx, char_idx);
                    word_idx -= 1;
                    // char_idx = words_state.word_states[word_idx].word_slice.len + words_state.word_states[word_idx].getFilledOverFlowLen();
                    char_idx = words_state.word_states.getLastCharIdxToFill() ;
                }
            }
            continue;
        }
        if (byte == ' ') {
            // words_state.newPrint(word_idx, char_idx);
            // if (l)
            if (word_idx < words_state.word_slices.len - 1) {
//                 // Skip remaining chars in current word and the space
//                 const remaining_chars = words[current_word].len - char_in_word;
//                 if (remaining_chars > 0) {
//                     std.debug.print("\x1b[{}C", .{remaining_chars});
//                 }
//                 std.debug.print("\x1b[1C", .{}); // skip the space
//
                printer.printJumpToNextWord(word_idx, char_idx);
                word_idx += 1;
                char_idx = 0;
            }
            // printColoredChar(.gray, ' ');
            // char_idx = 0;
            // word_idx += 1;
        } else {
            // if (byte == words_state.word_states[word_idx].word_slice[char_idx]) {
            words_state.word_states[word_idx].updateCharAt(char_idx, byte);
            printer.printCharAt(word_idx, char_idx, byte);
            // words_state.newPrint(word_idx, char_idx);
            char_idx += 1;
        }
    }
}

// pub fn main2() !void {
//     var arena  = std.heap.ArenaAllocator.init(std.heap.page_allocator);
//     defer arena.deinit();
//
//     const allocator = arena.allocator();
//
//     try disableEcho();
//     defer enableEcho() catch {};
//
//     const numberOfWords: comptime_int = 10;
//     const words: [][]const u8 = try getRandomWords(allocator, numberOfWords);
//     // const charsState: *[]
//     printGrayedWords(words);
//
//     var total_len: usize = 0;
//     for (words) |word| total_len += word.len;
//     total_len += words.len - 1; // spaces between words
//     std.debug.print("\x1b[{}D", .{total_len});
//
//     var buffer: [1]u8 = undefined;
//     var current_word: usize = 0;
//     var char_in_word: usize = 0;
//     var overflow_chars: usize = 0;
//
//     while (current_word < words.len) {
//         const bytes_read = try std.fs.File.stdin().read(&buffer);
//         if (bytes_read == 0) break;
//         const byte = buffer[0];
//
//         // Handle backspace
//         if (byte == '\x7f') {
//             if (overflow_chars > 0) {
//                 overflow_chars -= 1;
//                 std.debug.print("\x1b[1D \x1b[1D", .{});
//             } else if (char_in_word > 0) {
//                 char_in_word -= 1;
//                 const target_char = words[current_word][char_in_word];
//                 std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), target_char, Color.reset.toString() });
//             }
//             continue;
//         }
//
//         // Handle space - move to next word
//         if (byte == ' ') {
//             if (current_word < words.len - 1) {
//                 // Skip remaining chars in current word and the space
//                 const remaining_chars = words[current_word].len - char_in_word;
//                 if (remaining_chars > 0) {
//                     std.debug.print("\x1b[{}C", .{remaining_chars});
//                 }
//                 std.debug.print("\x1b[1C", .{}); // skip the space
//
//                 current_word += 1;
//                 char_in_word = 0;
//                 overflow_chars = 0;
//             }
//             continue;
//         }
//         //todo: enter key behavior
//
//         // Handle regular character input
//         if (char_in_word < words[current_word].len) {
//             // Within word bounds
//             if (byte == words[current_word][char_in_word]) {
//                 printColoredChar(.correct, byte);
//             } else {
//                 printColoredChar(.error_fg, byte);
//             }
//             char_in_word += 1;
//         } else {
//             // Overflow - beyond word length
//             printColoredChar(.error_bg, byte);
//             overflow_chars += 1;
//
//             // // Move to beginning of line, clear entire line, and reprint everything
//             // std.debug.print("\x1b[2K\x1b[G", .{}); // Clear entire line and move to beginning
//             //
//             // var idx_to_substract: usize = 0;
//             // Reprint all words with current progress
//             for (words, 0..) |word, word_idx| {
//                 if (word_idx > 0) printColoredChar(.gray, ' ');
//
//                 if (word_idx < current_word) {
//                     // Already completed words - show in correct color
//                     printColoredString(.correct, word);
//                 } else if (word_idx == current_word) {
//                     // Current word - show typed part + overflow + remaining
//                     for (word[0..char_in_word]) |c| {
//                         printColoredChar(.correct, c);
//                     }
//                     // Show overflow characters that were typed
//                     for (0..overflow_chars) |_| {
//                         printColoredChar(.error_bg, 'X'); // Placeholder for overflow chars
//                     }
//                     // Show remaining part of current word in gray
//                     if (char_in_word < word.len) {
//                         printColoredString(.gray, word[char_in_word..]);
//                     }
//                 } else {
//                     // Future words in gray
//                     printColoredString(.gray, word);
//                 }
//             }
//             std.debug.print("\x1b[{}D", .{total_len});
//         }
//     }
// }

pub const ALL_WORDS = [_][]const u8{ "i", "present", "my", "zig", "first", "program", "all", "software", "ai", "none", "all", "fast", "blazingly", "update", "upgrade", "improve", "understanding", "publication", "contact", "note", "hobby", "intervention", "discovery", "volcano", "trait", "balance", "criminal", "nerve", "dialect", "mutual", "terrace", "post", "lace", "tile", "tie", "exploit", "ancestor", "advance", "exchange", "building", "watch", "appreciate", "detective", "disagreement", "excavate", "experienced ", };
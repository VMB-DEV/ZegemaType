const std = @import("std");
const posix = std.posix;
const color = @import("color.zig");
const word_state_file = @import("word_state.zig");
const words_state_file = @import("words_state.zig");
const printer = @import("printer.zig");

const Color = color.Color;
const WordState = word_state_file.WordState;
const CharState = word_state_file.CharState;
const WordsState = words_state_file.WordsState;
const Printer = printer.Printer;

//todo : fix the overflow writing
//todo : fix the double keystroke like ctrl + backspace (bug when deleting letter by letter du to the fact ctrl is considered as an input)
//todo : calculate speed
//todo : display speed with random sentence
//todo : find a way to display this

test "getRandomWords returns correct number of words" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words = try words_state_file.getRandomWords(allocator, 5);
    try std.testing.expect(words.len == 5);

    const single_word = try words_state_file.getRandomWords(allocator, 1);
    try std.testing.expect(single_word.len == 1);

    const many_words = try words_state_file.getRandomWords(allocator, 50);
    try std.testing.expect(many_words.len == 50);
}

test "getRandomWords returns valid word pointers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words = try words_state_file.getRandomWords(allocator, 10);

    // Check each word pointer is valid and points to a word from ALL_WORDS
    for (words) |word| {
        try std.testing.expect(word.len > 0);

        // Verify the word exists in ALL_WORDS
        var found = false;
        for (words_state_file.ALL_WORDS) |dict_word| {
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

    const words = try words_state_file.getRandomWords(allocator, 0);
    try std.testing.expect(words.len == 0);
}

test "getRandomWords produces different results across calls" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const words1 = try words_state_file.getRandomWords(allocator, 10);
    const words2 = try words_state_file.getRandomWords(allocator, 10);

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
    const words = try words_state_file.getRandomWords(allocator, 3);
    try std.testing.expect(words.len == 3);

    // Verify we can access all word data
    for (words) |word| {
        _ = word.len; // Should not crash
        _ = word[0]; // Should not crash if word is non-empty
    }
}

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

fn isValidPunct(byte: u8) bool {
    return std.mem.indexOfScalar(u8, ".,!?;:-'\"", byte) != null;
}

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator: std.mem.Allocator = arena.allocator();

    try disableEcho();
    defer enableEcho() catch {};

    const number_of_words: comptime_int = 3;
    const words_state: WordsState = try WordsState.init(allocator, number_of_words);
    const printer_instance: Printer = Printer.init(&words_state);


    var buffer: [1]u8 = undefined;
    var esc_count: usize = 0;
    var word_idx: usize = 0;
    var char_idx: usize = 0;

    // words_state.print(word_idx, char_idx);
    // words_state.print0();
    printer_instance.printGrayedSentence();
    std.debug.print("\x1b[{}D", .{words_state.total_length});

    while (esc_count < 2) {
        printer_instance.printIndexes(word_idx, char_idx);
        const bytes_read = try std.fs.File.stdin().read(&buffer);
        if (bytes_read == 0) break;
        const byte = buffer[0];

        // escape key
        if (byte == '\x1b') {
            esc_count += 1;
        }
        // backspace
        if (byte == 127) {
            // if (byte == '\x7f') {
            // if (byte == '\x08') {
                // if (words_state.word_states[word_idx].overflow.len > 0) {
            if (words_state.word_states[word_idx].getFilledOverFlowLen() > 0) {
                try words_state.removeLastOverflow(word_idx);
                // char_idx -= 1;
                // printer_instance.printBackspace(word_idx, char_idx);
                // overflow_chars -= 1;
                // std.debug.print("\x1b[1D \x1b[1D", .{});
            } else if (char_idx > 0) {
                char_idx -= 1;
                printer_instance.printBackspace(word_idx, char_idx);
                printer_instance.printIndexes(word_idx, char_idx);
                try words_state.setCharStateAt(word_idx, char_idx, .toComplete);
                // if (words_state.useWordState(word_idx) catch null) |words_state| { words_state.char_states[char_idx] = .toComplete; }
                // words_state.getWordState(word_idx).
                continue;
                // char_in_word -= 1;
                // const target_char = words[current_word][char_in_word];
                // std.debug.print("\x1b[1D{s}{c}{s}\x1b[1D", .{ Color.gray.toString(), target_char, Color.reset.toString() });
            } else if (char_idx == 0) {
                if (word_idx >= 1) {
                    char_idx = printer_instance.printJumpToPrecedentWordAndReturnNewCharIndex(word_idx, char_idx) catch {
                        continue;
                    };
                    word_idx -= 1;
                    printer_instance.printIndexes(word_idx, char_idx);
                    continue;
                } else if (word_idx == 0) {
                    continue;
                }
                // const new_char_idx = if (words_state.getWordState(word_idx)) |words_state| words_state.getLastCharIdxToFill() else |_| 0;
                // const new_char_idx = words_state.getLastCharIdxToFill(word_idx);
                // if (printer_instance.printJumpToPrecedentWordAndReturnNewCharIndex(word_idx, char_idx)) |new_char_idx| {
                // } else |_| {
                //     continue;
                // }
            } else if (char_idx < 0) {
                //todo: throw an error ?
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
                printer_instance.printJumpToNextWord(word_idx, char_idx);
                word_idx += 1;
                char_idx = 0;
                printer_instance.printIndexes(word_idx, char_idx);
                continue;
            }
            // printColoredChar(.gray, ' ');
            // char_idx = 0;
            // word_idx += 1;
        } else if (std.ascii.isAlphabetic(byte) or isValidPunct(byte)) {
            // const wrd_state_ptr: ?* const WordState= words_state.getWordState(word_idx) catch null;
            // if (wrd_state_ptr) {
            const indexOverflow: usize = words_state.word_states[word_idx].updateCharAt(char_idx, byte);
            printer_instance.printCharAt(word_idx, char_idx, byte);
            char_idx += indexOverflow;
            // }
            continue;
        }
    }
}
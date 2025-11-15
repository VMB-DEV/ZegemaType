const std = @import("std");

// Color enum with methods
pub const Color = enum {
    gray,
    correct,
    error_fg,
    error_bg,
    reset,
    gray_underline,
    correct_underline,
    error_fg_underline,
    error_bg_underline,

    pub fn toString(self: Color) []const u8 {
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

pub fn printColoredChar(color: Color, char: u8) void {
    std.debug.print("{s}{c}{s}", .{ color.toString(), char, Color.reset.toString() });
}

pub fn printColoredString(color: Color, string: []const u8) void {
    std.debug.print("{s}{s}{s}", .{ color.toString(), string, Color.reset.toString() });
}

pub fn printGrayedWords(words: [][]const u8) void {
    for (words, 0..) |word, i| {
        printColoredString(Color.gray, word);
        if (i < words.len - 1) {
            printColoredChar(Color.gray, ' ');
        }
    }
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
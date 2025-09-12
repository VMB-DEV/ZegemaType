const std = @import("std");
const posix = std.posix;

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
    try disableEcho();
    defer enableEcho() catch {};

    const target = "Hello World";
    std.debug.print("\x1b[90m{s}\x1b[0m", .{target});
    std.debug.print("\x1b[11D", .{});

    var buffer: [1]u8 = undefined;
    var index: usize = 0;
    while (index < target.len) {
        const bytes_read = try std.fs.File.stdin().read(&buffer);
        if (bytes_read == 0) break;
        const byte = buffer[0];

        if (byte == 127) {
            if (index > 0) {
                index -= 1;
                std.debug.print("\x1b[1D\x1b[90m{c}\x1b[0m\x1b[1D", .{target[index]});
            }
            continue;
        }

        if (byte == target[index]) {
            std.debug.print("{c}", .{byte});
        } else {
            std.debug.print("\x1b[31m{c}\x1b[0m", .{byte});
        }
        index += 1;
    }
}

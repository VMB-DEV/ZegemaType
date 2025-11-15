# ZegemaType

Terminal-based typing speed test application written in Zig.


## Requirements

- Zig 0.16.0
- A terminal that supports ANSI escape sequences


## Usage

### Running with Zig Build

```bash
zig build run
```

### Running the Binary Directly

After building, you can run the executable directly:

```bash
./zig-out/bin/zegemaType
```

Or make it accessible from anywhere:

**Option 1: Add to PATH**
```bash
# Add to your shell configuration (~/.bashrc, ~/.zshrc, etc.)
export PATH="$PATH:/path/to/ZegemaType/zig-out/bin"

# Then run from anywhere
zegemaType
```

**Option 2: Create a symlink**
```bash
# Create a symlink in a directory that's already in your PATH
sudo ln -s /path/to/ZegemaType/zig-out/bin/zegemaType /usr/local/bin/zegemaType

# Then run from anywhere
zegemaType
```

### How to Use

1. When you start the application, a sentence with random words will appear in gray
2. Start typing the words as shown
3. Characters will be color-coded based on your accuracy:
4. Press `Space` to move to the next word
5. Press `Backspace` to correct mistakes
6. Press `Esc` twice to exit early
7. When you complete the sentence, your WPM and time will be displayed


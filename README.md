# ZegemaType
<img src="https://img.shields.io/badge/zig-0.16-F7A41D.svg?style=flat&labelColor=000000&logoColor=CAB96A&logo=data:image/svg%2bxml;base64,PHN2ZyByb2xlPSJpbWciIHZpZXdCb3g9IjAgMCAyNCAyNCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiBmaWxsPSIjRjdBNDFEIj48dGl0bGU+WmlnPC90aXRsZT48cGF0aCBkPSJtMjMuNTMgMS4wMi03LjY4NiAzLjQ1aC03LjA2bC0yLjk4IDMuNDUyaDcuMTczTC40NyAyMi45OGw3LjY4MS0zLjYwN2g3LjA2NXYtLjAwMmwyLjk3OC0zLjQ1LTcuMTQ4LS4wMDEgMTIuNDgyLTE0Ljl6TTAgNC40N3YxNC45MDFoMS44ODNsMi45OC0zLjQ1SDMuNDUxdi04aC45NDJsMi44MjQtMy40NUgwem0yMi4xMTcgMC0yLjk4IDMuNjA4aDEuNDEydjcuODQ0aC0uOTQybC0yLjk4IDMuNDVIMjRWNC40N2gtMS44ODN6Ii8+PC9zdmc+" alt="Slack">


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

<p align="center">
    <img src="https://github.com/VMB-DEV/ZegemaType/blob/main/.gitRes/typing.gif">
</p>

### How to Use

1. When you start the application, a sentence with random words will appear in gray
2. Start typing the words as shown
3. Characters will be color-coded based on your accuracy:
4. Press `Space` to move to the next word
5. Press `Backspace` to correct mistakes
6. Press `Esc` twice to exit early
7. When you complete the sentence, your WPM and time will be displayed


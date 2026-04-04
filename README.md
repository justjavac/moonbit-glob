# Glob

[![ci](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-glob/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-glob)

A small path-aware glob matcher for MoonBit.

## Supported Syntax

- `?` matches exactly one character
- `*` matches inside a single path segment
- `**` matches across path separators
- `is_valid_pattern` checks whether `[` and `]` are balanced

Bracket expressions such as `[abc]` are validated only; they are not matched
specially yet.

## Installation

```bash
moon update
moon add justjavac/glob
```

## Usage

```moonbit
assert_eq(glob("*.txt", "notes.txt"), true)
assert_eq(glob("src/*.mbt", "src/main.mbt"), true)
assert_eq(glob("src/*.mbt", "src/lib/main.mbt"), false)
assert_eq(glob("src/**/*.mbt", "src/lib/main.mbt"), true)
```

## Collection Helpers

```moonbit
let files = ["README.md", "src/main.mbt", "src/lib/util.mbt"]

assert_eq(glob_match_any("src/**", files), true)
assert_eq(
  glob_filter("src/**/*.mbt", files),
  ["src/lib/util.mbt"],
)
assert_eq(match_any_pattern(["*.md", "**/*.mbt"], "README.md"), true)
```

## Tested Docs

The package also ships with a concise tested README at
[`README.mbt.md`](./README.mbt.md).

## License

This project is licensed under the MIT License.

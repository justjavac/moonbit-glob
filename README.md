# Glob

[![ci](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-glob/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-glob)

A glob pattern matching library for MoonBit, supporting wildcard pattern
matching on file paths and strings.

## Supported Syntax

- `?` matches exactly one character
- `*` matches inside a single path segment
- `**` matches across path separators
- `is_valid_pattern` checks whether `[` and `]` are balanced

Bracket expressions such as `[abc]` are validated only; they are not matched
specially yet.

## Installation

```bash
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

## License

This project is licensed under the MIT License.

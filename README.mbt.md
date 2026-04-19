# Glob

[![ci](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/justjavac/moonbit-glob/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/codecov/c/github/justjavac/moonbit-glob/main?label=coverage)](https://codecov.io/gh/justjavac/moonbit-glob)

A small path-aware glob matcher for MoonBit.

It supports `?`, `*`, and `**`:

- `?` matches exactly one character
- `*` matches inside a single path segment
- `**` matches across path separators

Bracket expressions such as `[abc]` are only validated by
`@glob.is_valid_pattern`; they are not matched specially yet.

## Quick Start

```mbt check
///|
test {
  assert_eq(@glob.glob("*.txt", "notes.txt"), true)
  assert_eq(@glob.glob("src/*.mbt", "src/main.mbt"), true)
  assert_eq(@glob.glob("src/*.mbt", "src/lib/main.mbt"), false)
  assert_eq(@glob.glob("src/**/*.mbt", "src/lib/main.mbt"), true)
}
```

## Bulk Matching

```mbt check
///|
test {
  let files = ["README.md", "src/main.mbt", "src/lib/util.mbt"]
  assert_eq(@glob.glob_match_any("src/**", files), true)
  assert_eq(@glob.glob_filter("src/**/*.mbt", files), ["src/lib/util.mbt"])
  assert_eq(@glob.match_any_pattern(["*.md", "**/*.mbt"], "README.md"), true)
}
```

## Helpers

```mbt check
///|
test {
  assert_eq(@glob.is_valid_pattern("[abc]*.txt"), true)
  assert_eq(@glob.is_valid_pattern("[abc*.txt"), false)
  assert_eq(@glob.escape_glob("file?.txt"), "file\\?.txt")
}
```

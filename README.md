# Glob

A glob pattern matching library for MoonBit, supporting wildcard pattern
matching on file paths and strings.

## Features

- **Basic Wildcards**: Support for `*` (matches any characters) and `?` (matches
  single character)
- **Directory Traversal**: Support for `**` (matches across directory
  boundaries)
- **Path-Aware Matching**: Single `*` respects directory boundaries, `**`
  crosses them
- **Character Classes**: Basic validation for bracket expressions `[abc]`
  (validation only)
- **Escaping**: Utility to escape special characters for literal matching
- **Bulk Operations**: Functions to match against multiple paths or patterns

## Installation

```bash
moon update
moon add justjavac/glob
```

## Usage

```moonbit
// Match text files
let result = glob("*.txt", "readme.txt")
assert_eq(result, true)

// Single character wildcard
let result = glob("file?.log", "file1.log")
assert_eq(result, true)

// Cross-directory matching
let result = glob("**/*.mbt", "src/main.mbt")
assert_eq(result, true)
```

## Pattern Syntax

| Pattern | Description                                        | Example         | Matches                     | Doesn't Match            |
| ------- | -------------------------------------------------- | --------------- | --------------------------- | ------------------------ |
| `*`     | Matches any characters (except path separators)    | `*.txt`         | `file.txt`, `readme.txt`    | `dir/file.txt`           |
| `**`    | Matches any characters (including path separators) | `**/*.txt`      | `dir/file.txt`, `a/b/c.txt` | `file.py`                |
| `?`     | Matches exactly one character                      | `file?.txt`     | `file1.txt`, `fileA.txt`    | `file.txt`, `file12.txt` |
| `[abc]` | Character class (validation only)                  | `file[123].txt` | _validated syntax only_     | _not implemented_        |
| Literal | Matches exact characters                           | `readme.txt`    | `readme.txt`                | `README.txt`             |

## License

This project is licensed under the MIT License.

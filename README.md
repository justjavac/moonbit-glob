# Glob

A glob pattern matching library for MoonBit, supporting wildcard pattern matching on file paths and strings.

## Features

- **Basic Wildcards**: Support for `*` (matches any characters) and `?` (matches single character)
- **Directory Traversal**: Support for `**` (matches across directory boundaries)
- **Path-Aware Matching**: Single `*` respects directory boundaries, `**` crosses them
- **Character Classes**: Basic validation for bracket expressions `[abc]` (validation only)
- **Escaping**: Utility to escape special characters for literal matching
- **Bulk Operations**: Functions to match against multiple paths or patterns

## Installation

```bash
moon update
moon add justjavac/glob
```

## Usage

### Basic Pattern Matching

```moonbit
test "basic pattern matching" {
  // Match text files
  assert_eq(glob("*.txt", "readme.txt"), true)
  
  // Single character wildcard
  assert_eq(glob("file?.log", "file1.log"), true)
  
  // Cross-directory matching
  assert_eq(glob("**/*.mbt", "src/main.mbt"), true)
}
```

### Filtering Files

```moonbit
test "filtering files" {
  let files = ["readme.txt", "main.mbt", "test.py", "config.txt"]
  
  // Filter text files
  let txt_files = glob_filter("*.txt", files)
  assert_eq(txt_files, ["readme.txt", "config.txt"])
  
  // Check if any MoonBit files exist
  let has_mbt = glob_match_any("*.mbt", files)
  assert_eq(has_mbt, true)
}
```

### Multiple Pattern Matching

```moonbit
test "multiple patterns" {
  let patterns = ["*.txt", "*.md", "readme.*"]
  
  assert_eq(match_any_pattern(patterns, "readme.txt"), true)
  assert_eq(match_any_pattern(patterns, "main.mbt"), false)
}
```

### Pattern Validation and Escaping

```moonbit
test "validation and escaping" {
  // Validate pattern syntax
  assert_eq(is_valid_pattern("*.txt"), true)
  assert_eq(is_valid_pattern("[abc*.txt"), false)
  
  // Escape special characters
  let escaped = escape_glob("file[1].txt")
  assert_eq(escaped, "file\\[1\\].txt")
}
```

## Pattern Syntax

| Pattern | Description | Example | Matches | Doesn't Match |
|---------|-------------|---------|---------|---------------|
| `*` | Matches any characters (except path separators) | `*.txt` | `file.txt`, `readme.txt` | `dir/file.txt` |
| `**` | Matches any characters (including path separators) | `**/*.txt` | `dir/file.txt`, `a/b/c.txt` | `file.py` |
| `?` | Matches exactly one character | `file?.txt` | `file1.txt`, `fileA.txt` | `file.txt`, `file12.txt` |
| `[abc]` | Character class (validation only) | `file[123].txt` | *validated syntax only* | *not implemented* |
| Literal | Matches exact characters | `readme.txt` | `readme.txt` | `README.txt` |

## License

This project is licensed under the MIT License.

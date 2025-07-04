/// # Glob Pattern Matching Library
/// 
/// This module provides comprehensive glob pattern matching functionality for MoonBit.
/// Glob patterns are widely used for matching file paths and strings using wildcard characters.
/// 
/// ## Features
/// 
/// - **Basic Wildcards**: Support for `*` (matches any characters) and `?` (matches single character)
/// - **Directory Traversal**: Support for `**` (matches across directory boundaries)
/// - **Path-Aware Matching**: Single `*` respects directory boundaries, `**` crosses them
/// - **Character Classes**: Basic validation for bracket expressions `[abc]` (not fully implemented)
/// - **Escaping**: Utility to escape special characters for literal matching
/// - **Bulk Operations**: Functions to match against multiple paths or patterns
/// 
/// ## Usage Examples
/// 
/// ### Basic Pattern Matching
/// ```moonbit
/// assert_eq(glob("*.txt", "readme.txt"), true) // true for text files
/// assert_eq(glob("file?.log", "file1.log"), true) // matches with single character wildcard
/// assert_eq(glob("**/*.rs", "src/main.rs"), true) // matches Rust files in any subdirectory
/// ```
/// 
/// ### Bulk Operations
/// ```moonbit
/// let files = ["readme.txt", "main.rs", "test.py"]
/// assert_eq(glob_filter("*.txt", files), ["readme.txt"]) // filters text files from a list
/// assert_eq(glob_match_any("*.rs", files), true) // checks if any Rust files exist  
/// let patterns = ["*.txt", "*.md"]
/// assert_eq(match_any_pattern(patterns, "file.txt"), true) // checks if file matches any pattern
/// ```
/// 
/// ### Validation and Escaping
/// ```moonbit
/// assert_eq(is_valid_pattern("[abc]*.txt"), true) // validates pattern syntax
/// assert_eq(escape_glob("file[1].txt"), "file\\[1\\].txt") // escapes special characters for literal matching
/// ```

///| Basic character matching function that supports the '?' wildcard character.
/// 
/// This function compares a pattern character with a text character.
/// The '?' character in the pattern acts as a wildcard that matches any single character.
/// 
/// # Arguments
/// * `pattern` - The pattern character to match against
/// * `char` - The text character to be matched
/// 
/// # Returns
/// * `true` if the pattern character matches the text character or if pattern is '?'
/// * `false` otherwise
/// 
/// # Examples
/// ```moonbit
/// assert_eq(match_char('a', 'a'), true) // true
/// assert_eq(match_char('?', 'x'), true) // true  
/// assert_eq(match_char('a', 'b'), false) // false
/// ```
pub fn match_char(pattern : Char, char : Char) -> Bool {
  pattern == '?' || pattern == char
}

///| Checks if a character is a path separator.
/// 
/// This function identifies path separators used in file systems.
/// It supports both Unix-style forward slashes and Windows-style backslashes.
/// 
/// # Arguments
/// * `c` - The character to check
/// 
/// # Returns
/// * `true` if the character is '/' or '\'
/// * `false` otherwise
/// 
/// # Examples
/// ```moonbit
/// assert_eq(is_path_separator('/'), true) // true
/// assert_eq(is_path_separator('\\'), true) // true
/// assert_eq(is_path_separator('a'), false) // false
/// ```
pub fn is_path_separator(c : Char) -> Bool {
  c == '/' || c == '\\'
}

///| Safely retrieves a character at the specified position in a string.
/// 
/// This function provides bounds-checked access to string characters,
/// returning None if the index is out of bounds.
/// 
/// # Arguments
/// * `s` - The input string
/// * `index` - The zero-based index of the character to retrieve
/// 
/// # Returns
/// * `Some(char)` if the index is valid and within bounds
/// * `None` if the index is negative or >= string length
/// 
/// # Examples
/// ```moonbit
/// assert_eq(get_char("hello", 0), Some('h')) // Some('h')
/// assert_eq(get_char("hello", 4), Some('o')) // Some('o')
/// assert_eq(get_char("hello", 5), None) // None (out of bounds)
/// assert_eq(get_char("hello", -1), None) // None (negative index)
/// ```
pub fn get_char(s : String, index : Int) -> Char? {
  if index >= 0 && index < s.length() {
    let code = s.charcode_at(index)
    Some(code.unsafe_to_char())
  } else {
    None
  }
}

///| Core glob pattern matching logic with support for wildcards and path-aware matching.
/// 
/// This is the main recursive matching function that handles various glob patterns:
/// - `**` - Matches any sequence of characters including path separators (cross-directory)
/// - `*` - Matches any sequence of characters except path separators (single directory)
/// - `?` - Matches any single character
/// - Literal characters - Match themselves exactly
/// 
/// # Arguments
/// * `pattern` - The glob pattern to match against
/// * `text` - The text string to be matched
/// 
/// # Returns
/// * `true` if the pattern matches the text
/// * `false` otherwise
/// 
/// # Pattern Behavior
/// - Empty pattern only matches empty text
/// - `**` can match across directory boundaries
/// - `*` stops at path separators ('/' or '\')
/// - Single character matching supports '?' wildcard
/// 
/// # Examples
/// ```moonbit
/// assert_eq(match_here("*.txt", "file.txt"), true) // true
/// assert_eq(match_here("**/*.txt", "dir/file.txt"), true) // true
/// assert_eq(match_here("*.txt", "dir/file.txt"), false) // false (single * doesn't cross directories)
/// ```
pub fn match_here(pattern : String, text : String) -> Bool {
  let pattern_len = pattern.length()
  let text_len = text.length()
  if pattern_len == 0 {
    return text_len == 0
  }

  // Handle ** double asterisk matching (cross-directory matching)
  if pattern.has_prefix("**") {
    // Try to match remaining pattern from each position in text
    for i = 0; i <= text.length(); i = i + 1 {
      if match_here(pattern.substring(start=2), text.substring(start=i)) {
        return true
      }
    }
    return false
  }

  // Handle * single asterisk matching (non-cross-directory matching)
  if pattern.has_prefix("*") {
    // If pattern starts with *, we need special handling
    let remaining_pattern = pattern.substring(start=1)

    // If remaining pattern is empty, * matches any content without path separators
    if remaining_pattern.length() == 0 {
      for i = 0; i < text.length(); i = i + 1 {
        match get_char(text, i) {
          Some(c) if is_path_separator(c) => return false
          _ => ()
        }
      }
      return true
    }

    // Try to match, but don't cross path separators
    for i = 0; i <= text.length(); i = i + 1 {
      // Check if path separator is encountered (single asterisk should not cross directories)
      if i < text.length() {
        match get_char(text, i) {
          Some(c) if is_path_separator(c) => break
          _ => ()
        }
      }
      if match_here(remaining_pattern, text.substring(start=i)) {
        return true
      }
    }
    return false
  }

  // Handle single character matching
  if text_len > 0 && pattern_len > 0 {
    match (get_char(pattern, 0), get_char(text, 0)) {
      (Some(p), Some(t)) =>
        if match_char(p, t) {
          return match_here(pattern.substring(start=1), text.substring(start=1))
        }
      _ => ()
    }
  }
  return false
}

///| Matches a glob pattern against a text string.
/// 
/// This is the main public interface for glob pattern matching.
/// It supports standard glob wildcards including single and double asterisks.
/// 
/// # Arguments
/// * `pattern` - The glob pattern containing wildcards
/// * `text` - The text string to match against the pattern
/// 
/// # Returns
/// * `true` if the pattern matches the text
/// * `false` otherwise
/// 
/// # Supported Patterns
/// - `*` - Matches any characters except path separators
/// - `**` - Matches any characters including path separators
/// - `?` - Matches exactly one character
/// - `[abc]` - Character class (validation only, not implemented)
/// - Literal characters match themselves
/// 
/// # Examples
/// ```moonbit
/// assert_eq(glob("*.txt", "readme.txt"), true) // true
/// assert_eq(glob("**/*.md", "docs/api/readme.md"), true) // true
/// assert_eq(glob("file?.txt", "file1.txt"), true) // true
/// assert_eq(glob("*.jpg", "image.png"), false) // false
/// ```
pub fn glob(pattern : String, text : String) -> Bool {
  match_here(pattern, text)
}

///| Checks if a glob pattern matches any path in a collection of file paths.
/// 
/// This function provides a convenient way to test if at least one path
/// in a collection matches the given glob pattern. It returns as soon as
/// the first match is found, making it efficient for large collections.
/// 
/// # Arguments
/// * `pattern` - The glob pattern to match against
/// * `paths` - An array of file paths to test
/// 
/// # Returns
/// * `true` if at least one path matches the pattern
/// * `false` if no paths match the pattern or if the array is empty
/// 
/// # Examples
/// ```moonbit
/// let files = ["readme.txt", "main.rs", "test.py"]
/// assert_eq(glob_match_any("*.txt", files), true) // true
/// assert_eq(glob_match_any("*.js", files), false) // false
/// ```
pub fn glob_match_any(pattern : String, paths : Array[String]) -> Bool {
  for path in paths {
    if glob(pattern, path) {
      return true
    }
  }
  false
}

///| Filters an array of paths, returning only those that match the glob pattern.
/// 
/// This function creates a new array containing only the paths from the input
/// array that match the specified glob pattern. The original array is not modified.
/// 
/// # Arguments
/// * `pattern` - The glob pattern to filter by
/// * `paths` - An array of file paths to filter
/// 
/// # Returns
/// * A new array containing only the paths that match the pattern
/// * An empty array if no paths match or if the input array is empty
/// 
/// # Examples
/// ```moonbit
/// let files = ["readme.txt", "main.rs", "test.py", "config.txt"]
/// assert_eq(glob_filter("*.txt", files), ["readme.txt", "config.txt"]) // ["readme.txt", "config.txt"]
/// assert_eq(glob_filter("*.js", files), []) // []
/// ```
pub fn glob_filter(pattern : String, paths : Array[String]) -> Array[String] {
  let result = []
  for path in paths {
    if glob(pattern, path) {
      result.push(path)
    }
  }
  result
}

///| Checks if a file path matches any pattern in a collection of glob patterns.
/// 
/// This function tests a single path against multiple glob patterns,
/// returning true if the path matches at least one pattern. This is useful
/// for implementing include/exclude rules or multiple pattern matching.
/// 
/// # Arguments
/// * `patterns` - An array of glob patterns to test against
/// * `path` - The file path to test
/// 
/// # Returns
/// * `true` if the path matches at least one pattern
/// * `false` if the path matches no patterns or if the patterns array is empty
/// 
/// # Examples
/// ```moonbit
/// let patterns = ["*.txt", "*.md", "readme.*"]
/// assert_eq(match_any_pattern(patterns, "readme.txt"), true) // true
/// assert_eq(match_any_pattern(patterns, "readme.md"), true) // true
/// assert_eq(match_any_pattern(patterns, "main.rs"), false) // false
/// ```
pub fn match_any_pattern(patterns : Array[String], path : String) -> Bool {
  for pattern in patterns {
    if glob(pattern, path) {
      return true
    }
  }
  false
}

///| Validates whether a string represents a well-formed glob pattern.
/// 
/// This function performs basic syntax validation on glob patterns,
/// currently focusing on bracket matching for character classes.
/// It ensures that all opening brackets '[' have corresponding closing brackets ']'.
/// 
/// # Arguments
/// * `pattern` - The glob pattern string to validate
/// 
/// # Returns
/// * `true` if the pattern appears to be syntactically valid
/// * `false` if the pattern has syntax errors (e.g., unmatched brackets)
/// 
/// # Validation Rules
/// - All '[' characters must have matching ']' characters
/// - No extra ']' characters without corresponding '['
/// - Brackets must be properly nested
/// 
/// # Examples
/// ```moonbit
/// assert_eq(is_valid_pattern("*.txt"), true) // true
/// assert_eq(is_valid_pattern("[abc]*.txt"), true) // true
/// assert_eq(is_valid_pattern("[abc*.txt"), false) // false (unmatched '[')
/// assert_eq(is_valid_pattern("abc]*.txt"), false) // false (extra ']')
/// ```
/// 
/// # Note
/// This is a basic validation that only checks bracket matching.
/// More sophisticated pattern validation could be added in the future.
pub fn is_valid_pattern(pattern : String) -> Bool {
  // Simple validation: check for unmatched brackets, etc.
  let mut bracket_count = 0
  for i = 0; i < pattern.length(); i = i + 1 {
    match get_char(pattern, i) {
      Some('[') => bracket_count = bracket_count + 1
      Some(']') => {
        bracket_count = bracket_count - 1
        // If an extra closing bracket is encountered, immediately return `false`.
        if bracket_count < 0 {
          return false
        }
      }
      _ => ()
    }
  }
  bracket_count == 0
}

///| Escapes special glob characters in a text string to create a literal pattern.
/// 
/// This function converts a regular text string into a glob pattern that will
/// match the text literally by escaping all special glob characters.
/// This is useful when you want to match a filename that contains characters
/// that would normally be interpreted as wildcards.
/// 
/// # Arguments
/// * `text` - The input text string to escape
/// 
/// # Returns
/// * A new string with all special glob characters escaped with backslashes
/// 
/// # Escaped Characters
/// - `*` becomes `\*`
/// - `?` becomes `\?`
/// - `[` becomes `\[`
/// - `]` becomes `\]`
/// 
/// # Examples
/// ```moonbit
/// assert_eq(escape_glob("file*.txt"), "file\\*.txt") // "file\\*.txt"
/// assert_eq(escape_glob("test?[1].log"), "test\\?\\[1\\].log") // "test\\?\\[1\\].log"
/// assert_eq(escape_glob("normal.txt"), "normal.txt") // "normal.txt"
/// ```
/// 
/// # Use Case
/// Use this function when you have a filename that contains glob metacharacters
/// but you want to match it literally rather than as a pattern.
pub fn escape_glob(text : String) -> String {
  let mut result = ""
  for i = 0; i < text.length(); i = i + 1 {
    match get_char(text, i) {
      Some('*') => result = result + "\\*"
      Some('?') => result = result + "\\?"
      Some('[') => result = result + "\\["
      Some(']') => result = result + "\\]"
      Some(c) => result = result + c.to_string()
      None => ()
    }
  }
  result
}

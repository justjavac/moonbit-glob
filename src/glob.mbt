/// # Glob Pattern Matching
///
/// `@glob` provides a small, path-aware glob matcher for MoonBit.
/// The matcher currently understands:
///
/// - `?` for exactly one character
/// - `*` for any characters inside one path segment
/// - `**` for any characters across path separators
///
/// `is_valid_pattern` also checks balanced brackets such as `[abc]`, but
/// character classes are not interpreted by `glob` yet.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.glob("*.txt", "notes.txt"), true)
///   assert_eq(@glob.glob("src/**/*.mbt", "src/lib/main.mbt"), true)
///   assert_eq(@glob.glob("src/*.mbt", "src/lib/main.mbt"), false)
/// }
/// ```

///|
/// Match one pattern character against one text character.
///
/// `?` matches any single character. All other characters must be equal.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.match_char('a', 'a'), true)
///   assert_eq(@glob.match_char('?', 'x'), true)
///   assert_eq(@glob.match_char('a', 'b'), false)
/// }
/// ```
pub fn match_char(pattern : Char, char : Char) -> Bool {
  pattern == '?' || pattern == char
}

///|
/// Return whether `c` is a supported path separator.
///
/// Both Unix (`/`) and Windows (`\`) separators are recognized.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.is_path_separator('/'), true)
///   assert_eq(@glob.is_path_separator('\\'), true)
///   assert_eq(@glob.is_path_separator('a'), false)
/// }
/// ```
pub fn is_path_separator(c : Char) -> Bool {
  c == '/' || c == '\\'
}

///|
/// Safely read one character from `s` by zero-based index.
///
/// This helper returns `None` instead of raising when the index is out of
/// bounds.
///
/// # Example
/// ```mbt check
/// test {
///   assert_true(@glob.get_char("moon", 0) == Some('m'))
///   assert_true(@glob.get_char("moon", 3) == Some('n'))
///   assert_true(@glob.get_char("moon", 4) == None)
/// }
/// ```
pub fn get_char(s : String, index : Int) -> Char? {
  let chars = s.to_array()
  if index >= 0 && index < chars.length() {
    Some(chars[index])
  } else {
    None
  }
}

///|
/// Match `pattern` and `text` starting at character offsets.
fn match_chars(
  pattern : Array[Char],
  pattern_index : Int,
  text : Array[Char],
  text_index : Int,
) -> Bool {
  let pattern_len = pattern.length()
  let text_len = text.length()
  if pattern_index >= pattern_len {
    return text_index >= text_len
  }

  if pattern[pattern_index] == '*' &&
    pattern_index + 1 < pattern_len &&
    pattern[pattern_index + 1] == '*' {
    for i in text_index..<=text_len {
      if match_chars(pattern, pattern_index + 2, text, i) {
        return true
      }
    }
    return false
  }

  if pattern[pattern_index] == '*' {
    let next_pattern = pattern_index + 1
    if next_pattern >= pattern_len {
      for i in text_index..<text_len {
        if is_path_separator(text[i]) {
          return false
        }
      }
      return true
    }

    let mut i = text_index
    while i <= text_len {
      if match_chars(pattern, next_pattern, text, i) {
        return true
      }
      if i < text_len && is_path_separator(text[i]) {
        break
      }
      i = i + 1
    }
    return false
  }

  if text_index < text_len &&
    match_char(pattern[pattern_index], text[text_index]) {
    return match_chars(pattern, pattern_index + 1, text, text_index + 1)
  }
  false
}

///|
/// Match `pattern` against `text` using the package's recursive glob rules.
///
/// This is the low-level matcher that powers `glob`. Most callers should use
/// `glob` directly.
///
/// Matching rules:
///
/// - `**` can consume any suffix, including path separators
/// - `*` can consume any suffix until the next path separator
/// - `?` matches exactly one character
/// - every other character matches literally
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.match_here("**/*.mbt", "src/lib/main.mbt"), true)
///   assert_eq(@glob.match_here("*.mbt", "src/lib/main.mbt"), false)
/// }
/// ```
pub fn match_here(pattern : String, text : String) -> Bool {
  match_chars(pattern.to_array(), 0, text.to_array(), 0)
}

///|
/// Match one glob `pattern` against one `text` path.
///
/// This is the main public entry point for the package.
///
/// Supported syntax:
///
/// - `*` matches zero or more non-separator characters
/// - `**` matches zero or more characters, including separators
/// - `?` matches exactly one character
///
/// Bracket expressions such as `[abc]` are validated by
/// `is_valid_pattern`, but they are not matched specially yet.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.glob("file?.log", "file1.log"), true)
///   assert_eq(@glob.glob("**/*.md", "docs/api/readme.md"), true)
///   assert_eq(@glob.glob("*.jpg", "images/logo.png"), false)
/// }
/// ```
pub fn glob(pattern : String, text : String) -> Bool {
  match_here(pattern, text)
}

///|
/// Return whether any path in `paths` matches `pattern`.
///
/// The function stops at the first match.
///
/// # Example
/// ```mbt check
/// test {
///   let files = ["README.md", "src/main.mbt", "test/main_test.mbt"]
///   assert_eq(@glob.glob_match_any("**/*.mbt", files), true)
///   assert_eq(@glob.glob_match_any("**/*.rs", files), false)
/// }
/// ```
pub fn glob_match_any(pattern : String, paths : Array[String]) -> Bool {
  for path in paths {
    if glob(pattern, path) {
      return true
    }
  }
  false
}

///|
/// Return a new array containing only the paths that match `pattern`.
///
/// The original array is left unchanged.
///
/// # Example
/// ```mbt check
/// test {
///   let files = ["README.md", "src/main.mbt", "src/lib/util.mbt"]
///   assert_true(@glob.glob_filter("src/*.mbt", files) == ["src/main.mbt"])
///   assert_true(@glob.glob_filter("src/**/*.mbt", files) == ["src/lib/util.mbt"])
/// }
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

///|
/// Return whether `path` matches at least one glob in `patterns`.
///
/// This is useful when several include rules should be checked together.
///
/// # Example
/// ```mbt check
/// test {
///   let patterns = ["*.md", "**/*.mbt"]
///   assert_eq(@glob.match_any_pattern(patterns, "README.md"), true)
///   assert_eq(@glob.match_any_pattern(patterns, "src/main.mbt"), true)
///   assert_eq(@glob.match_any_pattern(patterns, "package.json"), false)
/// }
/// ```
pub fn match_any_pattern(patterns : Array[String], path : String) -> Bool {
  for pattern in patterns {
    if glob(pattern, path) {
      return true
    }
  }
  false
}

///|
/// Check whether `pattern` is structurally valid.
///
/// The current validation is intentionally small in scope: it only checks that
/// `[` and `]` are balanced. It does not validate or implement the full glob
/// grammar.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.is_valid_pattern("*.mbt"), true)
///   assert_eq(@glob.is_valid_pattern("[abc]*.txt"), true)
///   assert_eq(@glob.is_valid_pattern("[abc*.txt"), false)
///   assert_eq(@glob.is_valid_pattern("abc]*.txt"), false)
/// }
/// ```
pub fn is_valid_pattern(pattern : String) -> Bool {
  let mut bracket_count = 0
  for c in pattern {
    match c {
      '[' => bracket_count = bracket_count + 1
      ']' => {
        bracket_count = bracket_count - 1
        if bracket_count < 0 {
          return false
        }
      }
      _ => ()
    }
  }
  bracket_count == 0
}

///|
/// Prefix common glob metacharacters in `text` with backslashes.
///
/// This helper is useful when you want a readable escaped representation of a
/// pattern fragment or when interoperating with tools that treat backslashes as
/// escapes. The current matcher does not interpret backslashes specially.
///
/// # Example
/// ```mbt check
/// test {
///   assert_eq(@glob.escape_glob("file*.txt"), "file\\*.txt")
///   assert_eq(@glob.escape_glob("test?[1].log"), "test\\?\\[1\\].log")
///   assert_eq(@glob.escape_glob("plain.txt"), "plain.txt")
/// }
/// ```
pub fn escape_glob(text : String) -> String {
  let mut result = ""
  for c in text {
    match c {
      '*' => result = result + "\\*"
      '?' => result = result + "\\?"
      '[' => result = result + "\\["
      ']' => result = result + "\\]"
      c => result = result + c.to_string()
    }
  }
  result
}

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
///   assert_eq(@glob.get_char("moon", 0), Some('m'))
///   assert_eq(@glob.get_char("moon", 3), Some('n'))
///   assert_eq(@glob.get_char("moon", 4), None)
/// }
/// ```
pub fn get_char(s : String, index : Int) -> Char? {
  if index >= 0 && index < s.length() {
    let code = s[index]
    Some(code.unsafe_to_char())
  } else {
    None
  }
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
pub fn match_here(pattern : String, text : String) -> Bool raise {
  let pattern_len = pattern.length()
  let text_len = text.length()
  if pattern_len == 0 {
    return text_len == 0
  }

  // `**` can span across directory boundaries.
  if pattern.has_prefix("**") {
    for i = 0; i <= text.length(); i = i + 1 {
      if match_here(pattern[2:].to_string(), text[i:].to_string()) {
        return true
      }
    }
    return false
  }

  // `*` stays within a single path segment.
  if pattern.has_prefix("*") {
    let remaining_pattern = pattern[1:].to_string()

    if remaining_pattern.length() == 0 {
      for i = 0; i < text.length(); i = i + 1 {
        match get_char(text, i) {
          Some(c) if is_path_separator(c) => return false
          _ => ()
        }
      }
      return true
    }

    for i = 0; i <= text.length(); i = i + 1 {
      if i < text.length() {
        match get_char(text, i) {
          Some(c) if is_path_separator(c) => break
          _ => ()
        }
      }
      if match_here(remaining_pattern, text[i:].to_string()) {
        return true
      }
    }
    return false
  }

  // Match one character literally or through `?`.
  if text_len > 0 && pattern_len > 0 {
    let pattern_char = pattern[0].unsafe_to_char()
    let text_char = text[0].unsafe_to_char()
    if match_char(pattern_char, text_char) {
      return match_here(pattern[1:].to_string(), text[1:].to_string())
    }
  }
  false
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
pub fn glob(pattern : String, text : String) -> Bool raise {
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
pub fn glob_match_any(pattern : String, paths : Array[String]) -> Bool raise {
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
///   assert_eq(@glob.glob_filter("src/*.mbt", files), ["src/main.mbt"])
///   assert_eq(@glob.glob_filter("src/**/*.mbt", files), ["src/lib/util.mbt"])
/// }
/// ```
pub fn glob_filter(
  pattern : String,
  paths : Array[String],
) -> Array[String] raise {
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
pub fn match_any_pattern(patterns : Array[String], path : String) -> Bool raise {
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
  for i = 0; i < pattern.length(); i = i + 1 {
    match get_char(pattern, i) {
      Some('[') => bracket_count = bracket_count + 1
      Some(']') => {
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
  for i = 0; i < text.length(); i = i + 1 {
    match text[i].unsafe_to_char() {
      '*' => result = result + "\\*"
      '?' => result = result + "\\?"
      '[' => result = result + "\\["
      ']' => result = result + "\\]"
      c => result = result + c.to_string()
    }
  }
  result
}

///|
test "glob: basic match" {
  assert_eq(glob("abc", "abc"), true)
  assert_eq(glob("abc", "def"), false)
  assert_eq(glob("", ""), true)
  assert_eq(glob("", "abc"), false)
  assert_eq(glob("abc", ""), false)
}

///|
test "glob: question mark wildcard" {
  assert_eq(glob("a?c", "abc"), true)
  assert_eq(glob("a?c", "axc"), true)
  assert_eq(glob("a?c", "ac"), false)
  assert_eq(glob("a?c", "abbc"), false)
  assert_eq(glob("???", "abc"), true)
  assert_eq(glob("???", "ab"), false)
}

///|
test "glob: single asterisk wildcard" {
  assert_eq(glob("a*c", "abc"), true)
  assert_eq(glob("a*c", "axyzc"), true)
  assert_eq(glob("a*c", "ac"), true)
  assert_eq(glob("*", "abc"), true)
  assert_eq(glob("*", ""), true)
  assert_eq(glob("a*", "abc"), true)
  assert_eq(glob("*c", "abc"), true)
}

///|
test "glob: double asterisk wildcard" {
  assert_eq(glob("a**c", "abc"), true)
  assert_eq(glob("a**c", "axyzc"), true)
  assert_eq(glob("a**c", "ac"), true)
  assert_eq(glob("a**c", "a/b/c"), true)
  assert_eq(glob("**", "a/b/c"), true)
  assert_eq(glob("**/test", "dir/test"), true)
  assert_eq(glob("src/**", "src/main.mbt"), true)
}

///|
test "glob: path patterns" {
  assert_eq(glob("src/*.mbt", "src/main.mbt"), true)
  assert_eq(glob("src/*.mbt", "src/lib/main.mbt"), false)
  assert_eq(glob("src/**/*.mbt", "src/lib/main.mbt"), true)
  assert_eq(glob("test/**/test_*.mbt", "test/unit/test_glob.mbt"), true)
}

///|
test "glob: utility functions" {
  let paths = ["src/main.mbt", "src/lib.mbt", "test/main.mbt", "README.md"]
  assert_eq(glob_match_any("*.mbt", paths), false)
  assert_eq(glob_match_any("*.py", paths), false)
  let mbt_files = glob_filter("*.mbt", paths)
  assert_eq(mbt_files.length(), 0)
  assert_eq(glob_match_any("**/*.mbt", paths), true)
  let all_mbt_files = glob_filter("**/*.mbt", paths)
  assert_eq(all_mbt_files.length(), 3)
  let patterns = ["*.mbt", "*.md"]
  assert_eq(match_any_pattern(patterns, "main.mbt"), true)
  assert_eq(match_any_pattern(patterns, "README.md"), true)
  assert_eq(match_any_pattern(patterns, "config.json"), false)
}

///|
test "glob: pattern validation" {
  assert_eq(is_valid_pattern("*.mbt"), true)
  assert_eq(is_valid_pattern("test[abc]"), true)
  assert_eq(is_valid_pattern("test[abc"), false)
  assert_eq(is_valid_pattern("test]abc["), false)
}

///| Escape function tests
test "glob: escape function" {
  assert_eq(escape_glob("test*file"), "test\\*file")
  assert_eq(escape_glob("file?.txt"), "file\\?.txt")
  assert_eq(escape_glob("normal_file"), "normal_file")
}

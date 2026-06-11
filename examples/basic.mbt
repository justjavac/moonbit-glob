fn main {
  let paths = ["README.md", "src/main.mbt", "src/lib/util.mbt"]
  println(@glob.glob_filter("src/**/*.mbt", paths))
}

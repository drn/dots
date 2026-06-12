#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

RENDER="$SCRIPTS_DIR/markdown-preview/scripts/render.sh"

# Source the script to access functions without running main.
_source_render() {
  eval "$(sed 's/^main "\$@"//' "$RENDER")"
}

test_preview_path_basic() {
  _source_render
  assert_eq "$(preview_path "docs/README.md")" "docs/README-preview.html" \
    "preview path next to source, .md stripped"
}

test_preview_path_no_dir() {
  _source_render
  assert_eq "$(preview_path "NOTES.md")" "./NOTES-preview.html" \
    "bare filename gets ./ dir from dirname"
}

test_preview_path_markdown_ext() {
  _source_render
  assert_eq "$(preview_path "a/b/guide.markdown")" "a/b/guide-preview.html" \
    "longest-ext strip handles .markdown"
}

test_wrap_html_structure() {
  _source_render
  local doc
  doc="$(wrap_html "My Title" "<h1>Hello</h1>")"
  assert_contains "$doc" "<!doctype html>" "emits doctype"
  assert_contains "$doc" "<title>My Title</title>" "title is interpolated"
  assert_contains "$doc" "<h1>Hello</h1>" "body is embedded"
  assert_contains "$doc" "markdown-body" "uses markdown-body article class"
}

test_wrap_html_light_dark() {
  _source_render
  local doc
  doc="$(wrap_html "T" "<p>x</p>")"
  assert_contains "$doc" "prefers-color-scheme: dark" "has dark mode block"
  assert_contains "$doc" "color-scheme: light dark" "declares light+dark"
  assert_contains "$doc" "max-width: 1012px" "GitHub content width"
}

test_wrap_stdin_hook() {
  _source_render
  local doc
  doc="$(echo "<p>piped body</p>" | bash "$RENDER" --wrap-stdin "Piped")"
  assert_contains "$doc" "<title>Piped</title>" "stdin hook sets title"
  assert_contains "$doc" "<p>piped body</p>" "stdin hook embeds piped body"
}

test_missing_file_arg() {
  capture bash "$RENDER"
  assert_eq "$_CAPTURED_EXIT" "1" "exits 1 with no file"
  assert_contains "$_CAPTURED" "no markdown file" "reports missing file arg"
}

test_nonexistent_file() {
  capture bash "$RENDER" "/no/such/file-xyz.md"
  assert_eq "$_CAPTURED_EXIT" "1" "exits 1 for missing file"
  assert_contains "$_CAPTURED" "file not found" "reports file not found"
}

test_unknown_flag() {
  capture bash "$RENDER" --bogus
  assert_eq "$_CAPTURED_EXIT" "1" "exits 1 on unknown flag"
}

run_tests

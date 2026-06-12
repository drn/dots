#!/usr/bin/env bash
source "$(dirname "$0")/harness.sh"

RENDER="$SCRIPTS_DIR/markdown-preview/scripts/render.sh"

# Source the script to access functions without running main.
_source_render() {
  eval "$(sed 's/^main "\$@"//' "$RENDER")"
}

# Build a temp dir with stub `gh`/`jq` on PATH so the full pipeline runs
# offline. Stub gh ignores its input and emits a fixed body; stub jq is a
# no-op that satisfies the dependency check. Echoes the dir; PATH must be
# prefixed with "$dir/bin" by the caller. Harness cleans the dir up on exit.
_mdp_stub_dir() {
  local dir
  dir=$(mktemp -d "${TMPDIR:-/tmp}/mdp-XXXXXX")
  _TMPDIRS+=("$dir")
  mkdir -p "$dir/bin"
  printf '#!/usr/bin/env bash\ncat >/dev/null\nprintf "%%s" "<p>STUB BODY</p>"\n' > "$dir/bin/gh"
  printf '#!/usr/bin/env bash\nprintf "%%s" "{}"\n' > "$dir/bin/jq"
  chmod +x "$dir/bin/gh" "$dir/bin/jq"
  printf '# Hi\n' > "$dir/doc.md"
  echo "$dir"
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

test_preview_path_dotfile() {
  _source_render
  assert_eq "$(preview_path ".hidden")" "./.hidden-preview.html" \
    "dotfile keeps its name instead of stripping to empty"
}

test_preview_path_multidot() {
  _source_render
  assert_eq "$(preview_path "a.b.md")" "./a.b-preview.html" \
    "only the last extension is stripped"
}

test_wrap_html_escapes_title() {
  _source_render
  local doc
  doc="$(wrap_html "<script>x</script>" "<p>body</p>")"
  assert_contains "$doc" "&lt;script&gt;x&lt;/script&gt;" "title markup is escaped"
  assert_not_contains "$doc" "<title><script>" "raw script tag not in title"
}

test_out_requires_value() {
  capture bash "$RENDER" somefile.md --out
  assert_eq "$_CAPTURED_EXIT" "1" "--out with no value exits 1"
  assert_contains "$_CAPTURED" "requires a path" "reports --out needs a path"
}

test_out_rejects_flag_as_value() {
  capture bash "$RENDER" somefile.md --out --no-open
  assert_eq "$_CAPTURED_EXIT" "1" "--out followed by a flag exits 1"
  assert_contains "$_CAPTURED" "requires a path" "does not consume --no-open as the path"
}

test_wrap_html_escapes_ampersand_first() {
  _source_render
  local doc
  doc="$(wrap_html "A & B" "<p>x</p>")"
  assert_contains "$doc" "<title>A &amp; B</title>" "bare ampersand becomes &amp;"
  assert_not_contains "$doc" "&amp;amp;" "no double-escaping of the ampersand"
}

test_wrap_stdin_requires_title() {
  capture bash "$RENDER" --wrap-stdin
  assert_eq "$_CAPTURED_EXIT" "1" "--wrap-stdin with no title exits 1"
  assert_contains "$_CAPTURED" "requires a title" "reports missing title"
}

test_render_print_path_only_emits_path() {
  local dir out
  dir=$(_mdp_stub_dir)
  out=$(PATH="$dir/bin:$PATH" bash "$RENDER" "$dir/doc.md" --no-open --print-path)
  assert_eq "$out" "$dir/doc-preview.html" "--print-path emits only the path"
  assert_not_contains "$out" "Wrote preview" "no friendly prefix under --print-path"
  assert_contains "$(cat "$dir/doc-preview.html")" "STUB BODY" "preview embeds rendered body"
}

test_render_default_prints_friendly_message() {
  local dir out
  dir=$(_mdp_stub_dir)
  out=$(PATH="$dir/bin:$PATH" bash "$RENDER" "$dir/doc.md" --no-open)
  assert_contains "$out" "Wrote preview:" "default run prints friendly message"
  assert_contains "$out" "doc-preview.html" "message includes the preview path"
}

test_render_out_writes_custom_path() {
  local dir
  dir=$(_mdp_stub_dir)
  PATH="$dir/bin:$PATH" bash "$RENDER" "$dir/doc.md" --out "$dir/custom.html" --no-open >/dev/null
  assert_contains "$(cat "$dir/custom.html")" "STUB BODY" "--out writes to the custom path"
}

test_render_open_failure_does_not_abort() {
  local dir code=0
  dir=$(_mdp_stub_dir)
  printf '#!/usr/bin/env bash\nexit 1\n' > "$dir/bin/open"
  chmod +x "$dir/bin/open"
  PATH="$dir/bin:$PATH" bash "$RENDER" "$dir/doc.md" >/dev/null 2>&1 || code=$?
  assert_eq "$code" "0" "a failed browser opener does not abort the script"
  assert_contains "$(cat "$dir/doc-preview.html")" "STUB BODY" "preview is written even when open fails"
}

test_out_rejects_empty_value() {
  capture bash "$RENDER" somefile.md --out ""
  assert_eq "$_CAPTURED_EXIT" "1" "--out with an empty value exits 1"
  assert_contains "$_CAPTURED" "requires a path" "reports empty --out value"
}

test_wrap_stdin_rejects_empty_title() {
  capture bash "$RENDER" --wrap-stdin ""
  assert_eq "$_CAPTURED_EXIT" "1" "--wrap-stdin with an empty title exits 1"
  assert_contains "$_CAPTURED" "requires a title" "reports empty --wrap-stdin title"
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
  assert_contains "$_CAPTURED" "Unknown flag" "reports the unknown flag"
}

test_wrap_html_escapes_double_quote() {
  _source_render
  local doc
  doc="$(wrap_html 'a"b' "<p>x</p>")"
  assert_contains "$doc" "<title>a&quot;b</title>" "double quote in title is escaped"
}

# Exercises the real jq encoding (the integration tests stub jq out, so this
# is the only check that the API request payload has the right shape).
test_build_payload_shape() {
  command -v jq >/dev/null 2>&1 || return 0
  _source_render
  local dir payload
  dir=$(mktemp -d "${TMPDIR:-/tmp}/mdp-XXXXXX")
  _TMPDIRS+=("$dir")
  printf '# Heading\n' > "$dir/d.md"
  payload=$(build_payload "$dir/d.md")
  assert_contains "$payload" '"mode": "gfm"' "payload requests gfm mode"
  assert_contains "$payload" "Heading" "payload carries the markdown text"
}

run_tests

#!/usr/bin/env bash
#
# render.sh — render a Markdown file to GitHub-flavored HTML and open a preview.
#
# Renders the markdown via `gh api /markdown` (mode: gfm — true GitHub
# rendering of tables, task lists, etc.), wraps the result in a self-contained,
# GitHub-styled HTML document (light + dark via prefers-color-scheme), writes
# the preview ALONGSIDE the source file so relative image paths resolve, then
# opens it in the default browser.
#
# Usage:
#   render.sh <file.md> [--out <path>] [--no-open] [--print-path]
#
# Flags:
#   --out <path>    Write the preview to <path> instead of <file>-preview.html.
#                   Use only when the markdown has no relative assets — a path
#                   outside the source directory will break relative image src.
#   --no-open       Render and write the file but do not launch a browser.
#   --print-path    Print only the written preview path to stdout.
#   -h, --help      Show usage.
#
# Hidden test hook (no network, no gh — used by the bash tests):
#   --wrap-stdin <title>   Read body HTML from stdin, emit the wrapped document
#                          to stdout, and exit.
#
# Requires: gh (authenticated), jq. macOS `open`, Linux `xdg-open`, or
# Windows `start` for the open step.

set -euo pipefail

usage() {
  sed -n '3,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Compute the default preview path: <dir>/<name>-preview.html next to source.
preview_path() {
  local md="$1" dir base name
  dir="$(dirname "$md")"
  base="$(basename "$md")"
  name="${base%.*}"
  # A dotfile with no other extension (e.g. ".hidden") strips to empty; keep
  # the original name so the preview path is never "./-preview.html".
  [[ -z "$name" ]] && name="$base"
  echo "${dir}/${name}-preview.html"
}

# Emit a self-contained, GitHub-styled HTML document wrapping the body HTML.
# wrap_html <title> <body-html>
wrap_html() {
  local title="$1" body="$2"
  # Escape the title (derived from the filename) so an exotic name cannot
  # inject markup into the <title> element. The body is GitHub-rendered HTML
  # and is intentionally emitted as-is.
  title="${title//&/&amp;}"
  title="${title//</&lt;}"
  title="${title//>/&gt;}"
  cat <<HTML
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0;
    background: #ffffff;
    color: #1f2328;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans",
      Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 1.5;
  }
  .markdown-body {
    box-sizing: border-box;
    max-width: 1012px;
    margin: 0 auto;
    padding: 32px 16px 64px;
  }
  .markdown-body h1, .markdown-body h2 {
    border-bottom: 1px solid #d1d9e0;
    padding-bottom: .3em;
  }
  .markdown-body h1, .markdown-body h2, .markdown-body h3,
  .markdown-body h4, .markdown-body h5, .markdown-body h6 {
    margin-top: 24px;
    margin-bottom: 16px;
    font-weight: 600;
    line-height: 1.25;
  }
  .markdown-body a { color: #0969da; text-decoration: none; }
  .markdown-body a:hover { text-decoration: underline; }
  .markdown-body img { max-width: 100%; box-sizing: content-box; }
  .markdown-body code {
    padding: .2em .4em;
    margin: 0;
    font-size: 85%;
    background: rgba(129,139,152,0.12);
    border-radius: 6px;
    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas,
      "Liberation Mono", monospace;
  }
  .markdown-body pre {
    padding: 16px;
    overflow: auto;
    font-size: 85%;
    line-height: 1.45;
    background: #f6f8fa;
    border-radius: 6px;
  }
  .markdown-body pre code { padding: 0; background: transparent; border: 0; }
  .markdown-body blockquote {
    margin: 0;
    padding: 0 1em;
    color: #59636e;
    border-left: .25em solid #d1d9e0;
  }
  .markdown-body table {
    border-collapse: collapse;
    border-spacing: 0;
    display: block;
    width: max-content;
    max-width: 100%;
    overflow: auto;
  }
  .markdown-body table th, .markdown-body table td {
    padding: 6px 13px;
    border: 1px solid #d1d9e0;
  }
  .markdown-body table tr:nth-child(2n) { background: #f6f8fa; }
  .markdown-body hr { height: .25em; background: #d1d9e0; border: 0; }
  .markdown-body .task-list-item { list-style-type: none; }
  @media (prefers-color-scheme: dark) {
    body { background: #0d1117; color: #e6edf3; }
    .markdown-body h1, .markdown-body h2 { border-bottom-color: #3d444d; }
    .markdown-body a { color: #4493f8; }
    .markdown-body code { background: rgba(101,108,118,0.2); }
    .markdown-body pre { background: #151b23; }
    .markdown-body blockquote { color: #9198a1; border-left-color: #3d444d; }
    .markdown-body table th, .markdown-body table td { border-color: #3d444d; }
    .markdown-body table tr:nth-child(2n) { background: #151b23; }
    .markdown-body hr { background: #3d444d; }
  }
</style>
</head>
<body>
<article class="markdown-body">
${body}
</article>
</body>
</html>
HTML
}

# Render the body HTML from a markdown file via the GitHub API.
render_body() {
  local md="$1"
  jq -Rs '{text: ., mode: "gfm"}' "$md" | gh api --method POST /markdown --input -
}

# Open a file in the default browser, branching on platform.
open_file() {
  local f="$1"
  if command -v open >/dev/null 2>&1; then
    open "$f"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$f"
  elif command -v start >/dev/null 2>&1; then
    start "" "$f"
  else
    echo "No browser opener found (open/xdg-open/start). Preview at: $f" >&2
  fi
}

main() {
  local file="" out="" do_open=1 print_path=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --wrap-stdin) shift; wrap_html "${1:-Preview}" "$(cat)"; return 0 ;;
      --out)
        shift
        if [[ $# -eq 0 || "${1:-}" == -* ]]; then
          echo "Error: --out requires a path argument." >&2
          return 1
        fi
        out="$1"
        ;;
      --no-open) do_open=0 ;;
      --print-path) print_path=1 ;;
      -h|--help) usage; return 0 ;;
      -*) echo "Unknown flag: $1" >&2; usage >&2; return 1 ;;
      *) file="$1" ;;
    esac
    shift
  done

  if [[ -z "$file" ]]; then
    echo "Error: no markdown file given." >&2
    usage >&2
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "Error: file not found: $file" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    return 1
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh (GitHub CLI) is required but not installed." >&2
    echo "Install it, or render with a local tool such as 'grip' or 'glow'." >&2
    return 1
  fi

  [[ -z "$out" ]] && out="$(preview_path "$file")"

  local body
  if ! body="$(render_body "$file")"; then
    echo "Error: 'gh api /markdown' failed. Check auth with: gh auth status" >&2
    return 1
  fi

  wrap_html "$(basename "$file")" "$body" > "$out"

  if [[ "$print_path" -eq 1 ]]; then
    echo "$out"
  else
    echo "Wrote preview: $out"
  fi

  [[ "$do_open" -eq 1 ]] && open_file "$out"
  return 0
}

main "$@"

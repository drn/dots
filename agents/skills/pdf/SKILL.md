---
name: pdf
description: Use when the user wants to export conversation content, or an existing HTML file such as a saved Claude Artifact, to a professionally styled PDF for sharing
---

# Export to PDF

Export summaries, research, or any content from the conversation to a professionally styled PDF for sharing. Also handles exporting an existing HTML file (for example, a saved Claude Artifact with inline SVG or custom CSS) directly to PDF.

## Arguments

- `$ARGUMENTS` - Optional: filename (without .pdf extension), "last" to export the last assistant message, or a path to an existing HTML file to export

## Instructions

You are exporting content from the current conversation to a shareable PDF document.

### Step 1: Identify Content to Export

First determine the content type, then what to export:

1. **Markdown/conversation content** (default): a summary, research, analysis, or other text from the conversation.
   - If user says "last" or no arguments: export the most recent substantive assistant response
   - If user provides a topic: find the relevant content from the conversation about that topic
   - If user provides specific text: use that text directly
   - Continue with Steps 2-4 below.
2. **Existing HTML file** (for example, a saved Claude Artifact with inline SVG or custom CSS): the user names or points to an `.html` file already on disk instead of asking to export conversation text. `md_to_pdf.py` only parses Markdown and cannot render arbitrary HTML, CSS, or inline SVG. Skip Steps 2-4 and follow "HTML File Export" instead.

### Step 2: Prepare the Content

(Markdown path only — for an existing HTML file, see "HTML File Export" below.)

Clean up the content for PDF export:

- Keep all markdown formatting (headers, tables, bullets, code blocks)
- Remove any conversation artifacts or meta-commentary
- Ensure links are preserved
- Keep the "Sources" section if present

### Step 3: Determine Filename and Title

Generate appropriate names:

- **Filename**: Use provided argument, or generate from content (e.g., `ai-orchestration-tools-2026`)
  - Use lowercase, hyphens for spaces
  - Keep under 50 characters
  - Add date suffix if relevant (e.g., `-2026-02-05`)
- **Title**: Generate a professional title from the content's main heading or topic

### Step 4: Generate PDF

Write the content to a temporary markdown file using a **Bash heredoc** (do NOT use the Write tool — it may be sandboxed to the workspace directory and reject `/tmp` paths), then convert to PDF:

```bash
# Write content to temp file — MUST use Bash heredoc, not the Write tool
cat << 'CONTENT_EOF' > /tmp/export_content.md
{markdown content here}
CONTENT_EOF

# Convert to PDF using the colocated script
python ~/.claude/skills/pdf/scripts/md_to_pdf.py \
  --input /tmp/export_content.md \
  --output {output_path}/{filename}.pdf \
  --title "{title}"
```

Determine `{output_path}` using the "Output Location" section below.

**Important:** Always use the Bash tool with `cat << 'CONTENT_EOF' > /tmp/...` for the temp file. The Write tool is sandboxed in some environments (e.g., Conductor workspaces) and will refuse paths outside the workspace.

### Step 5: Confirm and Offer Options

After creating the PDF:

1. Confirm the file was created with path and size
2. Offer to reveal or share it, using the commands under "Output Location" below for the current environment

## HTML File Export (Claude Artifacts, saved pages)

When exporting an existing HTML file instead of conversation markdown, skip `md_to_pdf.py` and render directly with `weasyprint`, a pure-Python HTML+CSS to PDF renderer that needs no browser. This is the only reliable path for HTML, CSS, or inline-SVG content — `md_to_pdf.py` (mistune + fpdf2) only understands Markdown.

```bash
# weasyprint is pure-Python and needs no browser, but depends on the
# cairo, pango, gdk-pixbuf, and glib system libraries (already present via
# Homebrew on most Mac development machines; install them first if missing)
pip3 install --quiet weasyprint

python3 -c "
import weasyprint
weasyprint.HTML(filename='{input_html_path}').write_pdf('{output_path}/{filename}.pdf')
"
```

Determine `{output_path}` using the "Output Location" section below, then confirm and offer options exactly as in Step 5.

## Argus Worktree Sandbox Notes

Check whether the session is running inside an Argus worktree sandbox: `$PWD` under `~/.argus/worktrees/`, or the `ARGUS_TASK_ID` environment variable set. Two things change in that environment:

- **Renderer choice for HTML content**: do not attempt raw headless Chrome (`--headless --print-to-pdf`) or a Playwright-managed browser to render HTML to PDF. Both fail or hang indefinitely inside this sandbox — sandbox initialization errors, GPU process crashes, or 120+ second hangs launching the browser — regardless of `--no-sandbox` or a Bash tool sandbox override. Do not retry these approaches with more flags; go straight to `weasyprint` instead.
- **Output location**: `~/Downloads` is not writable from inside an Argus worktree sandbox. This is a macOS TCC restriction on the sandboxed session, not something a sandbox override flag fixes. Write the output PDF to the session scratchpad directory instead, then reveal it with `open -R {path}` (reveals the file in Finder) rather than `open {path}` or a Downloads-based clipboard flow.

## Output Location

- **Normal session**: save PDFs to `~/Downloads/` by default for easy access and sharing. Offer to open the file (`open ~/Downloads/{filename}.pdf`) or copy its path to the clipboard (`echo ~/Downloads/{filename}.pdf | pbcopy`).
- **Argus worktree sandbox** (see notes above): save PDFs to the session scratchpad directory instead, since `~/Downloads` is not writable there. Reveal the result with `open -R {scratchpad_path}/{filename}.pdf` instead of opening or copying a Downloads path.

## Usage Examples

- `/pdf` - Export the last summary/research to PDF
- `/pdf last` - Same as above
- `/pdf ai-tools-research` - Export with custom filename
- "Export that to PDF" - Natural language trigger
- "Export this HTML artifact to PDF" - Renders an existing HTML file with weasyprint instead of the markdown path

## Technical Notes

- Markdown path: uses `mistune` + `fpdf2` (`pip install mistune fpdf2`); supports tables, code blocks, and full GitHub-flavored markdown
- HTML file path: uses `weasyprint` (`pip3 install weasyprint`); renders arbitrary HTML, CSS, and inline SVG directly with no browser dependency, at the cost of needing cairo/pango/gdk-pixbuf/glib system libraries
- Professional styling optimized for sharing with colleagues
- Script location: `scripts/md_to_pdf.py` (colocated in this skill directory, markdown path only)

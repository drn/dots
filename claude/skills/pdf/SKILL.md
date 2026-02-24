---
name: pdf
description: Use when the user wants to export conversation content to a professionally styled PDF for sharing
---

# Export to PDF

Export summaries, research, or any content from the conversation to a professionally styled PDF for sharing.

## Arguments

- `$ARGUMENTS` - Optional: filename (without .pdf extension) or "last" to export the last assistant message

## Instructions

You are exporting content from the current conversation to a shareable PDF document.

### Step 1: Identify Content to Export

Determine what content the user wants to export:

1. **If user says "last" or no arguments**: Export the most recent substantive assistant response (summary, research, analysis, etc.)
2. **If user provides a topic**: Find the relevant content from the conversation about that topic
3. **If user provides specific text**: Use that text directly

### Step 2: Prepare the Content

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

Write the content to a temporary markdown file and convert to PDF:

```bash
# Write content to temp file
cat << 'CONTENT_EOF' > /tmp/export_content.md
{markdown content here}
CONTENT_EOF

# Convert to PDF using the colocated script
python ~/.claude/skills/pdf/scripts/md_to_pdf.py \
  --input /tmp/export_content.md \
  --output ~/Downloads/{filename}.pdf \
  --title "{title}"
```

### Step 5: Confirm and Offer Options

After creating the PDF:

1. Confirm the file was created with path and size
2. Offer to:
   - Open the file: `open ~/Downloads/{filename}.pdf`
   - Copy to clipboard (the path): `echo ~/Downloads/{filename}.pdf | pbcopy`

## Output Location

PDFs are saved to `~/Downloads/` by default for easy access and sharing.

## Usage Examples

- `/pdf` - Export the last summary/research to PDF
- `/pdf last` - Same as above
- `/pdf ai-tools-research` - Export with custom filename
- "Export that to PDF" - Natural language trigger

## Technical Notes

- Uses `fpdf2` for PDF rendering (`pip install fpdf2`)
- Supports tables, code blocks, and full GitHub-flavored markdown
- Professional styling optimized for sharing with colleagues
- Script location: `scripts/md_to_pdf.py` (colocated in this skill directory)

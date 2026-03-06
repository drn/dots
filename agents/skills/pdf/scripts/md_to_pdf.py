#!/usr/bin/env python3
"""
Convert Markdown to a styled PDF.

Pipeline: Markdown → AST (mistune) → PDF (fpdf2 direct rendering)

Performance vs the previous hand-rolled parser:
- mistune AST parsing replaces fragile regex line-by-line scanning
- Binary-search table cell truncation replaces O(n²) character-by-character loop
- Proper handling of nested lists, blockquotes, and inline formatting

Dependencies: pip install mistune fpdf2

Usage:
    python md_to_pdf.py --output output.pdf --input content.md
    python md_to_pdf.py --output output.pdf --title "Report" < content.md
"""

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path

import mistune
from fpdf import FPDF
from fpdf.enums import XPos, YPos

# --- Unicode sanitization (latin-1 PDF fonts) ---

_UNICODE_MAP = {
    "\u2014": "--",
    "\u2013": "-",
    "\u2018": "'",
    "\u2019": "'",
    "\u201c": '"',
    "\u201d": '"',
    "\u2026": "...",
    "\u2022": "*",
    "\u00a0": " ",
    "\u2032": "'",
    "\u2033": '"',
}
_SANITIZE_RE = re.compile("|".join(re.escape(k) for k in _UNICODE_MAP))


def sanitize(text: str) -> str:
    """Single-pass Unicode replacement then latin-1 encoding."""
    text = _SANITIZE_RE.sub(lambda m: _UNICODE_MAP[m.group()], text)
    return text.encode("latin-1", errors="replace").decode("latin-1")


# --- Markdown parser (singleton) ---

_parser = mistune.create_markdown(renderer="ast", plugins=["table", "strikethrough"])


# --- Styled PDF ---


class StyledPDF(FPDF):
    """PDF with title header and page numbers."""

    def __init__(self, title=None):
        super().__init__()
        self.doc_title = title
        self.set_auto_page_break(auto=True, margin=25)
        self.add_page()
        self.set_font("Helvetica", size=11)
        self.set_text_color(51, 51, 51)
        if title:
            self._render_title(title)

    def _render_title(self, title):
        self.set_font("Helvetica", "B", 20)
        self.set_text_color(26, 26, 26)
        self.cell(0, 12, sanitize(title), new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font("Helvetica", "", 10)
        self.set_text_color(87, 96, 106)
        date_str = datetime.now().strftime("%B %d, %Y")
        self.cell(
            0, 6, f"Generated {date_str}", new_x=XPos.LMARGIN, new_y=YPos.NEXT
        )
        self.ln(4)
        self.set_draw_color(225, 228, 232)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(8)
        self.set_text_color(51, 51, 51)
        self.set_font("Helvetica", "", 11)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(102, 102, 102)
        self.cell(0, 10, str(self.page_no()), align="R")


# --- Inline rendering ---


def _flatten_inline(children):
    """Extract plain text from inline AST children."""
    parts = []
    for child in children:
        t = child.get("type", "")
        if t == "text":
            parts.append(child["raw"])
        elif t == "codespan":
            parts.append(child["raw"])
        elif t == "softbreak":
            parts.append(" ")
        elif t == "linebreak":
            parts.append("\n")
        elif "children" in child:
            parts.append(_flatten_inline(child["children"]))
    return "".join(parts)


def _render_inline(pdf, children, base_size=11):
    """Render inline AST nodes with bold/italic/code formatting."""
    for child in children:
        t = child.get("type", "")
        if t == "text":
            pdf.write(5, sanitize(child["raw"]))
        elif t == "strong":
            pdf.set_font("Helvetica", "B", base_size)
            _render_inline(pdf, child["children"], base_size)
            pdf.set_font("Helvetica", "", base_size)
        elif t == "emphasis":
            pdf.set_font("Helvetica", "I", base_size)
            _render_inline(pdf, child["children"], base_size)
            pdf.set_font("Helvetica", "", base_size)
        elif t == "codespan":
            pdf.set_font("Courier", "", base_size - 1)
            pdf.write(5, sanitize(child["raw"]))
            pdf.set_font("Helvetica", "", base_size)
        elif t == "link":
            # Render link text only (PDF links via fpdf2 are limited)
            _render_inline(pdf, child["children"], base_size)
        elif t == "softbreak":
            pdf.write(5, " ")
        elif t == "linebreak":
            pdf.ln(5)
        elif "children" in child:
            _render_inline(pdf, child["children"], base_size)


# --- Table rendering ---


def _truncate_to_fit(pdf, text, max_width):
    """Binary search for the longest prefix that fits within max_width."""
    if not text or pdf.get_string_width(text) <= max_width:
        return text
    lo, hi = 0, len(text)
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if pdf.get_string_width(text[:mid]) <= max_width - 4:
            lo = mid
        else:
            hi = mid - 1
    return text[:lo].rstrip() + ".."


def _render_table(pdf, token):
    """Render a table from AST tokens with proportional column widths."""
    # Collect all rows (head + body) as lists of plain-text cells
    rows = []
    head = next((c for c in token["children"] if c["type"] == "table_head"), None)
    body = next((c for c in token["children"] if c["type"] == "table_body"), None)

    if head:
        row_cells = [
            sanitize(_flatten_inline(cell.get("children", [])))
            for cell in head.get("children", [])
        ]
        rows.append(row_cells)

    if body:
        for table_row in body.get("children", []):
            row_cells = [
                sanitize(_flatten_inline(cell.get("children", [])))
                for cell in table_row.get("children", [])
            ]
            rows.append(row_cells)

    if not rows:
        return

    num_cols = len(rows[0])
    page_width = 190

    # Compute proportional column widths from content
    pdf.set_font("Helvetica", "B", 9)
    max_widths = [0.0] * num_cols
    for row in rows:
        for col, cell in enumerate(row):
            if col < num_cols:
                w = pdf.get_string_width(cell) + 4
                if w > max_widths[col]:
                    max_widths[col] = w

    # Scale widths to fit page
    min_col_width = 12
    total = sum(max_widths)
    if total > page_width:
        col_widths = [max(min_col_width, w * page_width / total) for w in max_widths]
        total_scaled = sum(col_widths)
        if total_scaled > page_width:
            col_widths = [w * page_width / total_scaled for w in col_widths]
    else:
        col_widths = [max(min_col_width, w) for w in max_widths]
        remaining = page_width - sum(col_widths)
        if remaining > 0:
            total_w = sum(col_widths)
            col_widths = [w + remaining * w / total_w for w in col_widths]

    # Font size for wide tables
    font_size = 9
    if num_cols >= 6:
        font_size = 7.5
    elif num_cols >= 5:
        font_size = 8

    row_height = 8

    for row_idx, row in enumerate(rows):
        if row_idx == 0:
            pdf.set_fill_color(246, 248, 250)
            pdf.set_font("Helvetica", "B", font_size)
        else:
            pdf.set_fill_color(249, 250, 251) if row_idx % 2 == 0 else pdf.set_fill_color(255, 255, 255)
            pdf.set_font("Helvetica", "", font_size)

        for col, cell in enumerate(row):
            if col < num_cols:
                w = col_widths[col]
                display = _truncate_to_fit(pdf, cell, w - 3)
                pdf.cell(w, row_height, display, border=1, fill=True)
        pdf.ln()

    pdf.ln(4)


# --- Block rendering ---

_HEADING_SIZES = {1: 18, 2: 14, 3: 12, 4: 11, 5: 11, 6: 11}


def _render_tokens(pdf, tokens):
    """Walk AST tokens and render each block to the PDF."""
    for token in tokens:
        t = token.get("type", "")

        if t == "blank_line":
            pdf.ln(3)

        elif t == "thematic_break":
            pdf.ln(4)
            pdf.set_draw_color(208, 215, 222)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(6)

        elif t == "heading":
            level = token.get("attrs", {}).get("level", 1)
            size = _HEADING_SIZES.get(level, 11)
            pdf.ln(4)
            pdf.set_font("Helvetica", "B", size)
            pdf.set_text_color(36, 41, 46)
            text = sanitize(_flatten_inline(token.get("children", [])))
            pdf.multi_cell(0, 7, text)
            pdf.set_text_color(51, 51, 51)
            pdf.set_font("Helvetica", "", 11)
            pdf.ln(2)

        elif t == "paragraph":
            pdf.set_font("Helvetica", "", 11)
            _render_inline(pdf, token.get("children", []))
            pdf.ln(6)

        elif t == "table":
            _render_table(pdf, token)

        elif t == "block_code":
            pdf.ln(2)
            pdf.set_fill_color(246, 248, 250)
            pdf.set_font("Courier", "", 9)
            code = sanitize(token.get("raw", "")).rstrip("\n")
            x = pdf.get_x()
            for code_line in code.split("\n"):
                pdf.set_x(x)
                pdf.cell(
                    190, 5, code_line, fill=True,
                    new_x=XPos.LMARGIN, new_y=YPos.NEXT,
                )
            pdf.set_font("Helvetica", "", 11)
            pdf.ln(2)

        elif t == "block_quote":
            pdf.set_font("Helvetica", "I", 11)
            pdf.set_text_color(87, 96, 106)
            for child in token.get("children", []):
                if child.get("type") == "paragraph":
                    text = sanitize(_flatten_inline(child.get("children", [])))
                    pdf.set_x(15)
                    pdf.multi_cell(175, 6, text)
            pdf.set_text_color(51, 51, 51)
            pdf.set_font("Helvetica", "", 11)
            pdf.ln(4)

        elif t == "list":
            ordered = token.get("attrs", {}).get("ordered", False)
            depth = token.get("attrs", {}).get("depth", 0)
            indent = min(depth, 2) * 5
            for i, item in enumerate(token.get("children", [])):
                if item.get("type") == "list_item":
                    pdf.set_x(15 + indent)
                    prefix = f"{i + 1}. " if ordered else "- "
                    pdf.write(5, prefix)
                    for child in item.get("children", []):
                        if child.get("type") in ("block_text", "paragraph"):
                            _render_inline(
                                pdf, child.get("children", [])
                            )
                        elif child.get("type") == "list":
                            pdf.ln(6)
                            _render_tokens(pdf, [child])
                            continue
                    pdf.ln(6)


# --- PDF creation ---


def create_pdf(md_content: str, output_path: Path, title=None) -> Path:
    """Create PDF from markdown content."""
    if title:
        md_content = re.sub(r"^#\s+.+\n*", "", md_content, count=1)

    tokens = _parser(md_content)

    pdf = StyledPDF(title)
    _render_tokens(pdf, tokens)
    pdf.output(output_path)
    return output_path


def main():
    parser = argparse.ArgumentParser(description="Convert Markdown to PDF")
    parser.add_argument("--output", "-o", required=True, help="Output PDF path")
    parser.add_argument("--title", "-t", help="Document title")
    parser.add_argument(
        "--input", "-i", help="Input markdown file (default: stdin)"
    )
    args = parser.parse_args()

    md_content = Path(args.input).read_text() if args.input else sys.stdin.read()
    if not md_content.strip():
        print("Error: No content provided", file=sys.stderr)
        sys.exit(1)

    output_path = Path(args.output).expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    create_pdf(md_content, output_path, args.title)
    print(f"PDF created: {output_path}")
    print(f"Size: {output_path.stat().st_size / 1024:.1f} KB")


if __name__ == "__main__":
    main()

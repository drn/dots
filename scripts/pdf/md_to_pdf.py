#!/usr/bin/env python3
"""
Convert Markdown content to a styled PDF.

Usage:
    python md_to_pdf.py --output output.pdf < content.md
    python md_to_pdf.py --output output.pdf --title "My Report" < content.md
    echo "# Hello" | python md_to_pdf.py --output hello.pdf
"""

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict

from fpdf import FPDF
from fpdf.enums import XPos, YPos


# Unicode to ASCII replacements for PDF compatibility
UNICODE_REPLACEMENTS = {
    '\u2014': '--',   # em dash
    '\u2013': '-',    # en dash
    '\u2018': "'",    # left single quote
    '\u2019': "'",    # right single quote
    '\u201c': '"',    # left double quote
    '\u201d': '"',    # right double quote
    '\u2026': '...',  # ellipsis
    '\u2022': '*',    # bullet
    '\u00a0': ' ',    # non-breaking space
    '\u2032': "'",    # prime
    '\u2033': '"',    # double prime
}


def sanitize_text(text: str) -> str:
    """Replace Unicode characters that aren't supported by standard PDF fonts."""
    for unicode_char, replacement in UNICODE_REPLACEMENTS.items():
        text = text.replace(unicode_char, replacement)
    # Remove any remaining non-latin1 characters
    return text.encode('latin-1', errors='replace').decode('latin-1')


class MarkdownPDF(FPDF):
    """Custom PDF class for markdown rendering."""

    def __init__(self, title: Optional[str] = None):
        super().__init__()
        self.doc_title = title
        self.set_auto_page_break(auto=True, margin=25)
        self.add_page()

        # Set up fonts
        self.set_font("Helvetica", size=11)

        # Add title if provided
        if title:
            self.set_font("Helvetica", "B", 20)
            self.set_text_color(26, 26, 26)
            self.cell(0, 12, sanitize_text(title), new_x=XPos.LMARGIN, new_y=YPos.NEXT)

            # Add date
            self.set_font("Helvetica", "", 10)
            self.set_text_color(87, 96, 106)
            date_str = datetime.now().strftime("%B %d, %Y")
            self.cell(0, 6, f"Generated {date_str}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

            # Add separator line
            self.ln(4)
            self.set_draw_color(225, 228, 232)
            self.line(10, self.get_y(), 200, self.get_y())
            self.ln(8)

            # Reset text color
            self.set_text_color(51, 51, 51)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "", 9)
        self.set_text_color(102, 102, 102)
        self.cell(0, 10, str(self.page_no()), align="R")


def parse_markdown(md_content: str) -> List[Dict]:
    """Parse markdown into structured elements."""
    elements = []
    lines = md_content.split('\n')
    i = 0
    in_code_block = False

    while i < len(lines):
        line = lines[i]

        # Fenced code blocks
        if re.match(r'^(`{3,}|~{3,})', line.strip()):
            if not in_code_block:
                in_code_block = True
                lang_match = re.match(r'^(`{3,}|~{3,})\s*(.*)', line.strip())
                lang = lang_match.group(2) if lang_match else ''
                code_lines = []
                fence = lang_match.group(1)[0]  # ` or ~
                fence_len = len(lang_match.group(1))
                i += 1
                while i < len(lines):
                    if re.match(r'^' + re.escape(fence) + '{' + str(fence_len) + r',}\s*$', lines[i].strip()):
                        i += 1
                        break
                    code_lines.append(lines[i])
                    i += 1
                in_code_block = False
                elements.append({'type': 'code_block', 'text': '\n'.join(code_lines), 'lang': lang})
                continue
            # Closing fence handled above; fallthrough shouldn't happen
            i += 1
            continue

        # Skip empty lines
        if not line.strip():
            elements.append({'type': 'blank'})
            i += 1
            continue

        # Horizontal rule
        if re.match(r'^-{3,}$|^\*{3,}$|^_{3,}$', line.strip()):
            elements.append({'type': 'hr'})
            i += 1
            continue

        # Headers
        header_match = re.match(r'^(#{1,6})\s+(.+)$', line)
        if header_match:
            level = len(header_match.group(1))
            text = header_match.group(2)
            elements.append({'type': 'header', 'level': level, 'text': text})
            i += 1
            continue

        # Table
        if '|' in line and i + 1 < len(lines) and re.match(r'^\|?\s*[-:]+', lines[i + 1]):
            table_lines = []
            while i < len(lines) and '|' in lines[i]:
                table_lines.append(lines[i])
                i += 1
            elements.append({'type': 'table', 'lines': table_lines})
            continue

        # Bullet list
        bullet_match = re.match(r'^(\s*)[-*+]\s+(.+)$', line)
        if bullet_match:
            indent = len(bullet_match.group(1))
            text = bullet_match.group(2)
            elements.append({'type': 'bullet', 'text': text, 'indent': indent})
            i += 1
            continue

        # Numbered list
        num_match = re.match(r'^(\s*)(\d+)\.\s+(.+)$', line)
        if num_match:
            indent = len(num_match.group(1))
            number = num_match.group(2)
            text = num_match.group(3)
            elements.append({'type': 'numbered', 'text': text, 'indent': indent, 'number': number})
            i += 1
            continue

        # Regular paragraph
        elements.append({'type': 'text', 'text': line})
        i += 1

    return elements


def render_text_with_formatting(pdf: FPDF, text: str, base_size: int = 11):
    """Render text with bold/italic/code formatting."""
    # Remove link markdown but keep text
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    # Sanitize for PDF compatibility
    text = sanitize_text(text)

    # Split by formatting markers
    parts = re.split(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)', text)

    for part in parts:
        if not part:
            continue

        if part.startswith('**') and part.endswith('**'):
            # Bold
            pdf.set_font("Helvetica", "B", base_size)
            pdf.write(5, part[2:-2])
            pdf.set_font("Helvetica", "", base_size)
        elif part.startswith('*') and part.endswith('*'):
            # Italic
            pdf.set_font("Helvetica", "I", base_size)
            pdf.write(5, part[1:-1])
            pdf.set_font("Helvetica", "", base_size)
        elif part.startswith('`') and part.endswith('`'):
            # Code
            pdf.set_font("Courier", "", base_size - 1)
            pdf.set_fill_color(246, 248, 250)
            pdf.write(5, part[1:-1])
            pdf.set_font("Helvetica", "", base_size)
        else:
            pdf.write(5, part)


def render_table(pdf: FPDF, table_lines: List[str]):
    """Render a markdown table with proportional column widths."""
    # Parse table
    rows = []
    for i, line in enumerate(table_lines):
        if i == 1 and re.match(r'^\|?\s*[-:]+', line):
            continue  # Skip separator row
        cells = [c.strip() for c in line.strip('|').split('|')]
        rows.append(cells)

    if not rows:
        return

    num_cols = len(rows[0])
    page_width = 190  # Available width

    # Clean all cells for width measurement
    clean_rows = []
    for row in rows:
        clean_row = []
        for cell in row:
            clean_cell = re.sub(r'\*\*([^*]+)\*\*', r'\1', cell)
            clean_cell = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', clean_cell)
            clean_cell = sanitize_text(clean_cell)
            clean_row.append(clean_cell)
        clean_rows.append(clean_row)

    # Calculate proportional column widths based on max content length
    pdf.set_font("Helvetica", "B", 9)
    max_widths = [0.0] * num_cols
    for row in clean_rows:
        for col_idx, cell in enumerate(row):
            if col_idx < num_cols:
                w = pdf.get_string_width(cell) + 4  # padding
                max_widths[col_idx] = max(max_widths[col_idx], w)

    # Scale widths to fit page, with minimum width
    min_col_width = 12
    total_natural = sum(max_widths)
    if total_natural > page_width:
        col_widths = [max(min_col_width, w * page_width / total_natural) for w in max_widths]
        # Re-scale after applying minimums
        total_scaled = sum(col_widths)
        if total_scaled > page_width:
            col_widths = [w * page_width / total_scaled for w in col_widths]
    else:
        col_widths = [max(min_col_width, w) for w in max_widths]
        # Distribute remaining space proportionally
        remaining = page_width - sum(col_widths)
        if remaining > 0:
            total_w = sum(col_widths)
            col_widths = [w + remaining * w / total_w for w in col_widths]

    # Determine font size — shrink for wide tables
    font_size = 9
    if num_cols >= 6:
        font_size = 7.5
    elif num_cols >= 5:
        font_size = 8

    row_height = 8

    for row_idx, clean_row in enumerate(clean_rows):
        # Header row
        if row_idx == 0:
            pdf.set_fill_color(246, 248, 250)
            pdf.set_font("Helvetica", "B", font_size)
        else:
            if row_idx % 2 == 0:
                pdf.set_fill_color(249, 250, 251)
            else:
                pdf.set_fill_color(255, 255, 255)
            pdf.set_font("Helvetica", "", font_size)

        for col_idx, cell in enumerate(clean_row):
            if col_idx < num_cols:
                w = col_widths[col_idx]
                # Extract link URL if present
                link_match = re.search(r'\[([^\]]+)\]\(([^)]+)\)', rows[row_idx][col_idx] if col_idx < len(rows[row_idx]) else '')
                link_url = link_match.group(2) if link_match else ''
                # Truncate text with ellipsis if it exceeds cell width
                display = cell
                while pdf.get_string_width(display) > w - 3 and len(display) > 1:
                    display = display[:-1]
                if display != cell:
                    display = display.rstrip() + '..'
                if link_url:
                    # Render as clickable link
                    pdf.set_text_color(0, 102, 204)
                    pdf.cell(w, row_height, display, border=1, fill=True, link=link_url)
                    pdf.set_text_color(51, 51, 51)
                else:
                    pdf.cell(w, row_height, display, border=1, fill=True)
        pdf.ln()

    pdf.ln(4)


def create_pdf(md_content: str, output_path: Path, title: Optional[str] = None) -> Path:
    """Create PDF from markdown content."""
    # When a title is provided, strip the leading H1 from markdown to avoid duplication
    if title:
        md_content = re.sub(r'^#\s+.+\n*', '', md_content, count=1)

    pdf = MarkdownPDF(title)

    elements = parse_markdown(md_content)

    for elem in elements:
        if elem['type'] == 'blank':
            pdf.ln(3)

        elif elem['type'] == 'hr':
            pdf.ln(4)
            pdf.set_draw_color(208, 215, 222)
            pdf.line(10, pdf.get_y(), 200, pdf.get_y())
            pdf.ln(6)

        elif elem['type'] == 'header':
            level = elem['level']
            text = elem['text']

            # Remove markdown formatting from header and sanitize
            text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
            text = sanitize_text(text)

            pdf.ln(4)
            if level == 1:
                pdf.set_font("Helvetica", "B", 18)
            elif level == 2:
                pdf.set_font("Helvetica", "B", 14)
            elif level == 3:
                pdf.set_font("Helvetica", "B", 12)
            else:
                pdf.set_font("Helvetica", "B", 11)

            pdf.set_text_color(36, 41, 46)
            pdf.multi_cell(0, 7, text)
            pdf.set_text_color(51, 51, 51)
            pdf.set_font("Helvetica", "", 11)
            pdf.ln(2)

        elif elem['type'] == 'table':
            render_table(pdf, elem['lines'])

        elif elem['type'] == 'bullet':
            indent = min(elem['indent'] // 2, 2)
            pdf.set_x(15 + indent * 5)
            pdf.write(5, "- ")
            render_text_with_formatting(pdf, elem['text'])
            pdf.ln(6)

        elif elem['type'] == 'numbered':
            indent = min(elem['indent'] // 2, 2)
            pdf.set_x(15 + indent * 5)
            pdf.write(5, f"{elem['number']}. ")
            render_text_with_formatting(pdf, elem['text'])
            pdf.ln(6)

        elif elem['type'] == 'code_block':
            pdf.ln(2)
            pdf.set_fill_color(246, 248, 250)
            pdf.set_font("Courier", "", 9)
            code_text = sanitize_text(elem['text'])
            x = pdf.get_x()
            for code_line in code_text.split('\n'):
                pdf.set_x(x)
                pdf.cell(190, 5, code_line, fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            pdf.set_font("Helvetica", "", 11)
            pdf.ln(2)

        elif elem['type'] == 'text':
            render_text_with_formatting(pdf, elem['text'])
            pdf.ln(6)

    pdf.output(output_path)
    return output_path


def main():
    parser = argparse.ArgumentParser(description='Convert Markdown to PDF')
    parser.add_argument('--output', '-o', required=True, help='Output PDF path')
    parser.add_argument('--title', '-t', help='Document title (optional)')
    parser.add_argument('--input', '-i', help='Input markdown file (default: stdin)')

    args = parser.parse_args()

    # Read markdown content
    if args.input:
        md_content = Path(args.input).read_text()
    else:
        md_content = sys.stdin.read()

    if not md_content.strip():
        print("Error: No content provided", file=sys.stderr)
        sys.exit(1)

    # Create PDF
    output_path = Path(args.output).expanduser()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    create_pdf(md_content, output_path, args.title)

    print(f"PDF created: {output_path}")
    print(f"Size: {output_path.stat().st_size / 1024:.1f} KB")


if __name__ == '__main__':
    main()

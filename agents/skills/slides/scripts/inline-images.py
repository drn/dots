#!/usr/bin/env python3
"""Inline an HTML deck's relative <img src="..."> assets as base64 data URIs.

The on-disk deck references screenshots by relative path. The Argus artifact
viewer sandbox has no relative-asset guarantee, so a self-contained copy is
needed before artifact_register. This reads each local image referenced in the
HTML, base64-encodes it, and rewrites src="name.png" -> src="data:...;base64,...".

Usage:
    python3 inline-images.py <input.html> [output.html]

Defaults output to /tmp/<input-stem>.inlined.html. Prints the output path.
"""
import base64
import mimetypes
import re
import sys
import tempfile
from pathlib import Path


def inline(input_path: Path, output_path: Path) -> None:
    html = input_path.read_text(encoding="utf-8")
    base_dir = input_path.parent

    def repl(match: re.Match) -> str:
        quote, src = match.group(1), match.group(2)
        # Skip already-inlined data URIs and remote URLs.
        if src.startswith(("data:", "http://", "https://", "//")):
            return match.group(0)
        asset = (base_dir / src).resolve()
        if not asset.is_file():
            print(f"  warn: asset not found, leaving as-is: {src}", file=sys.stderr)
            return match.group(0)
        mime = mimetypes.guess_type(asset.name)[0] or "application/octet-stream"
        b64 = base64.b64encode(asset.read_bytes()).decode("ascii")
        print(f"  inlined {src} ({len(b64)} b64 chars)", file=sys.stderr)
        return f'src={quote}data:{mime};base64,{b64}{quote}'

    html = re.sub(r'src=(["\'])([^"\']+)\1', repl, html)
    output_path.write_text(html, encoding="utf-8")
    print(output_path)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 1
    input_path = Path(sys.argv[1]).resolve()
    if not input_path.is_file():
        print(f"error: input not found: {input_path}", file=sys.stderr)
        return 1
    if len(sys.argv) >= 3:
        output_path = Path(sys.argv[2]).resolve()
    else:
        output_path = Path(tempfile.gettempdir()) / f"{input_path.stem}.inlined.html"
    inline(input_path, output_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())

---
name: docling
description: Convert reference files (PDF, DOCX, PPTX, XLSX, HTML, images) to Markdown before reading or acting on them. Use when user provides a non-Markdown file as context for an implementation task — "use this doc", "based on this file", "implement from this", or any path ending in .pdf/.docx/.pptx/.xlsx/.html/.htm/.png/.jpg/.jpeg/.gif/.webp/.tiff.
---

# Docling: Convert Reference Files Before Implementation

When a user provides a reference file in a non-Markdown format, convert it first, then read the result.

## When to Apply

Trigger when the user:
- Drops a file path ending in `.pdf`, `.docx`, `.pptx`, `.xlsx`, `.html`, `.htm`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.tiff`
- Says "use this doc", "based on this file", "implement from this", "use this reference", or similar
- References any file that isn't already `.md` or `.txt`

## How to Convert

### Primary: Python CLI (preferred)

```bash
docling "<file>" --to md --output /tmp/docling-output
```

Output lands in `/tmp/docling-output/<filename>.md`. Read that file, then proceed.

If `docling` is not installed:

```bash
pip install docling --break-system-packages -q
```

### Image-based PDFs (blank pages / no embedded text)

If the output is empty or 0 bytes, the PDF is image-based. Add `--force-ocr`:

```bash
pip install onnxruntime --break-system-packages -q  # required for rapidocr
docling "<file>" --to md --output /tmp/docling-output --force-ocr --ocr-engine rapidocr
```

### Fallback: Docker script

Only use if Python CLI is unavailable. **Fails in Docker-in-Docker environments** (volume mounts reference host filesystem, not agent container).

```bash
~/.claude/scripts/docling.sh --to md --output /tmp/docling-output <file>
```

## Example

User says: "Build the API based on spec.pdf"

```bash
docling "/path/to/spec.pdf" --to md --output /tmp/docling-output
# then read /tmp/docling-output/spec.md
```

## Reading the Output

Strip embedded base64 images before reading large markdown files:

```python
import re
with open('/tmp/docling-output/file.md') as f:
    content = f.read()
clean = re.sub(r'!\[Image\]\(data:image/[^)]+\)', '[IMAGE]', content)
print(clean)
```

## Notes

- Output filename matches input filename with `.md` extension
- Files with spaces in path: quote the path — Python CLI handles spaces correctly
- First run downloads models (~500MB OCR models). Subsequent runs use cache
- Images: OCR applied automatically without `--force-ocr` for text-layer PDFs
- HTML: strips markup, extracts structured text
- If output is 0 bytes after `--force-ocr`, the PDF may have white-on-white content or DRM — use Claude's built-in PDF reader (`Read` tool) as last resort

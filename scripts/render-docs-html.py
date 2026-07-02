#!/usr/bin/env python3
"""Render repository Markdown docs into one consolidated HTML file."""

from __future__ import annotations

import argparse
import datetime as dt
import html
import re
import shutil
from pathlib import Path
from typing import NamedTuple

import markdown


EXCLUDED_DIRS = {
    ".git",
    ".github",
    ".tmp",
    ".cache",
    ".local",
    "sources",
    "out",
    "build",
}

ASSET_EXTENSIONS = {
  ".png",
  ".jpg",
  ".jpeg",
  ".gif",
  ".svg",
  ".webp",
}

IMAGE_PATH_PATTERN = r"[^\s`'\")>]+\.(?:png|jpg|jpeg|gif|svg|webp)"


class ImageRef(NamedTuple):
  path: str
  explanation: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build one HTML document from repository Markdown files."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Repository root directory (default: current directory).",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output HTML file path.",
    )
    return parser.parse_args()


def doc_sort_key(rel_path: str) -> tuple[int, str]:
    if rel_path == "README.md":
        return (0, rel_path)
    if rel_path.startswith("docs/"):
        return (1, rel_path)
    if rel_path.startswith("apps/"):
        return (2, rel_path)
    if rel_path.startswith("scripts/"):
        return (3, rel_path)
    return (4, rel_path)


def should_include(path: Path, root: Path) -> bool:
    if path.suffix.lower() != ".md":
        return False

    rel = path.relative_to(root)
    if any(part in EXCLUDED_DIRS for part in rel.parts):
        return False
    return True


def discover_docs(root: Path) -> list[Path]:
    docs = [p for p in root.rglob("*.md") if should_include(p, root)]
    docs.sort(key=lambda p: doc_sort_key(str(p.relative_to(root))))
    return docs


def should_include_asset(path: Path, root: Path) -> bool:
  if path.suffix.lower() not in ASSET_EXTENSIONS:
    return False

  rel = path.relative_to(root)
  if any(part in EXCLUDED_DIRS for part in rel.parts):
    return False
  return True


def discover_assets(root: Path) -> list[Path]:
  assets = [p for p in root.rglob("*") if p.is_file() and should_include_asset(p, root)]
  assets.sort(key=lambda p: str(p.relative_to(root)))
  return assets


def copy_assets(root: Path, output_dir: Path, assets: list[Path]) -> None:
  for asset in assets:
    rel = asset.relative_to(root)
    target = output_dir / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(asset, target)


def first_heading(markdown_text: str, fallback: str) -> str:
    match = re.search(r"^#\s+(.+)$", markdown_text, flags=re.MULTILINE)
    if match:
        return match.group(1).strip()
    return fallback


def to_anchor_id(rel_path: str) -> str:
    sanitized = re.sub(r"[^a-zA-Z0-9]+", "-", rel_path).strip("-").lower()
    return f"doc-{sanitized}"


def humanize_filename(path: str) -> str:
  stem = Path(path).stem
  words = re.sub(r"[-_]+", " ", stem).strip()
  return words.capitalize() if words else path


def normalize_local_path(raw_path: str) -> str | None:
  path = raw_path.strip().strip("<>").strip("\"'")
  if not path:
    return None
  if path.startswith(("http://", "https://", "data:", "#")):
    return None
  if path.startswith("./"):
    return path[2:]
  return path


def extract_image_references(markdown_text: str) -> list[ImageRef]:
  refs: list[ImageRef] = []
  seen: set[str] = set()

  # Prefer rich explanations from the table form:
  # | Diagram title | `docs/diagrams/file.png` | ... |
  table_row_re = re.compile(
    rf"^\|\s*(?P<title>[^|]+?)\s*\|\s*`?(?P<path>{IMAGE_PATH_PATTERN})`?\s*\|",
    flags=re.IGNORECASE,
  )
  for line in markdown_text.splitlines():
    match = table_row_re.match(line)
    if not match:
      continue
    local_path = normalize_local_path(match.group("path"))
    if not local_path or local_path in seen:
      continue
    explanation = match.group("title").strip()
    refs.append(ImageRef(local_path, explanation))
    seen.add(local_path)

  # Support explicit markdown image syntax.
  image_md_re = re.compile(
    rf"!\[(?P<alt>[^\]]*)\]\((?P<path>{IMAGE_PATH_PATTERN})\)",
    flags=re.IGNORECASE,
  )
  for match in image_md_re.finditer(markdown_text):
    local_path = normalize_local_path(match.group("path"))
    if not local_path or local_path in seen:
      continue
    alt = match.group("alt").strip()
    explanation = alt if alt else f"Diagram: {humanize_filename(local_path)}"
    refs.append(ImageRef(local_path, explanation))
    seen.add(local_path)

  # Fallback: code-formatted image paths.
  code_path_re = re.compile(
    rf"`(?P<path>{IMAGE_PATH_PATTERN})`",
    flags=re.IGNORECASE,
  )
  for match in code_path_re.finditer(markdown_text):
    local_path = normalize_local_path(match.group("path"))
    if not local_path or local_path in seen:
      continue
    refs.append(
      ImageRef(
        local_path,
        f"Referenced image: {humanize_filename(local_path)}",
      )
    )
    seen.add(local_path)

  return refs


def file_within_root(path: Path, root: Path) -> bool:
  try:
    path.relative_to(root)
    return True
  except ValueError:
    return False


def render_html(root: Path, docs: list[Path]) -> str:
    now = dt.datetime.now(dt.UTC).strftime("%Y-%m-%d %H:%M UTC")
    nav_items: list[str] = []
    sections: list[str] = []

    for path in docs:
        rel_path = str(path.relative_to(root))
        source_text = path.read_text(encoding="utf-8")
        heading = first_heading(source_text, rel_path)
        anchor = to_anchor_id(rel_path)
        image_refs = extract_image_references(source_text)

        md = markdown.Markdown(
            extensions=["fenced_code", "tables", "sane_lists", "toc"],
            output_format="html5",
        )
        body = md.convert(source_text)

        image_cards: list[str] = []
        for ref in image_refs:
            img_abs = (root / ref.path).resolve()
            if not file_within_root(img_abs, root):
                continue
            if not img_abs.is_file() or img_abs.suffix.lower() not in ASSET_EXTENSIONS:
                continue
            img_path = str(img_abs.relative_to(root))
            image_cards.append(
                "\n".join(
                    [
                        '<figure class="doc-figure">',
                        (
                            f'<img src="{html.escape(img_path)}" '
                            f'alt="{html.escape(ref.explanation)}" loading="lazy" />'
                        ),
                        "<figcaption>",
                        f"<strong>{html.escape(ref.explanation)}</strong>",
                        (
                            '<p class="doc-figure-path">'
                            f'Path: <code>{html.escape(ref.path)}</code>'
                            "</p>"
                        ),
                        "</figcaption>",
                        "</figure>",
                    ]
                )
            )

        image_section = ""
        if image_cards and rel_path != "docs/diagram-gallery.md":
            image_section = "\n".join(
                [
                    '<div class="doc-images" aria-label="Referenced images">',
                    "<h3>Referenced Images</h3>",
                    '<p class="doc-images-note">'
                    "Auto-included preview and explanation for image paths referenced "
                    "in this document section."
                    "</p>",
                    '<div class="doc-image-grid">',
                    "".join(image_cards),
                    "</div>",
                    "</div>",
                ]
            )

        nav_items.append(
            f'<li><a href="#{anchor}">{html.escape(heading)}</a></li>'
        )
        sections.append(
            "\n".join(
                [
              (
                f'<section id="{anchor}" class="doc-section'
                f'{" doc-gallery-section" if rel_path == "docs/diagram-gallery.md" else ""}">'
              ),
                    '<div class="doc-meta">',
                    f"<h2>{html.escape(heading)}</h2>",
                    f'<p class="doc-path">Source: {html.escape(rel_path)}</p>',
                    "</div>",
                    '<div class="doc-content">',
                    body,
                    image_section,
                    "</div>",
                    "</section>",
                ]
            )
        )

    return f"""<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Yocto Project Documentation</title>
    <style>
      :root {{
        --bg: #f7f7f5;
        --surface: #ffffff;
        --line: #d9ddd7;
        --text: #18211a;
        --muted: #5f6b61;
        --accent: #0f6b3f;
        --code-bg: #f2f5f2;
      }}
      * {{ box-sizing: border-box; }}
      body {{
        margin: 0;
        font-family: "Segoe UI", "Helvetica Neue", Helvetica, Arial, sans-serif;
        color: var(--text);
        background: radial-gradient(circle at 10% 10%, #edf5ef, var(--bg) 35%);
      }}
      .layout {{
        display: grid;
        grid-template-columns: 300px 1fr;
        min-height: 100vh;
      }}
      aside {{
        border-right: 1px solid var(--line);
        background: #f0f4ef;
        padding: 1.25rem;
        position: sticky;
        top: 0;
        max-height: 100vh;
        overflow: auto;
      }}
      aside h1 {{
        margin: 0 0 0.4rem;
        font-size: 1.2rem;
      }}
      aside p {{
        margin: 0 0 1rem;
        color: var(--muted);
        font-size: 0.9rem;
      }}
      aside ul {{
        margin: 0;
        padding: 0;
        list-style: none;
      }}
      aside li {{
        margin: 0.15rem 0;
      }}
      aside a {{
        color: var(--text);
        text-decoration: none;
        display: block;
        border-left: 3px solid transparent;
        padding: 0.35rem 0.5rem;
      }}
      aside a:hover {{
        border-left-color: var(--accent);
        background: #e5eee6;
      }}
      main {{
        padding: 1.5rem 2rem;
      }}
      .doc-section {{
        background: var(--surface);
        border: 1px solid var(--line);
        border-radius: 12px;
        margin: 0 0 1.2rem;
        padding: 1.1rem 1.2rem;
      }}
      .doc-section h2 {{
        margin: 0 0 0.25rem;
      }}
      .doc-path {{
        margin: 0;
        color: var(--muted);
        font-size: 0.9rem;
      }}
      .doc-content pre {{
        overflow: auto;
        padding: 0.75rem;
        border-radius: 8px;
        background: var(--code-bg);
      }}
      .doc-content code {{
        background: var(--code-bg);
        padding: 0.1rem 0.3rem;
        border-radius: 4px;
      }}
      .doc-content table {{
        border-collapse: collapse;
        width: 100%;
      }}
      .doc-content th,
      .doc-content td {{
        border: 1px solid var(--line);
        padding: 0.45rem 0.6rem;
        text-align: left;
      }}
      .doc-content img {{
        display: block;
        max-width: 100%;
        height: auto;
        border: 1px solid var(--line);
        border-radius: 10px;
        margin: 0.6rem 0 1rem;
        background: #f8fbf8;
      }}
      .doc-gallery-section .doc-content h2 {{
        margin-top: 1.2rem;
        padding-top: 0.8rem;
        border-top: 1px dashed var(--line);
      }}
      .doc-images {{
        margin-top: 1.2rem;
        border-top: 1px dashed var(--line);
        padding-top: 1rem;
      }}
      .doc-images h3 {{
        margin: 0 0 0.35rem;
      }}
      .doc-images-note {{
        margin: 0 0 0.75rem;
        color: var(--muted);
        font-size: 0.9rem;
      }}
      .doc-image-grid {{
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 0.75rem;
      }}
      .doc-figure {{
        margin: 0;
        border: 1px solid var(--line);
        border-radius: 10px;
        background: #fbfdfb;
        overflow: hidden;
      }}
      .doc-figure img {{
        display: block;
        width: 100%;
        height: auto;
        border-bottom: 1px solid var(--line);
      }}
      .doc-figure figcaption {{
        padding: 0.6rem 0.7rem;
      }}
      .doc-figure-path {{
        margin: 0.35rem 0 0;
        color: var(--muted);
        font-size: 0.88rem;
      }}
      @media (max-width: 980px) {{
        .layout {{
          grid-template-columns: 1fr;
        }}
        aside {{
          position: static;
          max-height: none;
          border-right: 0;
          border-bottom: 1px solid var(--line);
        }}
        main {{
          padding: 1rem;
        }}
      }}
    </style>
  </head>
  <body>
    <div class="layout">
      <aside>
        <h1>Project Docs</h1>
        <p>Generated {html.escape(now)}</p>
        <ul>
          {"".join(nav_items)}
        </ul>
      </aside>
      <main>
        {"".join(sections)}
      </main>
    </div>
  </body>
</html>
"""


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    output = Path(args.output).resolve()

    docs = discover_docs(root)
    if not docs:
        raise SystemExit("No markdown files found to build docs.")

    assets = discover_assets(root)

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_html(root, docs), encoding="utf-8")
    copy_assets(root, output.parent, assets)

    print(
      f"Generated {output} from {len(docs)} markdown files and {len(assets)} assets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
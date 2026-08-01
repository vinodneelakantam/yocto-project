#!/usr/bin/env python3
"""Parse BitBake cooker logs and generate task/recipe/stage visualizations.

Outputs:
- tasks.csv: event-level rows across task queue and recipe task status updates.
- recipe_stage_summary.csv: per-recipe per-stage counters.
- stage_summary.csv: global stage counters.
- report.html: simple dashboard with sortable tables.

Optional:
- Render task-depends.dot and pn-depends.dot to SVG if Graphviz dot is available.
"""

from __future__ import annotations

import argparse
import csv
import html
import json
import re
import shutil
import subprocess
from collections import Counter, defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

RUNNING_RE = re.compile(r"NOTE: Running task (?P<idx>\d+) of (?P<total>\d+) \((?P<entry>.+):(?P<task>do_[^)]+)\)")
RUNNING_NOEXEC_RE = re.compile(r"NOTE: Running noexec task (?P<idx>\d+) of (?P<total>\d+) \((?P<entry>.+):(?P<task>do_[^)]+)\)")
RECIPE_RE = re.compile(r"NOTE: recipe (?P<recipe>[^:]+): task (?P<task>do_[^:]+): (?P<status>Started|Succeeded|Failed)")


@dataclass
class TaskEvent:
    line_no: int
    event_type: str
    queue_index: int | None
    queue_total: int | None
    recipe: str
    recipe_file: str
    task: str
    stage: str
    status: str


def stage_from_task(task: str) -> str:
    return task[3:] if task.startswith("do_") else task


def recipe_from_entry(entry: str) -> tuple[str, str]:
    recipe_file = entry
    if ":" in entry and entry.startswith("virtual:"):
        parts = entry.split(":", 2)
        recipe_file = parts[2] if len(parts) == 3 else entry

    bb_name = Path(recipe_file).name
    recipe = bb_name[:-3] if bb_name.endswith(".bb") else bb_name
    return recipe, recipe_file


def parse_events(lines: Iterable[str]) -> list[TaskEvent]:
    events: list[TaskEvent] = []

    for line_no, line in enumerate(lines, start=1):
        line = line.rstrip("\n")

        m = RUNNING_RE.match(line)
        if m:
            recipe, recipe_file = recipe_from_entry(m.group("entry"))
            task = m.group("task")
            events.append(
                TaskEvent(
                    line_no=line_no,
                    event_type="queue",
                    queue_index=int(m.group("idx")),
                    queue_total=int(m.group("total")),
                    recipe=recipe,
                    recipe_file=recipe_file,
                    task=task,
                    stage=stage_from_task(task),
                    status="queued",
                )
            )
            continue

        m = RUNNING_NOEXEC_RE.match(line)
        if m:
            recipe, recipe_file = recipe_from_entry(m.group("entry"))
            task = m.group("task")
            events.append(
                TaskEvent(
                    line_no=line_no,
                    event_type="queue-noexec",
                    queue_index=int(m.group("idx")),
                    queue_total=int(m.group("total")),
                    recipe=recipe,
                    recipe_file=recipe_file,
                    task=task,
                    stage=stage_from_task(task),
                    status="noexec",
                )
            )
            continue

        m = RECIPE_RE.match(line)
        if m:
            task = m.group("task")
            recipe = m.group("recipe")
            events.append(
                TaskEvent(
                    line_no=line_no,
                    event_type="recipe-status",
                    queue_index=None,
                    queue_total=None,
                    recipe=recipe,
                    recipe_file="",
                    task=task,
                    stage=stage_from_task(task),
                    status=m.group("status").lower(),
                )
            )

    return events


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def make_recipe_stage_summary(events: list[TaskEvent]) -> list[dict]:
    counters: dict[tuple[str, str], Counter] = defaultdict(Counter)

    for e in events:
        counters[(e.recipe, e.stage)][e.status] += 1

    rows = []
    for (recipe, stage), c in sorted(counters.items(), key=lambda item: (item[0][0], item[0][1])):
        rows.append(
            {
                "recipe": recipe,
                "stage": stage,
                "queued": c["queued"],
                "started": c["started"],
                "succeeded": c["succeeded"],
                "failed": c["failed"],
                "noexec": c["noexec"],
                "events_total": sum(c.values()),
            }
        )
    return rows


def make_stage_summary(events: list[TaskEvent]) -> list[dict]:
    counters: dict[str, Counter] = defaultdict(Counter)
    for e in events:
        counters[e.stage][e.status] += 1

    rows = []
    for stage, c in sorted(counters.items()):
        rows.append(
            {
                "stage": stage,
                "queued": c["queued"],
                "started": c["started"],
                "succeeded": c["succeeded"],
                "failed": c["failed"],
                "noexec": c["noexec"],
                "events_total": sum(c.values()),
            }
        )
    return rows


def top_failed_recipes(events: list[TaskEvent], limit: int = 20) -> list[tuple[str, int]]:
    failed = Counter(e.recipe for e in events if e.status == "failed")
    return failed.most_common(limit)


def table_html(rows: list[dict], columns: list[str]) -> str:
    header = "".join(f"<th>{html.escape(col)}</th>" for col in columns)
    body_rows = []
    for row in rows:
        cells = "".join(f"<td>{html.escape(str(row.get(col, '')))}</td>" for col in columns)
        body_rows.append(f"<tr>{cells}</tr>")
    body = "\n".join(body_rows)
    return f"<table><thead><tr>{header}</tr></thead><tbody>{body}</tbody></table>"


def build_report(events: list[TaskEvent], recipe_stage_rows: list[dict], stage_rows: list[dict]) -> str:
    totals = Counter(e.status for e in events)
    failed_top = top_failed_recipes(events)
    failed_rows = [{"recipe": recipe, "failed_events": count} for recipe, count in failed_top]

    report = [
        "<!doctype html>",
        "<html lang=\"en\">",
        "<head>",
        "<meta charset=\"utf-8\">",
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
        "<title>BitBake Log Visualization</title>",
        "<style>",
        "body { font-family: 'Segoe UI', Tahoma, sans-serif; margin: 24px; background: #f7fafc; color: #111827; }",
        "h1, h2 { margin-top: 1.2rem; }",
        ".cards { display: grid; gap: 12px; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); }",
        ".card { background: #fff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 12px; }",
        ".label { color: #6b7280; font-size: 0.85rem; }",
        ".value { font-size: 1.5rem; font-weight: 700; }",
        "table { width: 100%; border-collapse: collapse; background: #fff; border: 1px solid #e5e7eb; border-radius: 8px; overflow: hidden; }",
        "th, td { padding: 8px 10px; border-bottom: 1px solid #f1f5f9; text-align: left; font-size: 0.9rem; }",
        "thead { background: #f8fafc; position: sticky; top: 0; }",
        "section { margin-bottom: 20px; }",
        "</style>",
        "</head>",
        "<body>",
        "<h1>BitBake Cooker Log Dashboard</h1>",
        "<div class=\"cards\">",
        f"<div class=\"card\"><div class=\"label\">Total events</div><div class=\"value\">{len(events)}</div></div>",
        f"<div class=\"card\"><div class=\"label\">Queued</div><div class=\"value\">{totals['queued']}</div></div>",
        f"<div class=\"card\"><div class=\"label\">Started</div><div class=\"value\">{totals['started']}</div></div>",
        f"<div class=\"card\"><div class=\"label\">Succeeded</div><div class=\"value\">{totals['succeeded']}</div></div>",
        f"<div class=\"card\"><div class=\"label\">Failed</div><div class=\"value\">{totals['failed']}</div></div>",
        f"<div class=\"card\"><div class=\"label\">Noexec</div><div class=\"value\">{totals['noexec']}</div></div>",
        "</div>",
        "<section><h2>Stage Summary</h2>",
        table_html(stage_rows, ["stage", "queued", "started", "succeeded", "failed", "noexec", "events_total"]),
        "</section>",
        "<section><h2>Top Failed Recipes</h2>",
        table_html(failed_rows or [{"recipe": "none", "failed_events": 0}], ["recipe", "failed_events"]),
        "</section>",
        "<section><h2>Recipe x Stage Summary</h2>",
        table_html(recipe_stage_rows, ["recipe", "stage", "queued", "started", "succeeded", "failed", "noexec", "events_total"]),
        "</section>",
        "</body></html>",
    ]
    return "\n".join(report)


def maybe_render_dot(dot_input: Path, svg_out: Path) -> bool:
    if not dot_input.exists() or shutil.which("dot") is None:
        return False

    svg_out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["dot", "-Tsvg", str(dot_input), "-o", str(svg_out)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return svg_out.exists()


def main() -> int:
    parser = argparse.ArgumentParser(description="Visualize BitBake cooker logs by task, recipe, and stage.")
    parser.add_argument("log", type=Path, help="Path to cooker log file")
    parser.add_argument("--out-dir", type=Path, default=None, help="Output directory (default: <log-dir>/visualization)")
    parser.add_argument(
        "--dot-dir",
        type=Path,
        default=None,
        help="Directory containing task-depends.dot and pn-depends.dot to render to SVG",
    )
    args = parser.parse_args()

    log_path = args.log
    if not log_path.exists():
        raise SystemExit(f"Log file not found: {log_path}")

    out_dir = args.out_dir or (log_path.parent / "visualization")
    out_dir.mkdir(parents=True, exist_ok=True)

    with log_path.open("r", encoding="utf-8", errors="replace") as f:
        events = parse_events(f)

    task_rows = [asdict(e) for e in events]
    recipe_stage_rows = make_recipe_stage_summary(events)
    stage_rows = make_stage_summary(events)

    write_csv(
        out_dir / "tasks.csv",
        task_rows,
        ["line_no", "event_type", "queue_index", "queue_total", "recipe", "recipe_file", "task", "stage", "status"],
    )
    write_csv(
        out_dir / "recipe_stage_summary.csv",
        recipe_stage_rows,
        ["recipe", "stage", "queued", "started", "succeeded", "failed", "noexec", "events_total"],
    )
    write_csv(
        out_dir / "stage_summary.csv",
        stage_rows,
        ["stage", "queued", "started", "succeeded", "failed", "noexec", "events_total"],
    )

    report = build_report(events, recipe_stage_rows, stage_rows)
    (out_dir / "report.html").write_text(report, encoding="utf-8")

    meta = {
        "input_log": str(log_path),
        "out_dir": str(out_dir),
        "event_count": len(events),
        "dot_rendered": {},
    }

    if args.dot_dir:
        dot_dir = args.dot_dir
        for name in ("task-depends", "pn-depends"):
            rendered = maybe_render_dot(dot_dir / f"{name}.dot", out_dir / f"{name}.svg")
            meta["dot_rendered"][name] = rendered

    (out_dir / "meta.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"Generated visualization artifacts in: {out_dir}")
    print(f"Open report: {out_dir / 'report.html'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

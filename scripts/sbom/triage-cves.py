#!/usr/bin/env python3
"""Gate a release on unwaived CVEs from a Yocto cve-check JSON manifest.

Reads the `<image>.json` manifest produced by bitbake's cve-check class
(enabled via ENABLE_CVE_CHECK=true, see scripts/remote-build.sh) and fails
(non-zero exit) if any Unpatched CVE meets or exceeds the severity threshold
and has no active waiver in cve-waivers.json.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import date
from pathlib import Path

DEFAULT_SEVERITY_THRESHOLD = 7.0


def load_waivers(path: Path) -> dict[str, dict]:
    if not path.is_file():
        return {}
    data = json.loads(path.read_text())
    return {entry["cve"]: entry for entry in data.get("waivers", []) if entry.get("cve")}


def score_of(issue: dict) -> float:
    for key in ("scorev4", "scorev3", "scorev2"):
        value = issue.get(key)
        if value in (None, "", "0"):
            continue
        try:
            return float(value)
        except ValueError:
            continue
    return 0.0


def is_waiver_active(waiver: dict, today: date) -> bool:
    expires = waiver.get("expires")
    if not expires:
        return True
    try:
        return date.fromisoformat(expires) >= today
    except ValueError:
        return False


def render_table(rows: list[dict], extra_col: str) -> list[str]:
    lines = [f"| CVE | Package | Version | Score | {extra_col} |", "|---|---|---|---:|---|"]
    for row in sorted(rows, key=lambda r: -r["score"]):
        lines.append(f"| {row['cve']} | {row['package']} | {row['version']} | {row['score']} | {row[extra_col.lower()]} |")
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="Path to the cve-check *.json manifest")
    parser.add_argument("--waivers", type=Path, default=Path("scripts/sbom/cve-waivers.json"))
    parser.add_argument("--threshold", type=float, default=DEFAULT_SEVERITY_THRESHOLD)
    parser.add_argument("--report", type=Path, help="Optional markdown report output path")
    args = parser.parse_args()

    if not args.manifest.is_file():
        print(f"ERROR: CVE manifest not found: {args.manifest}", file=sys.stderr)
        print("Hint: build with ENABLE_CVE_CHECK=true so cve-check produces this manifest.", file=sys.stderr)
        return 1

    manifest = json.loads(args.manifest.read_text())
    waivers = load_waivers(args.waivers)
    today = date.today()

    blocking = []
    waived = []
    for package in manifest.get("package", []):
        for issue in package.get("issue", []):
            if issue.get("status") != "Unpatched":
                continue
            score = score_of(issue)
            if score < args.threshold:
                continue
            cve = issue["id"]
            row = {
                "cve": cve,
                "package": package["name"],
                "version": package["version"],
                "score": score,
                "link": issue.get("link", ""),
            }
            waiver = waivers.get(cve)
            if waiver and is_waiver_active(waiver, today):
                waived.append({**row, "reason": waiver.get("reason", "")})
            else:
                blocking.append(row)

    lines = [
        "# CVE Triage Summary",
        "",
        f"Threshold: CVSS >= {args.threshold}  ·  Generated: {today.isoformat()}",
        "",
        f"- Blocking (unwaived): {len(blocking)}",
        f"- Waived: {len(waived)}",
        "",
    ]

    if blocking:
        lines.append("## Blocking CVEs")
        lines.append("")
        lines.extend(render_table(blocking, "Link"))
        lines.append("")

    if waived:
        lines.append("## Waived CVEs")
        lines.append("")
        lines.extend(render_table(waived, "Reason"))
        lines.append("")

    report_text = "\n".join(lines)
    print(report_text)

    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(report_text + "\n")

    if blocking:
        print(f"\nFAIL: {len(blocking)} unwaived CVE(s) at or above severity {args.threshold}.", file=sys.stderr)
        return 1

    print("\nPASS: no unwaived CVEs at or above the severity threshold.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

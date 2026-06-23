#!/usr/bin/env python3
"""Vehicle CLI — a small COVESA VSS-style signal client.

Part of the SDV vehicle-signal service.  Demonstrates the Python side of the
C/C++/Python Bazel stack.  Pure standard library so it runs unchanged on the
Yocto target's python3 with no extra rootfs packages.
"""

from __future__ import annotations

import argparse
import sys
from typing import Dict, List, Optional, Sequence

# A few well-known COVESA Vehicle Signal Specification (VSS) paths used as the
# default catalogue when no live broker is available.
DEFAULT_SIGNALS: Dict[str, float] = {
    "Vehicle.Speed": 0.0,
    "Vehicle.Powertrain.Battery.StateOfCharge": 87.5,
    "Vehicle.CurrentLocation.Heading": 90.0,
}


def list_signals(catalogue: Dict[str, float]) -> List[str]:
    """Return signal paths sorted for stable, testable output."""
    return sorted(catalogue)


def get_signal(catalogue: Dict[str, float], path: str) -> Optional[float]:
    """Return the value for a VSS path, or None when it is unknown."""
    return catalogue.get(path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="vehicle-cli",
        description="Inspect COVESA VSS-style vehicle signals.",
    )
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("list", help="List known signal paths.")
    get_parser = sub.add_parser("get", help="Get the value of a signal path.")
    get_parser.add_argument("path", help="VSS signal path, e.g. Vehicle.Speed")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = build_parser().parse_args(argv)
    catalogue = dict(DEFAULT_SIGNALS)

    if args.command == "list":
        for path in list_signals(catalogue):
            print(path)
        return 0

    if args.command == "get":
        value = get_signal(catalogue, args.path)
        if value is None:
            print(f"unknown signal: {args.path}", file=sys.stderr)
            return 1
        print(f"{args.path} = {value}")
        return 0

    return 2


if __name__ == "__main__":
    raise SystemExit(main())

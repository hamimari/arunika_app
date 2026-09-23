#!/usr/bin/env python3
"""Coverage ratchet — compares per-area coverage against coverage-baseline.json.

Phase 1 of the automation testing strategy runs this REPORT-ONLY: it prints
drops and exits 0. Set RATCHET_ENFORCE=1 (planned for Phase 5, once blocs and
repositories reach their 80% floor) to make a drop fail the build.

Coverage is read from coverage/lcov.info and grouped by top-level directory
under lib/, so adding a file to an already-covered area needs no baseline edit.

Usage:
    flutter test --coverage
    python3 scripts/coverage_ratchet.py [--write]
"""

# macOS ships Python 3.9, where `str | None` is not valid at runtime.
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LCOV = ROOT / "coverage" / "lcov.info"
BASELINE = ROOT / "coverage-baseline.json"
ENFORCE = os.environ.get("RATCHET_ENFORCE") == "1"
WRITE = "--write" in sys.argv


def group_for(source: str) -> str | None:
    """lib/presentation/screens/home/x.dart -> 'lib/presentation'."""
    p = Path(source)
    parts = p.parts
    if "lib" not in parts:
        return None
    i = parts.index("lib")
    rest = parts[i + 1:]
    return f"lib/{rest[0]}" if len(rest) > 1 else "lib"


def read_lcov() -> dict[str, tuple[int, int]]:
    if not LCOV.exists():
        sys.exit(f"No coverage at {LCOV.relative_to(ROOT)}. Run: flutter test --coverage")
    acc: dict[str, list[int]] = {}
    current: str | None = None
    for line in LCOV.read_text().splitlines():
        if line.startswith("SF:"):
            current = group_for(line[3:].strip())
        elif line.startswith("LH:") and current:
            acc.setdefault(current, [0, 0])[0] += int(line[3:])
        elif line.startswith("LF:") and current:
            acc.setdefault(current, [0, 0])[1] += int(line[3:])
        elif line.startswith("end_of_record"):
            current = None
    return {k: (v[0], v[1]) for k, v in acc.items()}


def main() -> int:
    groups = read_lcov()
    current = {
        name: (round(hit / found * 100, 1) if found else 0.0)
        for name, (hit, found) in groups.items()
    }
    total_hit = sum(h for h, _ in groups.values())
    total_found = sum(f for _, f in groups.values())
    current["total"] = round(total_hit / total_found * 100, 1) if total_found else 0.0

    if WRITE or not BASELINE.exists():
        BASELINE.write_text(json.dumps(current, indent=2, sort_keys=True) + "\n")
        print(f"Wrote baseline to {BASELINE.relative_to(ROOT)}:")
        for k, v in sorted(current.items()):
            print(f"  {k:<24} {v}%")
        return 0

    baseline = json.loads(BASELINE.read_text())
    drops = []
    for name, pct in sorted(current.items()):
        base = baseline.get(name)
        if base is None:
            print(f"  {name:<24} {pct}%  (new — not yet in baseline)")
            continue
        # 0.1pp of slack absorbs rounding noise.
        if pct < base - 0.1:
            drops.append((name, base, pct))
            print(f"  {name:<24} {pct}%  <- down from {base}%")
        else:
            print(f"  {name:<24} {pct}%")

    if not drops:
        print("\nCoverage ratchet: no regressions.")
        return 0

    print(f"\nCoverage ratchet: {len(drops)} area(s) dropped.")
    if not ENFORCE:
        print("Report-only mode — not failing the build. Set RATCHET_ENFORCE=1 to enforce.")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())

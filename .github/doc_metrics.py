#!/usr/bin/env python3
"""Print useful summary metrics from a LibreLane metrics.json file."""

import json
import sys
from pathlib import Path


SUMMARY_TERMS = (
    "area",
    "cell",
    "count",
    "drc",
    "lvs",
    "power",
    "slack",
    "util",
    "wns",
    "__ws",
    "wirelength",
)


def flatten_metrics(value, prefix=""):
    if isinstance(value, dict):
        for key, nested_value in sorted(value.items()):
            path = f"{prefix}.{key}" if prefix else str(key)
            yield from flatten_metrics(nested_value, path)
    elif isinstance(value, list):
        for index, nested_value in enumerate(value):
            yield from flatten_metrics(nested_value, f"{prefix}[{index}]")
    else:
        yield prefix, value


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {Path(sys.argv[0]).name} <metrics.json>", file=sys.stderr)
        return 2

    metrics_path = Path(sys.argv[1])
    if not metrics_path.is_file():
        print(f"Metrics file not found: {metrics_path}", file=sys.stderr)
        return 2

    with metrics_path.open(encoding="utf-8") as metrics_file:
        metrics = json.load(metrics_file)

    if not isinstance(metrics, (dict, list)):
        print("Expected metrics.json to contain a JSON object or array.", file=sys.stderr)
        return 2

    entries = list(flatten_metrics(metrics))
    if not entries:
        print(f"No metric entries found in {metrics_path}")
        return 0

    selected = [
        (key, value)
        for key, value in entries
        if any(term in key.lower() for term in SUMMARY_TERMS)
    ]
    if not selected:
        selected = entries

    print(f"Metrics file: {metrics_path}")
    print(f"Showing {len(selected)} of {len(entries)} metric entries:")
    for key, value in selected:
        print(f"  {key}: {json.dumps(value, ensure_ascii=False)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

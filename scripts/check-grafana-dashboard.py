#!/usr/bin/env python3
"""Validate the embedded py-wallet Grafana dashboard contract."""

from __future__ import annotations

import json
import re
from pathlib import Path


DASHBOARD_PATH = Path("manifests/monitoring/py-wallet-dashboard.yaml")
MARKER = "  py-wallet.json: |\n"
REQUIRED_METRICS = {
    "py_wallet_registration_completed_total",
    "py_wallet_first_wallet_added_total",
    "py_wallet_first_snapshot_outcome_total",
    "py_wallet_manual_refresh_total",
    "py_wallet_failed_chain_retry_total",
    "py_wallet_telegram_digest_total",
    "snapshot_worker_jobs_total",
    "py_wallet_wallet_snapshot_freshness_seconds_bucket",
    "snapshot_worker_oldest_pending_job_age_seconds",
    "py_wallet_build_info",
    "snapshot_service_build_info",
}
FORBIDDEN_LABELS = {"user", "user_id", "wallet", "wallet_id", "address", "job_id", "chat_id"}


def load_dashboard() -> dict:
    source = DASHBOARD_PATH.read_text(encoding="utf-8")
    if source.count(MARKER) != 1:
        raise AssertionError(f"expected exactly one embedded dashboard in {DASHBOARD_PATH}")
    payload = source.split(MARKER, maxsplit=1)[1]
    lines = payload.splitlines()
    if not lines or any(line and not line.startswith("    ") for line in lines):
        raise AssertionError("embedded dashboard must remain a four-space-indented YAML block")
    return json.loads("\n".join(line[4:] for line in lines))


def main() -> None:
    dashboard = load_dashboard()
    assert dashboard["uid"] == "py-wallet"
    assert dashboard["schemaVersion"] == 39

    panels = dashboard.get("panels", [])
    panel_ids = [panel.get("id") for panel in panels]
    assert panel_ids and all(isinstance(panel_id, int) and panel_id > 0 for panel_id in panel_ids)
    assert len(panel_ids) == len(set(panel_ids)), "dashboard panel IDs must be unique"

    expressions = [
        target["expr"]
        for panel in panels
        for target in panel.get("targets", [])
        if "expr" in target
    ]
    joined_expressions = "\n".join(expressions)
    missing = sorted(metric for metric in REQUIRED_METRICS if metric not in joined_expressions)
    assert not missing, f"required product/release metrics are absent: {', '.join(missing)}"

    for expression in expressions:
        labels = {
            match.group(1)
            for matcher in re.findall(r"\{([^}]*)\}", expression)
            for match in re.finditer(
                r"([a-zA-Z_:][a-zA-Z0-9_:]*)\s*(?:=|!=|=~|!~)", matcher
            )
        }
        labels.update(
            label.strip()
            for grouping in re.findall(r"(?:by|without)\s*\(([^)]*)\)", expression)
            for label in grouping.split(",")
        )
        forbidden = sorted(labels & FORBIDDEN_LABELS)
        assert not forbidden, (
            f"privacy-unsafe label in PromQL ({', '.join(forbidden)}): {expression}"
        )

    print(f"validated {len(panels)} Grafana panels and {len(expressions)} PromQL targets")


if __name__ == "__main__":
    main()

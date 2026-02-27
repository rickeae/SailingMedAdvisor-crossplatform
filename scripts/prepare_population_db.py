#!/usr/bin/env python3
# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
"""
Prepare a fresh-install population database.

This script keeps baseline app configuration/prompts while removing user-specific
runtime data that must not ship in the default DB:
- Consultation log/history
- Medical chest inventory
- Vessel and crew records
- Last prompt verbatim capture
"""

from __future__ import annotations

import argparse
import shutil
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


CLEAR_TABLES = (
    "history_entries",
    "chats",
    "chat_metrics",
    "med_expiries",
    "items",
    "crew_vaccines",
    "crew",
    "vessel",
)


def _table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return bool(row)


def _count(conn: sqlite3.Connection, table_name: str) -> int:
    if not _table_exists(conn, table_name):
        return 0
    row = conn.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()
    return int(row[0] if row else 0)


def _backup(db_path: Path) -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    backup = db_path.with_suffix(db_path.suffix + f".bak_{stamp}")
    shutil.copy2(db_path, backup)
    return backup


def sanitize_database(db_path: Path) -> None:
    if not db_path.exists():
        print(f"[skip] DB file not found: {db_path}")
        return

    backup = _backup(db_path)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys = ON;")

        before = {table: _count(conn, table) for table in CLEAR_TABLES}
        before_prompt_len = 0
        if _table_exists(conn, "settings_meta"):
            row = conn.execute(
                "SELECT COALESCE(LENGTH(last_prompt_verbatim), 0) FROM settings_meta WHERE id=1"
            ).fetchone()
            before_prompt_len = int(row[0] if row else 0)

        with conn:
            for table in CLEAR_TABLES:
                if _table_exists(conn, table):
                    conn.execute(f"DELETE FROM {table}")

            if _table_exists(conn, "settings_meta"):
                conn.execute("UPDATE settings_meta SET last_prompt_verbatim='' WHERE id=1")

        after = {table: _count(conn, table) for table in CLEAR_TABLES}
        after_prompt_len = 0
        if _table_exists(conn, "settings_meta"):
            row = conn.execute(
                "SELECT COALESCE(LENGTH(last_prompt_verbatim), 0) FROM settings_meta WHERE id=1"
            ).fetchone()
            after_prompt_len = int(row[0] if row else 0)

        print(f"[ok] sanitized: {db_path}")
        print(f"     backup:   {backup}")
        for table in CLEAR_TABLES:
            print(f"     {table:16}: {before[table]} -> {after[table]}")
        print(f"     last_prompt_verbatim_length: {before_prompt_len} -> {after_prompt_len}")
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Prepare SailingMedAdvisor population DB(s).")
    parser.add_argument(
        "db_paths",
        nargs="*",
        help="DB file paths to sanitize (default: app.db and seed/app.db).",
    )
    args = parser.parse_args()

    targets = args.db_paths or ["app.db", "seed/app.db"]
    for raw_path in targets:
        sanitize_database(Path(raw_path).resolve())


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# =============================================================================
# Author: Rick Escher
# Project: SailingMedAdvisor
# Context: Google HAI-DEF Framework
# Models: Google MedGemmas
# Program: Kaggle Impact Challenge
# =============================================================================
"""
Set the install-time database profile for SailingMedAdvisor.

Profiles:
- empty: clears user/runtime records but keeps defaults and prompt configuration.
- sample: applies a small non-personal demo dataset after clearing runtime records.
"""

from __future__ import annotations

import argparse
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


SAMPLE_CREW = [
    {
        "id": "sample-crew-01",
        "firstName": "Alex",
        "lastName": "Mariner",
        "sex": "M",
        "position": "Captain",
        "history": "No known chronic conditions. No known drug allergies.",
    },
    {
        "id": "sample-crew-02",
        "firstName": "Jamie",
        "lastName": "Deck",
        "sex": "F",
        "position": "Crew",
        "history": "Mild asthma (exercise triggered).",
    },
    {
        "id": "sample-crew-03",
        "firstName": "Sam",
        "lastName": "Watch",
        "sex": "M",
        "position": "Crew",
        "history": "No known chronic conditions.",
    },
]


SAMPLE_VACCINES = [
    {
        "id": "sample-vax-01",
        "crew_id": "sample-crew-01",
        "vaccineType": "Influenza",
        "dateAdministered": "2025-10-15",
    },
    {
        "id": "sample-vax-02",
        "crew_id": "sample-crew-02",
        "vaccineType": "Tetanus / Diphtheria / Pertussis (Td/Tdap)",
        "dateAdministered": "2024-07-02",
    },
]


SAMPLE_ITEMS = [
    {
        "id": "sample-med-01",
        "itemType": "pharma",
        "name": "Amoxicillin",
        "genericName": "Amoxicillin",
        "brandName": "Amoxicillin",
        "formStrength": "500 mg capsule",
        "indications": "Bacterial infection coverage when indicated.",
        "adultDosage": "As directed by onboard protocol.",
        "storageLocation": "Pharmacy Kit A",
        "totalQty": "30",
        "status": "In stock",
        "category": "Antibiotic",
    },
    {
        "id": "sample-med-02",
        "itemType": "pharma",
        "name": "Ibuprofen",
        "genericName": "Ibuprofen",
        "brandName": "Ibuprofen",
        "formStrength": "200 mg tablet",
        "indications": "Pain and inflammation support.",
        "adultDosage": "As directed by onboard protocol.",
        "storageLocation": "Pharmacy Kit A",
        "totalQty": "60",
        "status": "In stock",
        "category": "Analgesic",
    },
    {
        "id": "sample-eq-01",
        "itemType": "equipment",
        "name": "Kelly Hemostat Forceps",
        "storageLocation": "Procedure Kit",
        "totalQty": "1",
        "status": "In stock",
        "category": "Minor Procedure",
    },
    {
        "id": "sample-eq-02",
        "itemType": "equipment",
        "name": "Syringe 60cc Luer Lock",
        "storageLocation": "Procedure Kit",
        "totalQty": "2",
        "status": "In stock",
        "category": "Irrigation",
    },
    {
        "id": "sample-cons-01",
        "itemType": "consumable",
        "name": "Sterile Gauze Pads 2x2",
        "storageLocation": "Consumables Bin",
        "totalQty": "40",
        "status": "In stock",
        "category": "Dressings",
    },
    {
        "id": "sample-cons-02",
        "itemType": "consumable",
        "name": "Micropore Paper Tape",
        "storageLocation": "Consumables Bin",
        "totalQty": "6",
        "status": "In stock",
        "category": "Dressings",
    },
]


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


def _clear_runtime_data(conn: sqlite3.Connection) -> None:
    for table in CLEAR_TABLES:
        if _table_exists(conn, table):
            conn.execute(f"DELETE FROM {table}")
    if _table_exists(conn, "context_store"):
        conn.execute("DELETE FROM context_store")
    if _table_exists(conn, "settings_meta"):
        conn.execute("UPDATE settings_meta SET last_prompt_verbatim='' WHERE id=1")


def _apply_sample_data(conn: sqlite3.Connection, now_iso: str) -> None:
    if _table_exists(conn, "vessel"):
        conn.execute(
            """
            INSERT INTO vessel (
                id, vesselName, registrationNumber, flagCountry, homePort, callSign, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (1, "SV Sample Vessel", "SAMPLE-001", "Canada", "Halifax", "CFD1234", now_iso),
        )

    if _table_exists(conn, "crew"):
        for crew in SAMPLE_CREW:
            conn.execute(
                """
                INSERT INTO crew (
                    id, firstName, lastName, sex, position, history, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    crew["id"],
                    crew["firstName"],
                    crew["lastName"],
                    crew["sex"],
                    crew["position"],
                    crew["history"],
                    now_iso,
                ),
            )

    if _table_exists(conn, "crew_vaccines"):
        for vaccine in SAMPLE_VACCINES:
            conn.execute(
                """
                INSERT INTO crew_vaccines (
                    id, crew_id, vaccineType, dateAdministered, updated_at
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    vaccine["id"],
                    vaccine["crew_id"],
                    vaccine["vaccineType"],
                    vaccine["dateAdministered"],
                    now_iso,
                ),
            )

    if _table_exists(conn, "items"):
        for item in SAMPLE_ITEMS:
            conn.execute(
                """
                INSERT INTO items (
                    id, itemType, name, genericName, brandName, formStrength, indications,
                    adultDosage, storageLocation, totalQty, status, category, updated_at,
                    verified, excludeFromResources
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    item["id"],
                    item["itemType"],
                    item["name"],
                    item.get("genericName"),
                    item.get("brandName"),
                    item.get("formStrength"),
                    item.get("indications"),
                    item.get("adultDosage"),
                    item["storageLocation"],
                    item["totalQty"],
                    item["status"],
                    item["category"],
                    now_iso,
                    1,
                    0,
                ),
            )


def set_profile(db_path: Path, profile: str) -> None:
    if not db_path.exists():
        raise FileNotFoundError(f"DB file not found: {db_path}")

    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys = ON;")
        before = {table: _count(conn, table) for table in CLEAR_TABLES}
        now_iso = datetime.now(timezone.utc).isoformat()
        with conn:
            _clear_runtime_data(conn)
            if profile == "sample":
                _apply_sample_data(conn, now_iso)
        after = {table: _count(conn, table) for table in CLEAR_TABLES}

        print(f"[ok] database profile applied: {profile}")
        print(f"     db: {db_path}")
        for table in CLEAR_TABLES:
            print(f"     {table:16}: {before[table]} -> {after[table]}")
        if profile == "sample":
            print("     note: sample data is demo content and can be deleted in-app.")
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Set SailingMedAdvisor install DB profile.")
    parser.add_argument("--db", default="app.db", help="Path to SQLite database (default: app.db).")
    parser.add_argument(
        "--profile",
        default="empty",
        choices=("empty", "sample"),
        help="Install database profile: empty or sample.",
    )
    args = parser.parse_args()
    set_profile(Path(args.db).resolve(), args.profile)


if __name__ == "__main__":
    main()

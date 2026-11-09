#!/usr/bin/env python3
"""Build NoveLib's redistributable Japanese VN catalog from a VNDB dump."""

from __future__ import annotations

import argparse
import csv
import re
import shutil
import sqlite3
import unicodedata
from collections import defaultdict
from pathlib import Path


def read_tsv(path: Path):
    with path.open("r", encoding="utf-8", newline="") as handle:
        yield from csv.reader(handle, delimiter="\t", quoting=csv.QUOTE_NONE)


def value(text: str) -> str | None:
    return None if text == r"\N" else text.replace(r"\n", "\n").replace("\\\\", "\\")


def normalize_title(text: str) -> str:
    normalized = unicodedata.normalize("NFKC", text).casefold()
    normalized = re.sub(r"(dl版|ダウンロード版)$", "", normalized)
    return "".join(char for char in normalized if char.isalnum())


def image_url(image_id: str | None) -> str | None:
    if not image_id or not image_id.startswith("cv"):
        return None
    number = image_id[2:]
    if not number.isdigit():
        return None
    return f"https://t.vndb.org/cv/{number[-2:]}/{number}.jpg"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("extract_dir", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    db_dir = args.extract_dir / "db"
    timestamp = (args.extract_dir / "TIMESTAMP").read_text(encoding="utf-8").strip()

    vns: dict[str, dict[str, object]] = {}
    for row in read_tsv(db_dir / "vn"):
        vn_id, image_id, selected_image_id, original_language, vote_count, rating, _, _, _, _, dev_status, aliases, _ = row
        if original_language != "ja" or dev_status == "2":
            continue
        vns[vn_id] = {
            "image_url": image_url(value(selected_image_id) or value(image_id)),
            "vote_count": int(vote_count),
            "rating": int(rating) / 100 if rating != r"\N" else None,
            "aliases": set(filter(None, (value(aliases) or "").splitlines())),
        }

    for row in read_tsv(db_dir / "vn_titles"):
        vn_id, language, official, title, latin = row
        if vn_id not in vns:
            continue
        title_value = value(title)
        latin_value = value(latin)
        if title_value:
            vns[vn_id]["aliases"].add(title_value)
        if latin_value:
            vns[vn_id]["aliases"].add(latin_value)
        if language == "ja" and official == "t":
            vns[vn_id]["title_ja"] = title_value
            vns[vn_id]["title_romaji"] = latin_value

    release_info: dict[str, tuple[str | None, bool, int | None, bool]] = {}
    for row in read_tsv(db_dir / "releases"):
        release_id = row[0]
        original_language = row[2]
        released = value(row[3])
        min_age = int(row[7]) if row[7] not in (r"\N", "") else None
        has_ero = row[17] == "t"
        official = row[21] == "t"
        if original_language == "ja":
            release_info[release_id] = (released, official, min_age, has_ero)

    release_to_vns: dict[str, list[str]] = defaultdict(list)
    for release_id, vn_id, _ in read_tsv(db_dir / "releases_vn"):
        if vn_id in vns and release_id in release_info:
            release_to_vns[release_id].append(vn_id)

    producer_names: dict[str, str] = {}
    for producer_id, _, _, name, latin, _, _ in read_tsv(db_dir / "producers"):
        producer_names[producer_id] = value(name) or value(latin) or producer_id

    release_developers: dict[str, set[str]] = defaultdict(set)
    for release_id, producer_id, developer, _ in read_tsv(db_dir / "releases_producers"):
        if developer == "t" and producer_id in producer_names:
            release_developers[release_id].add(producer_names[producer_id])

    dates: dict[str, list[str]] = defaultdict(list)
    developers: dict[str, set[str]] = defaultdict(set)
    minimum_ages: dict[str, list[int]] = defaultdict(list)
    adult_works: dict[str, bool] = defaultdict(bool)
    for release_id, vn_ids in release_to_vns.items():
        released, official, min_age, has_ero = release_info[release_id]
        if not official:
            continue
        for vn_id in vn_ids:
            if released and re.match(r"^\d{4}", released):
                dates[vn_id].append(released)
            developers[vn_id].update(release_developers.get(release_id, ()))
            if min_age is not None:
                minimum_ages[vn_id].append(min_age)
            if has_ero or (min_age is not None and min_age >= 18):
                adult_works[vn_id] = True

    args.output.parent.mkdir(parents=True, exist_ok=True)
    if args.output.exists():
        args.output.unlink()
    database = sqlite3.connect(args.output)
    database.executescript(
        """
        PRAGMA journal_mode = OFF;
        PRAGMA synchronous = OFF;
        CREATE TABLE metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
        CREATE TABLE works (
          vndb_id TEXT PRIMARY KEY,
          title_ja TEXT NOT NULL,
          title_romaji TEXT,
          normalized_title TEXT NOT NULL,
          image_url TEXT,
          released TEXT,
          developers TEXT,
          rating REAL,
          vote_count INTEGER NOT NULL,
          min_age INTEGER,
          is_adult INTEGER NOT NULL DEFAULT 0 CHECK (is_adult IN (0, 1))
        );
        CREATE TABLE aliases (
          work_id TEXT NOT NULL REFERENCES works(vndb_id) ON DELETE CASCADE,
          alias TEXT NOT NULL,
          normalized_alias TEXT NOT NULL,
          PRIMARY KEY (work_id, normalized_alias)
        );
        CREATE TABLE store_products (
          work_id TEXT NOT NULL REFERENCES works(vndb_id) ON DELETE CASCADE,
          store TEXT NOT NULL CHECK (store IN ('dlsite', 'fanza')),
          product_id TEXT NOT NULL,
          landing_url TEXT,
          is_primary INTEGER NOT NULL DEFAULT 0 CHECK (is_primary IN (0, 1)),
          source TEXT,
          verified_at TEXT,
          PRIMARY KEY (store, product_id)
        );
        CREATE INDEX store_products_work_idx
          ON store_products(work_id, store, is_primary DESC);
        CREATE INDEX works_normalized_title_idx ON works(normalized_title);
        CREATE INDEX aliases_normalized_alias_idx ON aliases(normalized_alias);
        CREATE INDEX works_rating_idx ON works(rating DESC, vote_count DESC);
        """
    )
    database.executemany(
        "INSERT INTO metadata(key, value) VALUES(?, ?)",
        [
            ("source", "VNDB"),
            ("source_url", "https://vndb.org/"),
            ("source_timestamp", timestamp),
            ("database_license", "ODbL-1.0"),
            ("contents_license", "DbCL-1.0"),
            ("filter", "original_language=ja; development_status!=cancelled"),
        ],
    )

    work_rows = []
    alias_rows = []
    for vn_id, record in vns.items():
        title = record.get("title_ja")
        if not title:
            continue
        title_romaji = record.get("title_romaji")
        work_rows.append(
            (
                vn_id,
                title,
                title_romaji,
                normalize_title(title),
                record["image_url"],
                min(dates[vn_id]) if dates[vn_id] else None,
                " / ".join(sorted(developers[vn_id])) or None,
                record["rating"],
                record["vote_count"],
                max(minimum_ages[vn_id]) if minimum_ages[vn_id] else None,
                1 if adult_works[vn_id] else 0,
            )
        )
        aliases = set(record["aliases"])
        aliases.add(title)
        if title_romaji:
            aliases.add(title_romaji)
        seen_normalized = set()
        for alias in sorted(aliases):
            normalized = normalize_title(alias)
            if not normalized or normalized in seen_normalized:
                continue
            seen_normalized.add(normalized)
            alias_rows.append((vn_id, alias, normalized))

    database.executemany(
        """
        INSERT INTO works(
          vndb_id, title_ja, title_romaji, normalized_title,
          image_url, released, developers, rating, vote_count, min_age, is_adult
        ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        work_rows,
    )
    database.executemany(
        "INSERT INTO aliases(work_id, alias, normalized_alias) VALUES(?, ?, ?)",
        alias_rows,
    )
    database.commit()
    database.execute("ANALYZE")
    database.execute("VACUUM")
    database.close()

    license_dir = args.output.parent
    for filename in ("LICENSE-ODBL.txt", "LICENSE-DBCL.txt"):
        shutil.copy2(args.extract_dir / filename, license_dir / filename)
    print(f"works={len(work_rows)} aliases={len(alias_rows)} output={args.output}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json
import re
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo


LOCAL_TZ = ZoneInfo("Asia/Shanghai")
FRACTION_RE = re.compile(r"\.(\d+)")


def normalize_base_url(value: str) -> str:
    value = value.strip()
    if value.startswith(("http://", "https://")):
        return value
    return f"https://{value}"


def prepare_iso(value: str) -> str:
    value = value.strip()
    if value.endswith("Z"):
        value = f"{value[:-1]}+00:00"

    match = FRACTION_RE.search(value)
    if not match:
        return value

    digits = match.group(1)
    if len(digits) <= 6:
        return value

    start, end = match.span(1)
    return f"{value[:start]}{digits[:6]}{value[end:]}"


def parse_like_app(value: str | None) -> datetime | None:
    if value is None:
        return None

    parsed = datetime.fromisoformat(prepare_iso(value))
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=LOCAL_TZ)
    return parsed.astimezone(LOCAL_TZ)


def to_rfc3339_utc(value: datetime | None) -> str | None:
    if value is None:
        return None

    utc_value = value.astimezone(timezone.utc)
    base = utc_value.strftime("%Y-%m-%dT%H:%M:%S")
    if utc_value.microsecond:
        fraction = f"{utc_value.microsecond:06d}".rstrip("0")
        return f"{base}.{fraction}Z"
    return f"{base}Z"


def fetch_notes(base_url: str, secret: str) -> list[dict]:
    request = urllib.request.Request(
        url=f"{base_url}/api/Notes",
        headers={
            "Accept": "application/json",
            "Accept-Encoding": "identity",
            "x-secret": secret,
        },
    )
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def normalize_note(note: dict) -> dict:
    return {
        "id": note.get("id"),
        "isTopMost": note.get("isTopMost", False),
        "content": note.get("content"),
        "createTime": to_rfc3339_utc(parse_like_app(note.get("createTime"))),
        "lastUpdateTime": to_rfc3339_utc(
            parse_like_app(note.get("lastUpdateTime"))
        ),
        "archiveTime": to_rfc3339_utc(parse_like_app(note.get("archiveTime"))),
        "isArchived": note.get("isArchived", False),
        "color": note.get("color"),
        "index": note.get("index", 0),
    }


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: python3 tool/export_notes_from_url.py <base-url> [output.json] [secret]",
            file=sys.stderr,
        )
        return 64

    base_url = normalize_base_url(sys.argv[1])
    output_path = Path(sys.argv[2] if len(sys.argv) >= 3 else "notes.utc.json")
    secret = sys.argv[3] if len(sys.argv) >= 4 else ""

    notes = fetch_notes(base_url, secret)
    normalized = [normalize_note(note) for note in notes]
    output_path.write_text(
        json.dumps(normalized, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Exported {len(normalized)} notes to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Generate Prolog knowledge-base facts from data/INSAT_Class_Schedules.csv."""

from __future__ import annotations

import csv
import re
import unicodedata
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = PROJECT_ROOT / "data" / "INSAT_Class_Schedules.csv"
GROUPS_PATH = PROJECT_ROOT / "src" / "groups.pl"
OUT_GROUPS = PROJECT_ROOT / "src" / "csv_groups_generated.pl"
OUT_COURSES = PROJECT_ROOT / "src" / "csv_courses_generated.pl"
OUT_INSTRUCTORS = PROJECT_ROOT / "src" / "csv_instructors_generated.pl"
SLOT_HOURS = 1.5


def atom(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def slug(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value or "")
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii")
    ascii_value = ascii_value.lower()
    ascii_value = re.sub(r"[^a-z0-9]+", "_", ascii_value)
    ascii_value = re.sub(r"_+", "_", ascii_value).strip("_")
    return ascii_value or "subject"


def repair_text(value: str) -> str:
    if not isinstance(value, str):
        return value
    if "Ã" not in value and "Â" not in value:
        return value
    try:
        return value.encode("latin1").decode("utf-8")
    except UnicodeError:
        return value


def parse_float(value: str) -> float:
    try:
        return float(str(value).replace(",", "."))
    except (TypeError, ValueError):
        return 0.0


def class_parts(label: str) -> tuple[str, int, int]:
    match = re.match(r"^([A-Za-z]+)(\d+)\/(\d+)$", label.strip())
    if not match:
        raise ValueError(f"Unsupported class label: {label}")
    dept, year, section = match.groups()
    return dept.lower(), int(year), int(section)


def group_id_for(label: str) -> str:
    dept, year, section = class_parts(label)
    if dept == "mpi":
        return f"mpi_{((year - 1) * 4) + section}"

    suffixes = "abcdefghijklmnopqrstuvwxyz"
    suffix = suffixes[section - 1] if section <= len(suffixes) else str(section)
    return f"{dept}{year}_{suffix}"


def group_year_for(label: str):
    dept, year, _section = class_parts(label)
    if dept == "mpi":
        return "prep1" if year <= 3 else "prep2"
    return year


def existing_group_ids() -> set[str]:
    text = GROUPS_PATH.read_text(encoding="utf-8", errors="replace")
    return set(re.findall(r"group\(\s*([^,\s]+)\s*,", text))


def sessions_for(hours: float) -> int:
    if hours <= 0:
        return 0
    return max(1, round(hours / SLOT_HOURS))


def equipment_for(dept: str, session_type: str) -> str:
    if session_type == "lecture":
        return "projector_board"
    if session_type == "td":
        return "projector_board"
    if dept == "ch":
        return "chemistry_lab"
    if dept == "bio":
        return "biology_lab"
    if dept == "mpi":
        return "physics_lab"
    if dept in {"gl", "imi", "iia", "rt"}:
        return "cs_lab"
    return "projector_board"


def course_suffix(session_type: str) -> str:
    return {"lecture": "lec", "td": "td", "tp": "tp"}[session_type]


def course_title(subject: str, session_type: str) -> str:
    label = {"lecture": "Cours", "td": "TD", "tp": "TP"}[session_type]
    return f"{subject} - {label}"


def course_year_for(dept: str, year: int):
    return "prep" if dept == "mpi" else year


def make_course_id(label: str, subject: str, session_type: str) -> str:
    dept, year, _section = class_parts(label)
    return f"{dept}{year}_{slug(subject)}_{course_suffix(session_type)}"


def read_rows() -> list[dict[str, str]]:
    with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
        return [
            {key: repair_text(value) for key, value in row.items()}
            for row in csv.DictReader(handle)
        ]


def write_groups(rows: list[dict[str, str]]) -> None:
    known = existing_group_ids()
    class_labels = sorted({row["Class"].strip() for row in rows if row.get("Class")})

    lines = [
        "% ============================================================",
        "%  AUTO-GENERATED from data/INSAT_Class_Schedules.csv",
        "%  Regenerate with: python tools/generate_csv_kb.py",
        "% ============================================================",
        "",
    ]

    generated = []
    for label in class_labels:
        gid = group_id_for(label)
        if gid in known:
            continue
        dept, _year, _section = class_parts(label)
        generated.append((gid, dept, group_year_for(label)))

    for gid, dept, year in generated:
        lines.append(f"group({gid}, {dept}, {year}, 30).")

    lines.append("")
    OUT_GROUPS.write_text("\n".join(lines), encoding="utf-8")


def write_courses(rows: list[dict[str, str]]) -> None:
    seen_courses = set()
    course_lines = []
    session_lines = []

    for row in rows:
        class_label = row["Class"].strip()
        subject = row["Subject"].strip()
        dept, year, _section = class_parts(class_label)
        gid = group_id_for(class_label)
        prolog_year = course_year_for(dept, year)

        hour_fields = [
            ("lecture", parse_float(row.get("Course_Hours", "0"))),
            ("td", parse_float(row.get("TD_Hours", "0"))),
            ("tp", parse_float(row.get("TP_Hours", "0"))),
        ]

        for session_type, hours in hour_fields:
            session_count = sessions_for(hours)
            if not session_count:
                continue

            cid = make_course_id(class_label, subject, session_type)
            if cid not in seen_courses:
                seen_courses.add(cid)
                title = atom(course_title(subject, session_type))
                equipment = equipment_for(dept, session_type)
                instructor = f"csv_prof_{dept}"
                course_lines.append(
                    f"course({cid}, '{title}', {dept}, {prolog_year}, "
                    f"{session_count}, {session_type}, {equipment}, {instructor})."
                )
            session_lines.append(f"course_session({cid}, {gid}).")

    lines = [
        "% ============================================================",
        "%  AUTO-GENERATED from data/INSAT_Class_Schedules.csv",
        "%  Regenerate with: python tools/generate_csv_kb.py",
        "% ============================================================",
        "",
        "% --- CSV course facts ---",
        *course_lines,
        "",
        "% --- CSV course_session facts ---",
        *sorted(set(session_lines)),
        "",
    ]
    OUT_COURSES.write_text("\n".join(lines), encoding="utf-8")


def write_instructors(rows: list[dict[str, str]]) -> None:
    depts = sorted({class_parts(row["Class"].strip())[0] for row in rows if row.get("Class")})
    lines = [
        "% ============================================================",
        "%  AUTO-GENERATED from data/INSAT_Class_Schedules.csv",
        "%  Regenerate with: python tools/generate_csv_kb.py",
        "% ============================================================",
        "",
    ]
    for dept in depts:
        lines.append(f"instructor(csv_prof_{dept}, {dept}, csv_catalog_subjects).")
    lines.append("")
    OUT_INSTRUCTORS.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    rows = read_rows()
    write_groups(rows)
    write_courses(rows)
    write_instructors(rows)
    print(f"Generated {OUT_GROUPS.relative_to(PROJECT_ROOT)}")
    print(f"Generated {OUT_COURSES.relative_to(PROJECT_ROOT)}")
    print(f"Generated {OUT_INSTRUCTORS.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()

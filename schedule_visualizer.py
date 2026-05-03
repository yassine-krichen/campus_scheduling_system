#!/usr/bin/env python3
from __future__ import annotations
"""
FastAPI schedule visualizer for the INSAT Campus Scheduling System.

Run:
    python schedule_visualizer.py

Then open:
    http://127.0.0.1:8000
"""

import os
import re
import csv
import subprocess
import sys
import time
import unicodedata
from dataclasses import asdict, dataclass
from difflib import SequenceMatcher
from pathlib import Path
from typing import Dict, List, Optional


try:
    from fastapi import FastAPI, HTTPException, Query
    from fastapi.responses import HTMLResponse
except ModuleNotFoundError:
    FastAPI = None
    HTTPException = None
    Query = None
    HTMLResponse = None


DEFAULT_PROLOG_TIMEOUT = 120
DAYS_ORDER = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
SCENARIOS = ["demo", "gl3_only", "engineering", "full_campus"]
PROJECT_ROOT = Path(__file__).parent
DEFAULT_CSV_PATHS = [
    PROJECT_ROOT / "data" / "INSAT_Class_Schedules.csv",
    Path(r"d:\users\seif\Downloads\INSAT_Class_Schedules.csv"),
]


def get_prolog_timeout() -> int:
    raw_timeout = os.environ.get("SCHED_TIMEOUT", str(DEFAULT_PROLOG_TIMEOUT))
    try:
        timeout = int(raw_timeout)
    except ValueError:
        timeout = DEFAULT_PROLOG_TIMEOUT
    return max(1, timeout)


@dataclass
class Assignment:
    """Represents a schedule assignment."""

    course_id: str
    group_id: str
    room_id: str
    day: str
    slot: int
    course_name: str = ""
    subject_name: str = ""
    class_label: str = ""
    session_type: str = ""
    session_hours: float = 1.5
    total_hours: float = 0.0
    course_hours: float = 0.0
    td_hours: float = 0.0
    tp_hours: float = 0.0
    metadata_source: str = "course_id"


@dataclass
class SubjectInfo:
    class_label: str
    group_id: str
    subject: str
    total_hours: float
    course_hours: float
    td_hours: float
    tp_hours: float


@dataclass
class CourseInfo:
    course_id: str
    name: str
    session_type: str
    sessions_per_week: int


def clean_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value or "")
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii")
    ascii_value = ascii_value.lower()
    ascii_value = re.sub(r"\b(cours|td|tp|lec|lecture)\b", " ", ascii_value)
    ascii_value = re.sub(r"[^a-z0-9]+", " ", ascii_value)
    return re.sub(r"\s+", " ", ascii_value).strip()


def parse_float(value: str) -> float:
    try:
        return float(str(value).replace(",", "."))
    except (TypeError, ValueError):
        return 0.0


def class_label_to_group_id(label: str) -> str:
    match = re.match(r"^([A-Za-z]+)(\d+)\/(\d+)$", (label or "").strip())
    if not match:
        return clean_text(label).replace(" ", "_")

    dept, year, section = match.groups()
    dept = dept.lower()
    year_num = int(year)
    section_num = int(section)

    if dept == "mpi":
        return "mpi_{}".format(((year_num - 1) * 4) + section_num)

    suffixes = "abcdefghijklmnopqrstuvwxyz"
    suffix = suffixes[section_num - 1] if section_num <= len(suffixes) else str(section_num)
    return "{}{}_{}".format(dept, year_num, suffix)


def infer_session_type(course_id: str, fallback: str = "") -> str:
    if course_id.endswith("_td"):
        return "td"
    if course_id.endswith("_tp"):
        return "tp"
    if course_id.endswith("_lec"):
        return "lecture"
    return fallback or "lecture"


def resolve_csv_path() -> Optional[Path]:
    env_path = os.environ.get("SCHED_CSV_PATH")
    candidates = [Path(env_path)] if env_path else []
    candidates.extend(DEFAULT_CSV_PATHS)
    for path in candidates:
        if path and path.exists():
            return path
    return None


def load_subject_catalog() -> List[SubjectInfo]:
    csv_path = resolve_csv_path()
    if not csv_path:
        return []

    subjects: List[SubjectInfo] = []
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            class_label = (row.get("Class") or "").strip()
            subject = (row.get("Subject") or "").strip()
            if not class_label or not subject:
                continue
            subjects.append(
                SubjectInfo(
                    class_label=class_label,
                    group_id=class_label_to_group_id(class_label),
                    subject=subject,
                    total_hours=parse_float(row.get("Total_Hours", "0")),
                    course_hours=parse_float(row.get("Course_Hours", "0")),
                    td_hours=parse_float(row.get("TD_Hours", "0")),
                    tp_hours=parse_float(row.get("TP_Hours", "0")),
                )
            )
    return subjects


def load_course_catalog() -> Dict[str, CourseInfo]:
    courses_path = PROJECT_ROOT / "src" / "courses.pl"
    if not courses_path.exists():
        return {}

    text = courses_path.read_text(encoding="utf-8", errors="replace")
    pattern = re.compile(
        r"course\(\s*([^,\s]+)\s*,\s*'([^']+)'\s*,\s*[^,]+,\s*[^,]+,\s*(\d+)\s*,\s*([^,\s]+)",
        re.MULTILINE,
    )
    catalog: Dict[str, CourseInfo] = {}
    for course_id, name, sessions_per_week, session_type in pattern.findall(text):
        catalog[course_id] = CourseInfo(
            course_id=course_id,
            name=name,
            session_type=session_type,
            sessions_per_week=int(sessions_per_week),
        )
    return catalog


def score_subject_match(course_name: str, subject: str) -> float:
    left = clean_text(course_name)
    right = clean_text(subject)
    if not left or not right:
        return 0.0
    if left == right:
        return 1.0
    if left in right or right in left:
        return 0.88
    left_tokens = set(left.split())
    right_tokens = set(right.split())
    overlap = len(left_tokens & right_tokens) / max(1, len(left_tokens | right_tokens))
    return max(overlap, SequenceMatcher(None, left, right).ratio())


def subject_hours_for_type(subject: SubjectInfo, session_type: str) -> float:
    if session_type == "td":
        return subject.td_hours
    if session_type == "tp":
        return subject.tp_hours
    return subject.course_hours


class ScheduleParser:
    """Parse Prolog assignment output into Assignment objects."""

    @staticmethod
    def parse_assignments(prolog_output: str) -> List[Assignment]:
        assignments: List[Assignment] = []

        for line in prolog_output.strip().splitlines():
            line = line.strip()
            if not line or "|" not in line:
                continue

            parts = [part.strip() for part in line.split("|")]
            if len(parts) < 4:
                continue

            slot_match = re.search(r"(\w+)\s+slot\s+(\d+)", parts[3])
            if slot_match:
                assignments.append(
                    Assignment(
                        course_id=parts[0],
                        group_id=parts[1],
                        room_id=parts[2],
                        day=slot_match.group(1),
                        slot=int(slot_match.group(2)),
                    )
                )

        if assignments:
            return assignments

        pattern = r"assign\(([^,]+),\s*([^,]+),\s*([^,]+),\s*slot\(([^,]+),\s*(\d+)\)\)"
        for course, group, room, day, slot in re.findall(pattern, prolog_output):
            assignments.append(
                Assignment(
                    course_id=course.strip(),
                    group_id=group.strip(),
                    room_id=room.strip(),
                    day=day.strip(),
                    slot=int(slot),
                )
            )

        return assignments


class PrologInterface:
    """Interface with the Prolog scheduler."""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.main_pl = project_root / "main.pl"

    def generate_schedule(
        self,
        scenario: Optional[str] = None,
        limit: Optional[int] = None,
        timeout: Optional[int] = None,
    ) -> List[Assignment]:
        env = os.environ.copy()
        if scenario:
            env["SCHED_SCENARIO"] = scenario
        if limit is not None:
            env["SCHED_LIMIT"] = str(limit)

        effective_timeout = timeout or get_prolog_timeout()
        cmd = [
            "swipl",
            "-q",
            "-s",
            str(self.main_pl),
            "-g",
            "generate_schedule(S), write(S), halt.",
        ]

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=effective_timeout,
                cwd=str(self.project_root),
                env=env,
            )
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(
                "Prolog timed out after {} seconds. Increase SCHED_TIMEOUT for larger scenarios.".format(
                    effective_timeout
                )
            ) from exc

        if result.returncode != 0:
            detail = (result.stderr or result.stdout or "Unknown Prolog error").strip()
            raise RuntimeError(detail[:1000])

        assignments = ScheduleParser.parse_assignments(result.stdout)
        if not assignments:
            raise RuntimeError("Prolog returned no parseable assignments.")

        return assignments


class ScheduleVisualizer:
    """Build grouped and summary data for API consumers."""

    def __init__(self, assignments: List[Assignment]):
        self.subject_catalog = load_subject_catalog()
        self.course_catalog = load_course_catalog()
        self.subjects_by_group: Dict[str, List[SubjectInfo]] = {}
        for subject in self.subject_catalog:
            self.subjects_by_group.setdefault(subject.group_id, []).append(subject)

        assignments = [self.enrich_assignment(item) for item in assignments]
        self.assignments = sorted(
            assignments,
            key=lambda item: (
                DAYS_ORDER.index(item.day) if item.day in DAYS_ORDER else 999,
                item.slot,
                item.group_id,
                item.course_id,
                item.room_id,
            ),
        )

    def enrich_assignment(self, item: Assignment) -> Assignment:
        course_info = self.course_catalog.get(item.course_id)
        course_name = course_info.name if course_info else item.course_id
        session_type = infer_session_type(
            item.course_id,
            course_info.session_type if course_info else "",
        )

        candidates = [
            subject
            for subject in self.subjects_by_group.get(item.group_id, [])
            if subject_hours_for_type(subject, session_type) > 0
        ]
        if not candidates:
            candidates = self.subjects_by_group.get(item.group_id, [])

        best_subject = None
        best_score = 0.0
        for subject in candidates:
            score = score_subject_match(course_name, subject.subject)
            if score > best_score:
                best_score = score
                best_subject = subject

        if best_subject and best_score >= 0.42:
            item.subject_name = best_subject.subject
            item.class_label = best_subject.class_label
            item.total_hours = best_subject.total_hours
            item.course_hours = best_subject.course_hours
            item.td_hours = best_subject.td_hours
            item.tp_hours = best_subject.tp_hours
            item.session_hours = subject_hours_for_type(best_subject, session_type) or 1.5
            item.metadata_source = "csv"
        else:
            item.subject_name = re.sub(r"\s+-\s+(Cours|TD|TP)$", "", course_name)
            item.class_label = item.group_id
            item.metadata_source = "prolog"

        item.course_name = course_name
        item.session_type = session_type
        return item

    def summary(self) -> Dict[str, int]:
        by_day = self.by_day()
        return {
            "total_assignments": len(self.assignments),
            "rooms": len({item.room_id for item in self.assignments}),
            "groups": len({item.group_id for item in self.assignments}),
            "courses": len({item.course_id for item in self.assignments}),
            "days": sum(1 for day in by_day.values() if day),
            "max_slot": max((item.slot for item in self.assignments), default=0),
            "csv_matches": sum(1 for item in self.assignments if item.metadata_source == "csv"),
        }

    def by_day(self) -> Dict[str, List[Dict]]:
        grouped: Dict[str, List[Assignment]] = {day: [] for day in DAYS_ORDER}
        for item in self.assignments:
            grouped.setdefault(item.day, []).append(item)
        return {day: [asdict(item) for item in items] for day, items in grouped.items()}

    def by_slot(self) -> Dict[str, Dict[str, List[Dict]]]:
        grouped: Dict[str, Dict[str, List[Dict]]] = {
            day: {} for day in DAYS_ORDER
        }
        for item in self.assignments:
            grouped.setdefault(item.day, {}).setdefault(str(item.slot), []).append(asdict(item))
        return grouped

    def payload(self, scenario: str, elapsed_ms: int) -> Dict:
        rooms = sorted({item.room_id for item in self.assignments})
        groups = sorted({item.group_id for item in self.assignments})
        courses = sorted({item.subject_name or item.course_id for item in self.assignments})
        class_catalog: Dict[str, List[Dict]] = {}
        for subject in self.subject_catalog:
            class_catalog.setdefault(subject.class_label, []).append(asdict(subject))
        return {
            "scenario": scenario,
            "elapsed_ms": elapsed_ms,
            "csv_loaded": bool(self.subject_catalog),
            "csv_path": str(resolve_csv_path() or ""),
            "days": DAYS_ORDER,
            "slots": list(range(1, self.summary()["max_slot"] + 1)),
            "rooms": rooms,
            "groups": groups,
            "courses": courses,
            "class_catalog": class_catalog,
            "summary": self.summary(),
            "assignments": [asdict(item) for item in self.assignments],
            "by_day": self.by_day(),
            "by_slot": self.by_slot(),
        }


def require_fastapi() -> None:
    if FastAPI is None:
        print("ERROR: FastAPI is not installed.")
        print("Install it with: python -m pip install fastapi uvicorn")
        sys.exit(1)


require_fastapi()
app = FastAPI(title="Campus Schedule Visualizer")

_CACHE: Dict[str, Dict] = {}


def cache_key(scenario: str, limit: int, timeout: int) -> str:
    return "{}:{}:{}".format(scenario, limit, timeout)


@app.get("/", response_class=HTMLResponse)
def index():
    return HTML_PAGE


@app.get("/api/schedule")
def api_schedule(
    scenario: Optional[str] = Query(default=None),
    limit: int = Query(default=1, ge=1, le=20),
    timeout: Optional[int] = Query(default=None, ge=1, le=600),
    refresh: bool = Query(default=False),
):
    scenario = scenario or os.environ.get("SCHED_SCENARIO", "demo")
    timeout = timeout or get_prolog_timeout()
    if scenario not in SCENARIOS:
        raise HTTPException(status_code=400, detail="Unknown scenario: {}".format(scenario))

    key = cache_key(scenario, limit, timeout)
    if not refresh and key in _CACHE:
        return _CACHE[key]

    started = time.perf_counter()
    try:
        assignments = PrologInterface(PROJECT_ROOT).generate_schedule(
            scenario=scenario,
            limit=limit,
            timeout=timeout,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    payload = ScheduleVisualizer(assignments).payload(scenario=scenario, elapsed_ms=elapsed_ms)
    _CACHE[key] = payload
    return payload


@app.get("/api/health")
def api_health():
    return {"ok": True, "project_root": str(PROJECT_ROOT)}


HTML_PAGE = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Campus Schedule Visualizer</title>
  <style>
    :root {
      color-scheme: dark;
      --ink: #eef7f8;
      --muted: #8fa5ad;
      --soft: #c8d9dd;
      --line: rgba(151, 188, 196, .18);
      --line-strong: rgba(93, 232, 217, .42);
      --panel: rgba(12, 22, 29, .86);
      --panel-strong: rgba(17, 31, 40, .96);
      --page: #071015;
      --nav: #0a141b;
      --accent: #36d7c4;
      --accent-dark: #18a99a;
      --blue: #5aa9ff;
      --green: #5fe08f;
      --amber: #f4c35d;
      --magenta: #d874ff;
      --red: #ff6f61;
      --shadow: 0 18px 50px rgba(0, 0, 0, .36);
      --glow: 0 0 0 1px rgba(54, 215, 196, .18), 0 0 34px rgba(54, 215, 196, .09);
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      color: var(--ink);
      background:
        linear-gradient(90deg, rgba(255,255,255,.035) 1px, transparent 1px),
        linear-gradient(180deg, rgba(255,255,255,.035) 1px, transparent 1px),
        radial-gradient(circle at 80% 8%, rgba(54, 215, 196, .14), transparent 26%),
        radial-gradient(circle at 18% 82%, rgba(90, 169, 255, .12), transparent 28%),
        var(--page);
      background-size: 34px 34px, 34px 34px, auto, auto, auto;
    }

    .app {
      min-height: 100vh;
      display: grid;
      grid-template-columns: 280px minmax(0, 1fr);
    }

    .sidebar {
      background:
        linear-gradient(180deg, rgba(54, 215, 196, .10), transparent 28%),
        var(--nav);
      border-right: 1px solid var(--line);
      color: var(--ink);
      padding: 26px 18px;
      display: flex;
      flex-direction: column;
      gap: 24px;
    }

    .brand {
      display: flex;
      flex-direction: column;
      gap: 4px;
      padding: 4px 8px 20px;
      border-bottom: 1px solid var(--line);
      position: relative;
    }

    .brand::before {
      content: "";
      width: 42px;
      height: 4px;
      border-radius: 999px;
      background: linear-gradient(90deg, var(--accent), var(--blue));
      box-shadow: 0 0 22px rgba(54, 215, 196, .55);
      margin-bottom: 12px;
    }

    .brand strong {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: 0;
    }

    .brand span {
      color: var(--muted);
      font-size: 13px;
    }

    .nav {
      display: grid;
      gap: 8px;
    }

    .nav button,
    .icon-button,
    .primary-button,
    select,
    input {
      font: inherit;
    }

    .nav button {
      width: 100%;
      border: 0;
      border-radius: 8px;
      min-height: 46px;
      padding: 0 14px;
      text-align: left;
      color: var(--soft);
      background: rgba(255,255,255,.025);
      cursor: pointer;
      border: 1px solid transparent;
      transition: background .16s ease, border-color .16s ease, color .16s ease, transform .16s ease;
    }

    .nav button.active,
    .nav button:hover {
      background: linear-gradient(90deg, rgba(54, 215, 196, .18), rgba(90, 169, 255, .08));
      border-color: rgba(54, 215, 196, .28);
      color: #fff;
      box-shadow: var(--glow);
    }

    .nav button:hover {
      transform: translateX(2px);
    }

    .side-meta {
      margin-top: auto;
      display: grid;
      gap: 10px;
      color: var(--muted);
      font-size: 13px;
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 14px;
      background: rgba(255,255,255,.03);
    }

    .content {
      min-width: 0;
      display: flex;
      flex-direction: column;
    }

    .topbar {
      min-height: 92px;
      background: rgba(7, 16, 21, .76);
      backdrop-filter: blur(18px);
      border-bottom: 1px solid var(--line);
      padding: 18px 24px;
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 18px;
      align-items: center;
    }

    h1 {
      margin: 0;
      font-size: 28px;
      line-height: 1.2;
      letter-spacing: 0;
    }

    .subtle {
      margin-top: 4px;
      color: var(--muted);
      font-size: 14px;
    }

    .controls {
      display: flex;
      gap: 10px;
      align-items: center;
      flex-wrap: wrap;
      justify-content: flex-end;
    }

    .field {
      display: grid;
      gap: 6px;
      min-width: 126px;
    }

    label {
      color: var(--soft);
      font-size: 12px;
      font-weight: 650;
      text-transform: uppercase;
    }

    select,
    input {
      height: 40px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: rgba(255,255,255,.055);
      color: var(--ink);
      padding: 0 11px;
      min-width: 0;
      outline: none;
    }

    select:focus,
    input:focus {
      border-color: var(--line-strong);
      box-shadow: 0 0 0 3px rgba(54, 215, 196, .12);
    }

    option {
      background: #0c161d;
      color: var(--ink);
    }

    .primary-button,
    .icon-button {
      height: 40px;
      border-radius: 8px;
      border: 1px solid transparent;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      white-space: nowrap;
    }

    .primary-button {
      padding: 0 18px;
      background: linear-gradient(135deg, var(--accent), #5aa9ff);
      color: #061014;
      font-weight: 700;
      box-shadow: 0 0 28px rgba(54, 215, 196, .22);
    }

    .primary-button:hover {
      background: linear-gradient(135deg, #6ceedd, #80bdff);
    }

    .icon-button {
      width: auto;
      min-width: 58px;
      padding: 0 12px;
      background: rgba(255,255,255,.055);
      border-color: var(--line);
      color: var(--ink);
    }

    .main {
      padding: 20px 24px 32px;
      display: grid;
      gap: 18px;
      min-width: 0;
    }

    .command-strip {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 10px;
      padding: 14px 24px 0;
    }

    .signal {
      border: 1px solid var(--line);
      border-radius: 8px;
      background: rgba(255,255,255,.04);
      min-height: 44px;
      padding: 9px 12px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      color: var(--muted);
      font-size: 12px;
    }

    .signal strong {
      color: var(--ink);
      font-size: 13px;
      font-weight: 750;
      overflow-wrap: anywhere;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(6, minmax(130px, 1fr));
      gap: 12px;
    }

    .stat {
      background:
        linear-gradient(180deg, rgba(255,255,255,.08), rgba(255,255,255,.025)),
        var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 16px;
      min-height: 96px;
      display: grid;
      gap: 8px;
      box-shadow: var(--shadow);
      position: relative;
      overflow: hidden;
    }

    .stat::after {
      content: "";
      position: absolute;
      inset: auto 14px 0;
      height: 2px;
      background: linear-gradient(90deg, var(--accent), transparent);
    }

    .stat span {
      color: var(--muted);
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
    }

    .stat strong {
      font-size: 30px;
      line-height: 1;
      letter-spacing: 0;
    }

    .toolbar {
      display: grid;
      grid-template-columns: minmax(220px, 1fr) repeat(3, minmax(150px, 190px));
      gap: 10px;
      align-items: end;
    }

    .surface {
      background:
        linear-gradient(180deg, rgba(255,255,255,.055), rgba(255,255,255,.02)),
        var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      box-shadow: var(--shadow);
      overflow: hidden;
      min-width: 0;
    }

    .surface-head {
      min-height: 54px;
      padding: 14px 16px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-bottom: 1px solid var(--line);
      background: rgba(255,255,255,.025);
    }

    .surface-head h2 {
      margin: 0;
      font-size: 17px;
      letter-spacing: 0;
    }

    .status {
      color: var(--muted);
      font-size: 13px;
    }

    .timetable-wrap {
      overflow: auto;
      max-height: calc(100vh - 318px);
    }

    .timetable {
      min-width: 980px;
      display: grid;
      grid-template-columns: 84px repeat(6, minmax(148px, 1fr));
      align-items: stretch;
    }

    .cell {
      border-right: 1px solid rgba(151, 188, 196, .13);
      border-bottom: 1px solid rgba(151, 188, 196, .13);
      min-height: 112px;
      padding: 8px;
      background: rgba(9, 20, 27, .74);
    }

    .cell.header,
    .cell.slot {
      min-height: 44px;
      background: rgba(18, 34, 43, .96);
      font-weight: 750;
      color: var(--soft);
      position: sticky;
      z-index: 2;
      backdrop-filter: blur(14px);
    }

    .cell.header { top: 0; }
    .cell.slot {
      left: 0;
      z-index: 1;
      display: flex;
      align-items: center;
    }

    .course {
      border: 1px solid rgba(255,255,255,.07);
      border-left: 4px solid var(--blue);
      border-radius: 6px;
      background: linear-gradient(135deg, rgba(90,169,255,.16), rgba(255,255,255,.045));
      padding: 8px;
      display: grid;
      gap: 4px;
      margin-bottom: 8px;
      min-height: 70px;
      box-shadow: inset 0 1px 0 rgba(255,255,255,.08);
    }

    .course:nth-child(3n+1) { border-left-color: var(--accent); }
    .course:nth-child(3n+2) { border-left-color: var(--amber); }
    .course:nth-child(3n+3) { border-left-color: var(--green); }

    .course strong {
      font-size: 13px;
      line-height: 1.25;
      overflow-wrap: anywhere;
      color: var(--ink);
    }

    .course span {
      color: var(--soft);
      font-size: 12px;
      line-height: 1.25;
      overflow-wrap: anywhere;
    }

    .list-view {
      display: none;
      overflow: auto;
      max-height: calc(100vh - 318px);
    }

    table {
      width: 100%;
      border-collapse: collapse;
      min-width: 760px;
    }

    th,
    td {
      padding: 11px 12px;
      text-align: left;
      border-bottom: 1px solid var(--line);
      font-size: 14px;
    }

    th {
      background: rgba(18, 34, 43, .96);
      color: var(--soft);
      font-size: 12px;
      text-transform: uppercase;
      position: sticky;
      top: 0;
    }

    .empty,
    .error {
      padding: 28px;
      color: var(--muted);
    }

    .error {
      color: var(--red);
      font-weight: 700;
    }

    .loading {
      opacity: .65;
      pointer-events: none;
    }

    @media (max-width: 980px) {
      .app { grid-template-columns: 1fr; }
      .sidebar {
        position: sticky;
        top: 0;
        z-index: 5;
        padding: 14px;
        gap: 12px;
      }
      .brand { padding-bottom: 12px; }
      .nav {
        display: flex;
        overflow-x: auto;
      }
      .nav button {
        width: auto;
        min-width: 118px;
        text-align: center;
      }
      .side-meta { display: none; }
      .command-strip {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        padding: 14px 16px 0;
      }
      .topbar {
        grid-template-columns: 1fr;
        padding: 16px;
      }
      .controls { justify-content: stretch; }
      .field { min-width: 0; flex: 1 1 130px; }
      .main { padding: 16px; }
      .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .toolbar { grid-template-columns: 1fr; }
      .timetable-wrap,
      .list-view { max-height: none; }
    }

    @media (max-width: 560px) {
      .stats { grid-template-columns: 1fr; }
      .command-strip { grid-template-columns: 1fr; }
      h1 { font-size: 21px; }
      .primary-button { width: 100%; }
    }
  </style>
</head>
<body>
  <div class="app">
    <aside class="sidebar">
      <div class="brand">
        <strong>Campus Timetable</strong>
        <span>INSAT scheduler dashboard</span>
      </div>
      <nav class="nav" aria-label="Schedule views">
        <button class="active" data-view="grid">Timetable</button>
        <button data-view="table">Assignments</button>
        <button data-view="rooms">Rooms</button>
        <button data-view="groups">Groups</button>
        <button data-view="catalog">Class Catalog</button>
      </nav>
      <div class="side-meta">
        <div id="sideScenario">Scenario: --</div>
        <div id="sideRuntime">Runtime: --</div>
      </div>
    </aside>

    <section class="content">
      <header class="topbar">
        <div>
          <h1>Schedule Visualizer</h1>
          <div class="subtle" id="subtitle">Generate and inspect weekly room, group, and course assignments.</div>
        </div>
        <div class="controls">
          <div class="field">
            <label for="scenario">Scenario</label>
            <select id="scenario">
              <option value="demo">demo</option>
              <option value="gl3_only">gl3_only</option>
              <option value="engineering">engineering</option>
              <option value="full_campus">full_campus</option>
            </select>
          </div>
          <div class="field">
            <label for="timeout">Timeout</label>
            <input id="timeout" type="number" min="1" max="600" value="120">
          </div>
          <button class="primary-button" id="generate">Generate</button>
          <button class="icon-button" id="refresh" title="Regenerate schedule" aria-label="Regenerate schedule">Sync</button>
        </div>
      </header>

      <section class="command-strip" aria-label="Schedule status">
        <div class="signal"><span>Active scenario</span><strong id="signalScenario">--</strong></div>
        <div class="signal"><span>Generation time</span><strong id="signalRuntime">--</strong></div>
        <div class="signal"><span>Visible load</span><strong id="signalVisible">--</strong></div>
        <div class="signal"><span>Max slot</span><strong id="signalSlot">--</strong></div>
      </section>

      <main class="main">
        <section class="stats" id="stats"></section>

        <section class="toolbar">
          <div class="field">
            <label for="search">Search</label>
            <input id="search" type="search" placeholder="subject, class, group, room">
          </div>
          <div class="field">
            <label for="dayFilter">Day</label>
            <select id="dayFilter"><option value="">All days</option></select>
          </div>
          <div class="field">
            <label for="groupFilter">Group</label>
            <select id="groupFilter"><option value="">All groups</option></select>
          </div>
          <div class="field">
            <label for="roomFilter">Room</label>
            <select id="roomFilter"><option value="">All rooms</option></select>
          </div>
        </section>

        <section class="surface">
          <div class="surface-head">
            <h2 id="viewTitle">Timetable</h2>
            <div class="status" id="status">Ready</div>
          </div>
          <div class="timetable-wrap" id="gridView"></div>
          <div class="list-view" id="listView"></div>
        </section>
      </main>
    </section>
  </div>

  <script>
    const state = {
      data: null,
      view: "grid",
      filtered: [],
      refresh: false
    };

    const els = {
      scenario: document.getElementById("scenario"),
      timeout: document.getElementById("timeout"),
      generate: document.getElementById("generate"),
      refresh: document.getElementById("refresh"),
      stats: document.getElementById("stats"),
      status: document.getElementById("status"),
      subtitle: document.getElementById("subtitle"),
      gridView: document.getElementById("gridView"),
      listView: document.getElementById("listView"),
      viewTitle: document.getElementById("viewTitle"),
      search: document.getElementById("search"),
      dayFilter: document.getElementById("dayFilter"),
      groupFilter: document.getElementById("groupFilter"),
      roomFilter: document.getElementById("roomFilter"),
      sideScenario: document.getElementById("sideScenario"),
      sideRuntime: document.getElementById("sideRuntime"),
      signalScenario: document.getElementById("signalScenario"),
      signalRuntime: document.getElementById("signalRuntime"),
      signalVisible: document.getElementById("signalVisible"),
      signalSlot: document.getElementById("signalSlot")
    };

    function titleCase(value) {
      return value.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase());
    }

    function setLoading(isLoading) {
      document.body.classList.toggle("loading", isLoading);
      els.status.textContent = isLoading ? "Generating schedule..." : "Ready";
    }

    function stat(label, value) {
      return `<div class="stat"><span>${label}</span><strong>${value}</strong></div>`;
    }

    function renderStats() {
      const s = state.data.summary;
      els.stats.innerHTML = [
        stat("Assignments", s.total_assignments),
        stat("Rooms", s.rooms),
        stat("Groups", s.groups),
        stat("Courses", s.courses),
        stat("CSV matched", s.csv_matches),
        stat("Days", `${s.days}/6`)
      ].join("");
    }

    function fillSelect(select, items, first) {
      const current = select.value;
      select.innerHTML = `<option value="">${first}</option>` + items.map(item => (
        `<option value="${item}">${item}</option>`
      )).join("");
      if (items.includes(current)) select.value = current;
    }

    function renderFilters() {
      fillSelect(els.dayFilter, state.data.days, "All days");
      fillSelect(els.groupFilter, state.data.groups, "All groups");
      fillSelect(els.roomFilter, state.data.rooms, "All rooms");
    }

    function applyFilters() {
      const q = els.search.value.trim().toLowerCase();
      const day = els.dayFilter.value;
      const group = els.groupFilter.value;
      const room = els.roomFilter.value;

      state.filtered = state.data.assignments.filter(item => {
        const text = `${item.course_id} ${item.course_name} ${item.subject_name} ${item.class_label} ${item.group_id} ${item.room_id} ${item.day} ${item.slot}`.toLowerCase();
        return (!q || text.includes(q))
          && (!day || item.day === day)
          && (!group || item.group_id === group)
          && (!room || item.room_id === room);
      });
      renderCurrentView();
    }

    function courseBlock(item) {
      return `<div class="course">
        <strong>${item.subject_name || item.course_name || item.course_id}</strong>
        <span>${item.class_label || item.group_id} / ${item.session_type.toUpperCase()} / ${item.session_hours}h</span>
        <span>${item.room_id}</span>
      </div>`;
    }

    function renderGrid() {
      const days = state.data.days;
      const slots = state.data.slots;
      const filteredSet = new Set(state.filtered.map(item => `${item.day}:${item.slot}:${item.course_id}:${item.group_id}:${item.room_id}`));
      let html = `<div class="timetable"><div class="cell header">Slot</div>`;
      days.forEach(day => html += `<div class="cell header">${titleCase(day)}</div>`);
      slots.forEach(slot => {
        html += `<div class="cell slot">${slot}</div>`;
        days.forEach(day => {
          const items = (state.data.by_slot[day]?.[String(slot)] || []).filter(item =>
            filteredSet.has(`${item.day}:${item.slot}:${item.course_id}:${item.group_id}:${item.room_id}`)
          );
          html += `<div class="cell">${items.map(courseBlock).join("")}</div>`;
        });
      });
      html += `</div>`;
      els.gridView.innerHTML = html;
    }

    function renderTable(items, mode) {
      if (!items.length) {
        els.listView.innerHTML = `<div class="empty">No assignments match the current filters.</div>`;
        return;
      }
      let rows = items.map(item => `<tr>
        <td>${titleCase(item.day)}</td>
        <td>${item.slot}</td>
        <td>${item.subject_name || item.course_name || item.course_id}</td>
        <td>${item.class_label || item.group_id}</td>
        <td>${item.session_type}</td>
        <td>${item.session_hours}h</td>
        <td>${item.room_id}</td>
      </tr>`).join("");
      els.listView.innerHTML = `<table>
        <thead><tr><th>Day</th><th>Slot</th><th>Subject</th><th>Class</th><th>Type</th><th>Hours</th><th>Room</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>`;
    }

    function renderCatalog() {
      const entries = Object.entries(state.data.class_catalog || {});
      if (!entries.length) {
        els.listView.innerHTML = `<div class="empty">No CSV catalog was loaded. Set SCHED_CSV_PATH or add data/INSAT_Class_Schedules.csv.</div>`;
        return;
      }

      const q = els.search.value.trim().toLowerCase();
      const group = els.groupFilter.value;
      let rows = [];
      entries.forEach(([classLabel, subjects]) => {
        subjects.forEach(subject => {
          const text = `${classLabel} ${subject.group_id} ${subject.subject}`.toLowerCase();
          if (q && !text.includes(q)) return;
          if (group && subject.group_id !== group) return;
          rows.push(`<tr>
            <td>${classLabel}</td>
            <td>${subject.subject}</td>
            <td>${subject.total_hours}h</td>
            <td>${subject.course_hours}h</td>
            <td>${subject.td_hours}h</td>
            <td>${subject.tp_hours}h</td>
          </tr>`);
        });
      });

      els.listView.innerHTML = rows.length
        ? `<table>
            <thead><tr><th>Class</th><th>Subject</th><th>Total</th><th>Course</th><th>TD</th><th>TP</th></tr></thead>
            <tbody>${rows.join("")}</tbody>
          </table>`
        : `<div class="empty">No class catalog entries match the current filters.</div>`;
    }

    function renderCurrentView() {
      if (!state.data) return;
      const isGrid = state.view === "grid";
      els.gridView.style.display = isGrid ? "block" : "none";
      els.listView.style.display = isGrid ? "none" : "block";

      const titles = {
        grid: "Timetable",
        table: "Assignments",
        rooms: "Rooms",
        groups: "Groups",
        catalog: "Class Catalog"
      };
      els.viewTitle.textContent = titles[state.view];
      els.status.textContent = `${state.filtered.length} visible`;
      els.signalVisible.textContent = `${state.filtered.length} / ${state.data.summary.total_assignments}`;

      if (isGrid) {
        renderGrid();
        return;
      }

      if (state.view === "catalog") {
        renderCatalog();
        return;
      }

      const sorted = [...state.filtered].sort((a, b) => {
        if (state.view === "rooms") return a.room_id.localeCompare(b.room_id) || a.day.localeCompare(b.day) || a.slot - b.slot;
        if (state.view === "groups") return a.group_id.localeCompare(b.group_id) || a.day.localeCompare(b.day) || a.slot - b.slot;
        return state.data.days.indexOf(a.day) - state.data.days.indexOf(b.day) || a.slot - b.slot;
      });
      renderTable(sorted, state.view);
    }

    async function loadSchedule(refresh = false) {
      setLoading(true);
      els.gridView.innerHTML = "";
      els.listView.innerHTML = "";
      try {
        const params = new URLSearchParams({
          scenario: els.scenario.value,
          limit: "1",
          timeout: els.timeout.value || "120",
          refresh: String(refresh)
        });
        const response = await fetch(`/api/schedule?${params.toString()}`);
        const data = await response.json();
        if (!response.ok) throw new Error(data.detail || "Schedule generation failed.");

        state.data = data;
        state.filtered = data.assignments;
        els.subtitle.textContent = `${titleCase(data.scenario)} generated ${data.summary.total_assignments} assignments. ${data.csv_loaded ? "CSV class catalog loaded." : "CSV class catalog not found."}`;
        els.sideScenario.textContent = `Scenario: ${data.scenario}`;
        els.sideRuntime.textContent = `Runtime: ${(data.elapsed_ms / 1000).toFixed(1)}s`;
        els.signalScenario.textContent = data.scenario;
        els.signalRuntime.textContent = `${(data.elapsed_ms / 1000).toFixed(1)}s`;
        els.signalSlot.textContent = data.summary.max_slot;
        renderStats();
        renderFilters();
        applyFilters();
      } catch (error) {
        els.stats.innerHTML = "";
        els.gridView.innerHTML = `<div class="error">${error.message}</div>`;
        els.status.textContent = "Error";
      } finally {
        setLoading(false);
      }
    }

    document.querySelectorAll(".nav button").forEach(button => {
      button.addEventListener("click", () => {
        document.querySelectorAll(".nav button").forEach(item => item.classList.remove("active"));
        button.classList.add("active");
        state.view = button.dataset.view;
        renderCurrentView();
      });
    });

    [els.search, els.dayFilter, els.groupFilter, els.roomFilter].forEach(el => {
      el.addEventListener("input", applyFilters);
      el.addEventListener("change", applyFilters);
    });

    els.generate.addEventListener("click", () => loadSchedule(false));
    els.refresh.addEventListener("click", () => loadSchedule(true));

    loadSchedule(false);
  </script>
</body>
</html>
"""


def main() -> None:
    require_fastapi()
    try:
        import uvicorn
    except ModuleNotFoundError:
        print("ERROR: Uvicorn is not installed.")
        print("Install it with: python -m pip install fastapi uvicorn")
        sys.exit(1)

    host = os.environ.get("SCHED_HOST", "127.0.0.1")
    port = int(os.environ.get("SCHED_PORT", "8000"))
    print("Starting schedule visualizer at http://{}:{}".format(host, port))
    uvicorn.run("schedule_visualizer:app", host=host, port=port, reload=False)


if __name__ == "__main__":
    main()

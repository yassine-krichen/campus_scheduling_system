# INSAT Intelligent Campus Scheduling System

**Logical Programming Project — Spring 2026**
**INSAT GL3 | Group of 2**

---

## Assignment Summary

The goal of this project is to build a **Prolog-based declarative scheduling engine** that generates a valid weekly timetable for a multi-building university campus (INSAT) while respecting:

- **Structural constraints**: no room double-booking, no student group attending two sessions simultaneously
- **Resource constraints**: room capacity ≥ group enrollment, equipment type compatibility
- **Personnel constraints**: instructor availability (timetable-based, with exceptions)
- **Energy constraints**: per-building daily energy consumption must not exceed STEG metering thresholds
- **Optimisation**: schedules are scored by total energy use, daily load imbalance, and room fairness

The system must not only find feasible schedules but also compare and rank alternatives using quantitative criteria.

---

## Current Status

| Component | Status | Owner |
|-----------|--------|-------|
| `time_slots.pl` | ✅ Complete | Knowledge Base |
| `buildings_and_rooms.pl` | ✅ Complete | Knowledge Base |
| `groups.pl` | ✅ Complete | Knowledge Base |
| `instructors.pl` | ✅ Complete | Knowledge Base |
| `courses.pl` | ✅ Complete | Knowledge Base |
| `config.pl` | ✅ Complete | Person 1 |
| `constraints.pl` | ✅ Complete | Person 1 |
| `generator.pl` | ✅ Complete | Person 1 |
| `main.pl` | ✅ Complete | Person 1 |
| `energy.pl` | ✅ Complete | Person 2 |
| `optimizer.pl` | ✅ Complete | Person 2 |
| `interface.pl` | ✅ Complete | Person 2 |

---

## Architecture

```
main.pl
  ├── config.pl            — scenario selection & runtime settings
  ├── time_slots.pl        — temporal knowledge base (days, slots)
  ├── buildings_and_rooms.pl — rooms, buildings, energy rates
  ├── groups.pl            — student groups & enrollments
  ├── instructors.pl       — instructors & availability
  ├── courses.pl           — course facts & course_session/2
  ├── constraints.pl       — hard feasibility constraints
  ├── generator.pl         — recursive scheduler with early failure
  ├── energy.pl            — energy accumulation & thresholds
  ├── optimizer.pl         — multi-criteria schedule scoring
  └── interface.pl         — display, filtering, interactive queries
```

### Data Model

**Assignment** (the unit of output):
```prolog
assign(CourseID, GroupID, RoomID, slot(Day, Index))
```

**Slot** — uniquely identified by day atom and 1-based index:
```prolog
slot(monday, 1)   % 08:00–09:30
slot(monday, 2)   % 09:45–11:15
slot(monday, 3)   % 11:30–13:00
slot(monday, 4)   % 14:00–15:30
slot(monday, 5)   % 15:45–17:15
```
6 days × 5 slots = **30 slots per week**.

**Course** arity-8:
```prolog
course(ID, Name, Dept, Year, SessionsPerWeek, Type, RequiredEquip, InstructorID)
```

**Room** arity-6:
```prolog
room(ID, Building, Floor, Capacity, EquipmentType, HourlyEnergyCost_kW)
```

**Building** arity-3:
```prolog
building(ID, Name, DailyEnergyThreshold_kWh)
```

---

## Configuration

All tunable parameters are centralised in `src/config.pl` and can be overridden via environment variables before launching SWI-Prolog.

### Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SCHED_SCENARIO` | `demo` | Active scenario (`demo` \| `gl3_only` \| `engineering` \| `full_campus`) |
| `SCHED_LIMIT` | `1` | Max number of valid schedules to collect |
| `SCHED_OPT` | `none` | Optimisation mode (`none` \| `energy` \| `balanced`) |
| `SCHED_ENERGY` | `true` | Enforce building energy thresholds (`true` \| `false`) |

### Scenarios

| Scenario | Departments | Years | Scope |
|----------|-------------|-------|-------|
| `demo` | GL | 3 | GL Year 3 only — fastest, best for defence demos |
| `gl3_only` | GL | 2–5 | All GL years |
| `engineering` | GL, RT, IMI, CH, BIO | 2–5 | All engineering streams |
| `full_campus` | All | All | Entire INSAT knowledge base (slow) |

See `.env.example` for a ready-to-use configuration template.

---

## How to Run

### Prerequisites

- [SWI-Prolog](https://www.swi-prolog.org/Download.html) ≥ 9.x installed and `swipl` in PATH.

### Quick Start (demo scenario, first valid schedule)

```powershell
# Windows PowerShell
cd path\to\project
swipl main.pl
```

At the `?-` prompt:
```prolog
?- run_scheduler.
```

### Changing Scenario at Runtime

```powershell
# Windows — set env before launching
$env:SCHED_SCENARIO = "gl3_only"
$env:SCHED_LIMIT    = "3"
$env:SCHED_OPT      = "energy"
swipl main.pl
```

```bash
# Linux / macOS
SCHED_SCENARIO=gl3_only SCHED_LIMIT=3 SCHED_OPT=energy swipl main.pl
```

### Non-Interactive (script mode)

```powershell
swipl -g run_scheduler -t halt main.pl
```

### Interactive Queries

After loading, all public predicates can be queried interactively:

```prolog
% Generate one schedule
?- generate_schedule(S).

% Show assignments for a specific group
?- schedule_for_group(gl3_a, A).

% Show assignments for a specific room
?- schedule_for_room(r136, A).

% Validate a schedule post-hoc
?- generate_schedule(S), validate_schedule(S).

% Check how many work items the demo scenario has
?- build_work_list(WL), length(WL, N).

% Active scenario details
?- scenario_courses(C), length(C, NC), scenario_groups(G), length(G, NG).
```

---

## Visualizing Schedules (Python UI)

After generating schedules, use the included Python visualization tools to view and analyze them.

### Option 1: Interactive Terminal Viewer (Recommended)

```bash
python schedule_viewer.py
```

Menu options:
- **Summary** — Statistics (total assignments, rooms in use, etc.)
- **By Room** — What's scheduled in each room and when
- **By Group** — Each group's timetable
- **By Day** — Daily breakdown with all activities
- **Timetable Grid** — Slot-by-slot view
- **All Views** — Show everything at once

### Option 2: Graphical Viewer (Tkinter)

```bash
python schedule_visualizer.py
```

Or from terminal viewer: `python schedule_viewer.py --gui`

Click buttons to switch between Room/Group/Day views and Summary.

### Example Usage

**Quick 3-step visualization:**
```bash
python schedule_viewer.py
# Press: 1 (Summary), Enter
# Press: 0 (Exit), Enter
```

**View everything at once:**
```bash
echo "6" | python schedule_viewer.py
```

**Save to file:**
```bash
echo "1" | python schedule_viewer.py > my_schedule.txt 2>&1
```

For detailed documentation, see: **QUICKSTART_VISUALIZATION.md** and **VISUALIZATION_README.md**

---

## Module Responsibilities

### `config.pl` — Person 1
Centralises all runtime-tunable settings. Reads environment variables via `getenv/2` with compiled-in defaults. Exposes `setting/2`, `scenario_courses/1`, and `scenario_groups/1` so downstream modules never hard-code scope.

### `constraints.pl` — Person 1
Implements all five hard feasibility predicates:

| Predicate | Checks |
|-----------|--------|
| `equipment_satisfied/2` | Room equipment compatible with course requirement |
| `capacity_satisfied/3` | Room capacity ≥ group enrollment |
| `instructor_available_for/2` | Instructor not listed as unavailable at that slot |
| `no_room_conflict/1` | No two assignments share the same (Room, Slot) |
| `no_group_conflict/1` | No two assignments share the same (Group, Slot) |

The combined predicate `all_constraints_satisfied/2` applies checks in cheapest-first order (static lookups before list scans) to maximise early pruning.

### `generator.pl` — Person 1
Implements the recursive schedule builder:
- `build_work_list/1` — expands `course_session/2` pairs by `SessionsPerWeek` into a flat work list
- `assign_all/3` — recurses over the work list, accumulating a partial assignment list
- `assign_one/4` — iterates over (Slot × Room) candidates via backtracking, calling `all_constraints_satisfied/2` and the energy constraint check before committing
- `generate_n_schedules/2` — collects up to N schedules with `findnsols/4`

### `energy.pl` — Person 2
Energy accumulation and threshold validation:
- `assignment_energy/2` — energy per assignment = hourly rate × 1.5 h
- `building_daily_energy/4` — sum over a day per building
- `building_energy_ok/3` — threshold check
- `total_weekly_energy/2` — campus-wide weekly total

### `optimizer.pl` — Person 2
Multi-criteria schedule scoring:
- `schedule_score/2` — composite score (energy + imbalance + fairness)
- `best_schedule/2` — selects highest-scoring schedule from a list
- `compare_schedules/3` — pairwise comparison

### `interface.pl` — Person 2
Terminal-friendly output and filtering:
- `run_scheduler/0` — main orchestration predicate (overrides the fallback in `main.pl`)
- `display_schedule/1` — formatted timetable output
- `query_group/2`, `query_room/2` — focused filtering

---

## Constraint Ordering and Search Complexity

The generator applies constraints in the following order for each candidate `assign(C, G, R, Slot)`:

1. **`equipment_satisfied/2`** — eliminates ~80–90% of room candidates for lab courses immediately (pure KB lookup, O(1))
2. **`capacity_satisfied/3`** — further eliminates undersized rooms (O(1))
3. **`instructor_available_for/2`** — eliminates slots where the instructor is unavailable (O(1))
4. **`room_free_for/3`** — linear scan of partial list — only reached after the above filters
5. **`group_free_at/3`** — linear scan of partial list

**Theoretical branching factor** without constraints: 130 rooms × 30 slots = 3,900 per work item.
With equipment filtering active: typically 3–20 compatible rooms per course type, reducing the factor by 99%+.

---

## Known Limitations and Realistic Scope

- **Full-campus exhaustive optimisation is not the default execution path.** The full knowledge base contains >600 `course_session` pairs, each requiring 1–2 weekly sessions. Exhaustive search over all of them simultaneously is computationally infeasible in pure Prolog without constraint solvers (CLP). The `candidate_limit` setting (default 1) means the system returns the first valid schedule found.
- **The `demo` scenario (GL Year 3 only)** is the recommended setting for the defence. It produces a valid schedule in sub-second time.
- **Energy constraints** can be disabled via `SCHED_ENERGY=false` to speed up generation if building thresholds are too restrictive for a given scenario.
- **No HTTP interface** — this is a terminal-first deliverable as per project scope.

---

## Work Split

| Task | Person 1 | Person 2 |
|------|----------|----------|
| Knowledge base (existing) | Maintained & integrated | — |
| `config.pl` | ✅ | — |
| `constraints.pl` | ✅ | — |
| `generator.pl` | ✅ | — |
| `main.pl` | ✅ | — |
| README — architecture, setup, work split | ✅ | — |
| `energy.pl` | — | ✅ |
| `optimizer.pl` | — | ✅ |
| `interface.pl` | — | ✅ |
| Demo output, screenshots, report tables | — | ✅ |
| Final testing (both scenarios) | ✅ | ✅ |
| Report — pruning analysis, tradeoffs | ✅ | ✅ |

---

## File Structure

```
project/
├── main.pl                    ← entry point
├── README.md                  ← this file
├── LICENSE                    ← MIT License
├── .gitignore                 ← Git ignore rules
├── .env.example               ← configuration template
├── docs/                      ← Project documentation & assignment
│   ├── project_assignment.md
│   └── PLAN.md
├── tests/                     ← Automated tests
│   └── sanity_test.pl
└── src/
    ├── config.pl              ← [Person 1] scenario & settings
    ├── time_slots.pl          ← [KB] temporal facts
    ├── buildings_and_rooms.pl ← [KB] spatial facts + energy
    ├── groups.pl              ← [KB] student groups
    ├── instructors.pl         ← [KB] instructor availability
    ├── courses.pl             ← [KB] course facts
    ├── constraints.pl         ← [Person 1] hard constraints
    ├── generator.pl           ← [Person 1] recursive generator
    ├── energy.pl              ← [Person 2] energy reasoning
    ├── optimizer.pl           ← [Person 2] multi-criteria optimizer
    └── interface.pl           ← [Person 2] display & queries
```

---

## Submission

**Deadline:** Sunday, May 3rd at midnight (strict).
**Defence:** Tuesday, May 5th.

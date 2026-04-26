# Finish INSAT Scheduler as a 2-Person, Configurable Prolog Project

## Summary
We will keep the existing knowledge-base work, treat it as the project foundation already completed, and finish the project around a **configurable scheduler core** rather than assuming the full-campus dataset must always be solved in one heavy run.

The plan is to deliver:
- a working Prolog scheduler with hard constraints, energy checks, and basic optimization
- a **configurable scenario layer** so you can run a smaller/demo scenario or the larger dataset without editing core code
- a rewritten [README.md](C:\Users\user\Desktop\root\uni\gl3_2nd_term\logical_programming\project\README.md) that explains the assignment, current architecture, how to run it, what is implemented, what is configurable, and how work is split between Person 1 and Person 2

## Key Changes
- Keep the existing base modules as the source of domain facts:
  - `time_slots.pl`
  - `buildings_and_rooms.pl`
  - `groups.pl`
  - `instructors.pl`
  - `courses.pl`
- Add a **configuration layer** for tunable values and scenario selection.
  - Use a `.env`-inspired file for values such as dataset mode, active departments/years, candidate limits, optimization mode, and export toggles.
  - Parse that config at startup into Prolog-accessible settings; if `.env` parsing is too brittle in pure Prolog, fall back to a small generated/config module while preserving the same external variable names.
- Implement the core scheduling pipeline:
  - `constraints.pl`: room conflict, group conflict, capacity, equipment, instructor availability, and combined constraint checks
  - `generator.pl`: recursive assignment with **early failure**
  - `energy.pl`: assignment energy, per-building/per-day totals, threshold validation, total weekly energy
  - `optimizer.pl`: schedule scoring with a practical strategy that does not require enumerating all full-campus schedules
  - `interface.pl`: terminal-first interface with readable schedule output and focused queries
- Fix integration mismatches discovered during planning:
  - export or otherwise expose `equipment_compatible/2` so constraints can use it cleanly
  - decide whether `all_slots/1` should be exported or whether generation should iterate via `time_slot/6`
  - update the old README language that still assumes a 6-member team
- Keep optimization practical:
  - default to a bounded candidate search or first-valid-plus-ranking strategy for larger scenarios
  - allow a smaller scenario mode for demonstrations and defense
  - document that “full campus exhaustive optimization” is not the default execution path
- Rewrite [README.md](C:\Users\user\Desktop\root\uni\gl3_2nd_term\logical_programming\project\README.md) so it includes:
  - assignment summary in plain language
  - current project status and what was already done
  - architecture and data model
  - configuration variables and example `.env`
  - run instructions
  - module responsibilities
  - known limitations and realistic scope
  - explicit 2-person work split, with you as **Person 1**

## Public Interfaces / Types
- Keep assignment shape:
  - `assign(CourseID, GroupID, RoomID, Slot)`
- Keep slot shape:
  - `slot(Day, Index)`
- Main entrypoint remains:
  - `run_scheduler/0`
- Core scheduler predicates to expose and stabilize:
  - `generate_schedule/1`
  - `all_constraints_satisfied/1`
  - `building_energy_ok/3`
  - `total_weekly_energy/2`
  - `schedule_score/2`
  - `display_schedule/1`
- New config-facing behavior:
  - startup reads scenario/config values before generation
  - default values are used when config entries are missing

## Team Split
- **Person 1 (you)**:
  - understand and preserve the existing knowledge base
  - own config/scenario system
  - implement `constraints.pl`
  - implement `generator.pl`
  - handle core integration through `main.pl`
  - write the README sections for architecture, setup, and work split
- **Person 2 (your colleague)**:
  - implement `energy.pl`
  - implement `optimizer.pl`
  - implement `interface.pl`
  - help produce demo output, screenshots, report tables, and defense-facing material
- Shared:
  - final testing on at least one small scenario and one larger scenario
  - report discussion of pruning, feasibility, and optimization tradeoffs

## Test Plan
- Knowledge base sanity:
  - counts of groups, rooms, courses, and course-session mappings load correctly
  - config can narrow the active scenario without editing source facts
- Constraint tests:
  - reject same room/same slot conflicts
  - reject same group/same slot conflicts
  - reject undersized rooms
  - reject incompatible equipment
  - reject unavailable instructors
- Energy tests:
  - per-assignment energy is computed correctly
  - daily building totals match expected sums
  - schedules exceeding a building threshold are rejected
- Generator tests:
  - small scenario produces at least one valid schedule
  - invalid scenario fails cleanly
  - incremental constraint checks prune early
- Optimizer tests:
  - lower-energy candidate scores better than higher-energy candidate
  - imbalance and fairness metrics are deterministic
- Interface tests:
  - `run_scheduler/0` prints a readable result
  - group and room filtering work on generated assignments

## Assumptions
- We are planning for a **terminal-first** deliverable, not an HTTP web app, unless you later choose to add it.
- The current full dataset is valuable as a knowledge base, but default execution should support a smaller/configured scenario for reliable demos.
- The `.env` idea is accepted, but implementation may use a simple Prolog-friendly parser or equivalent config bridge depending on SWI-Prolog practicality.
- The machine currently does **not** have `swipl` available in PATH, so part of implementation/verification planning must include local SWI-Prolog setup before execution testing.
- The rewritten README should describe the project as a **2-person collaboration**, not preserve the old 6-member template.

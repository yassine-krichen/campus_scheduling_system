# Campus Schedule Visualization Tools

This project now has two schedule viewers:

- `schedule_viewer.py`: interactive terminal viewer
- `schedule_visualizer.py`: FastAPI web timetable dashboard

## Install Web Dependencies

```bash
python -m pip install -r requirements.txt
```

The terminal viewer only uses the Python standard library. The web UI requires FastAPI and Uvicorn.

## Terminal Viewer

```bash
python schedule_viewer.py
```

Use it for fast text output and scripted checks.

## Web Timetable UI

```bash
python schedule_visualizer.py
```

Then open:

```text
http://127.0.0.1:8000
```

The web UI includes:

- Day and slot timetable grid
- Searchable assignment table
- Room-focused and group-focused navigation
- CSV-backed class catalog with subject and hour totals
- Day, room, and group filters
- Scenario selector
- Regenerate button
- Schedule summary metrics

The old `--gui` shortcut still works, but now starts the web app:

```bash
python schedule_viewer.py --gui
```

## Scenario and Timeout Settings

The scheduler reads these environment variables:

```bash
$env:SCHED_SCENARIO="gl3_only"
$env:SCHED_KB="legacy"
$env:SCHED_LIMIT="1"
$env:SCHED_TIMEOUT="120"
python schedule_visualizer.py
```

## CSV Class Catalog

The visualizer enriches timetable cards with real class labels, subject names, and hour totals from:

```text
data/INSAT_Class_Schedules.csv
```

To use another CSV file:

```bash
$env:SCHED_CSV_PATH="D:\path\to\INSAT_Class_Schedules.csv"
python schedule_visualizer.py
```

Expected columns:

```text
Class,Subject,Total_Hours,Course_Hours,TD_Hours,TP_Hours
```

To regenerate the Prolog knowledge-base facts from the CSV:

```bash
python tools/generate_csv_kb.py
```

Available scenarios:

- `demo`
- `gl3_only`
- `engineering`
- `full_campus`

Knowledge-base sources:

- `legacy`: hand-written Prolog facts
- `csv`: facts generated from `data/INSAT_Class_Schedules.csv`
- `both`: combined facts

Run with the CSV-backed knowledge base:

```bash
$env:SCHED_KB="csv"
python schedule_visualizer.py
```

For larger scenarios, increase the timeout:

```bash
$env:SCHED_SCENARIO="full_campus"
$env:SCHED_KB="legacy"
$env:SCHED_TIMEOUT="180"
python schedule_visualizer.py
```

## API

The web app exposes the generated schedule as JSON:

```text
GET /api/schedule?scenario=gl3_only&kb_source=csv&limit=1&timeout=120
```

Use `refresh=true` to force regeneration instead of returning the cached result:

```text
GET /api/schedule?scenario=gl3_only&kb_source=csv&limit=1&timeout=120&refresh=true
```

## Troubleshooting

If web dependencies are missing:

```bash
python -m pip install -r requirements.txt
```

If SWI-Prolog is not available:

```bash
swipl --version
```

If a large scenario times out:

```bash
$env:SCHED_TIMEOUT="180"
python schedule_visualizer.py
```

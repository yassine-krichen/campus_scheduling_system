# Quick Start Guide - Schedule Visualization

## Option 1: Terminal Viewer

Use the interactive terminal viewer for quick checks:

```bash
python schedule_viewer.py
```

Menu options:

```text
1. Summary
2. By Room
3. By Group
4. By Day
5. Timetable Grid
6. All Views
0. Exit
```

## Option 2: Web Timetable UI

Install the web dependencies once:

```bash
python -m pip install -r requirements.txt
```

Start the FastAPI visualizer:

```bash
python schedule_visualizer.py
```

Open:

```text
http://127.0.0.1:8000
```

You can also launch it from the terminal viewer entry point:

```bash
python schedule_viewer.py --gui
```

## Scenario Examples

Small demo:

```bash
$env:SCHED_SCENARIO="demo"
python schedule_visualizer.py
```

GL scenario:

```bash
$env:SCHED_SCENARIO="gl3_only"
python schedule_visualizer.py
```

Full campus with a longer timeout:

```bash
$env:SCHED_SCENARIO="full_campus"
$env:SCHED_LIMIT="1"
$env:SCHED_TIMEOUT="180"
python schedule_visualizer.py
```

## Web UI Features

- Timetable grid by day and slot
- Assignment table for dense review
- Room and group navigation views
- Class catalog from `data/INSAT_Class_Schedules.csv`
- Search across course, group, room, day, and slot
- Filters for day, group, and room
- Scenario selector and regenerate button
- JSON endpoint at `/api/schedule`

To point the visualizer at another CSV:

```bash
$env:SCHED_CSV_PATH="D:\path\to\INSAT_Class_Schedules.csv"
python schedule_visualizer.py
```

To regenerate the Prolog knowledge base from the CSV:

```bash
python tools/generate_csv_kb.py
```

To schedule using CSV-generated facts:

```bash
$env:SCHED_KB="csv"
python schedule_visualizer.py
```

## Troubleshooting

If FastAPI or Uvicorn is missing:

```bash
python -m pip install -r requirements.txt
```

If `swipl` is not found, install SWI-Prolog and make sure it is available in your PATH:

```bash
swipl --version
```

Large scenarios can take more than 30 seconds. Increase the timeout:

```bash
$env:SCHED_TIMEOUT="180"
python schedule_visualizer.py
```

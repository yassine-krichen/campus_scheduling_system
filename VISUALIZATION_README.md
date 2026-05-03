# Campus Schedule Visualization Tools

This directory includes two Python tools for visualizing generated schedules from the INSAT Campus Scheduling System.

## Quick Start

### Terminal Viewer (No GUI)
```bash
python schedule_viewer.py
```

This launches an interactive terminal menu where you can:
- View schedule summary statistics
- Browse assignments by room
- Browse assignments by group
- Browse assignments by day
- View a timetable grid layout
- Generate all views at once

### GUI Viewer (Tkinter)
```bash
python schedule_visualizer.py
```

Or launch from terminal viewer:
```bash
python schedule_viewer.py --gui
```

This opens a graphical window with buttons to switch between:
- **View by Room** — See which courses/groups are in each room and when
- **View by Group** — See which courses each group attends and where
- **View by Day** — See the full day's schedule with all activities
- **Summary** — Statistics and overview of the generated schedule

## Features

### Schedule Parser
Both tools automatically parse Prolog's assignment format:
```
assign(CourseID, GroupID, RoomID, slot(Day, SlotIndex))
```

Examples parsed:
- `assign(gl3_lp_lec, gl3_a, room_01, slot(monday, 1))`
- `assign(mpi_analysis_td, mpi_1, room_15, slot(wednesday, 3))`

### Visualization Views

#### 1. Summary Statistics
```
Total assignments:      32
Rooms in use:           8
Groups scheduled:       2
Days in use:            6/6
```

#### 2. By Room View
Shows each room's complete schedule with courses, groups, day/time:
```
📍 ROOM: room_01
────────────────────────────────────────
Day          Slot   Course                      Group
────────────────────────────────────────
monday       1      gl3_lp_lec                  gl3_a
tuesday      2      mpi_analysis_lec            mpi_1
...
```

#### 3. By Group View
Shows each group's timetable with courses, rooms, day/time:
```
👥 GROUP: gl3_a
────────────────────────────────────────
Day          Slot   Course                      Room
────────────────────────────────────────
monday       1      gl3_lp_lec                  room_01
wednesday    3      gl3_net_lec                 room_05
...
```

#### 4. By Day View
Shows daily schedule organized by time slots:
```
📅 MONDAY
────────────────────────────────────────
Slot   Course                      Group          Room
────────────────────────────────────────
1      gl3_lp_lec                  gl3_a          room_01
2      mpi_analysis_td             mpi_1          room_15
...
```

#### 5. Timetable Grid
Displays time slots on each day with all scheduled activities:
```
📅 MONDAY

  Slot 1:
    • gl3_lp_lec (gl3_a) → room_01
    • mpi_analysis_td (mpi_1) → room_15
    
  Slot 2:
    • iia_algo_lec (iia_1) → room_03
```

## Requirements

- **Python 3.7+** (for terminal viewer; tkinter for GUI)
- **SWI-Prolog 10.0.1+** (must be in PATH or discoverable)
- The main Prolog system files in the project root

### Optional
- `tkinter` — Built-in with Python, required for GUI visualizer

## Installation

1. Ensure Python 3.7+ is installed
2. Ensure SWI-Prolog is accessible from command line:
   ```bash
   swipl --version
   ```

3. No additional Python packages required (uses only stdlib)

## Usage Examples

### Example 1: Quick Terminal View
```bash
$ python schedule_viewer.py
🔄 Connecting to Prolog system...
📅 Generating schedule...
✅ Generated schedule with 32 assignments

======================================================================
SCHEDULE VIEWER - SELECT VIEW
======================================================================
1. Summary
2. By Room
3. By Group
4. By Day
5. Timetable Grid
6. All Views
0. Exit
======================================================================
Enter choice (0-6): 1
```

### Example 2: GUI Visualization
```bash
$ python schedule_visualizer.py
🔄 Connecting to Prolog system...
📅 Generating schedule...
✅ Generated schedule with 32 assignments

# Opens window with toggle buttons for different views
```

### Example 3: View All at Once
```bash
$ python schedule_viewer.py
[menu...]
Enter choice (0-6): 6
# Displays summary, by room, by group, by day, and grid all at once
```

## Implementation Details

### ScheduleParser
- Regex-based parsing of Prolog `assign(...)` terms
- Extracts: CourseID, GroupID, RoomID, Day, SlotIndex
- Returns structured `Assignment` objects

### ScheduleVisualizer
- Grouping functions: by room, by group, by day
- Sorting: consistent day ordering (Mon→Sat), then by slot
- Formatting: aligned columns for readability

### PrologInterface
- Subprocess wrapper for SWI-Prolog
- Calls `generate_schedule(S)` and parses output
- Handles timeouts and errors gracefully

### TerminalScheduleViewer
- Interactive menu-driven interface
- Multiple view modes without recomputing
- Supports --gui flag to launch GUI variant

### ScheduleGUI (Tkinter)
- Multi-view tabbed/button interface
- Auto-resizes text area with scrollbar
- Non-blocking display updates

## Troubleshooting

### Issue: "swipl command not found"
**Solution:** Make sure SWI-Prolog is installed and in your PATH:
```bash
# On Windows
swipl --version

# If not found, add Prolog to PATH or specify full path
```

### Issue: "Failed to generate schedule"
**Solution:** Verify the Prolog system can generate a schedule:
```bash
cd /path/to/campus_scheduling_system
swipl -f main.pl -t "generate_schedule(S), write(S), halt"
```

### Issue: GUI doesn't appear
**Solution:** Tkinter is required but not always bundled:
```bash
# Ubuntu/Debian
sudo apt-get install python3-tk

# macOS
brew install python-tk@3.11

# Windows (included with Python installer)
```

### Issue: Schedule parsing fails
**Solution:** Check Prolog output format hasn't changed:
```bash
swipl -f main.pl -t "generate_schedule(S), format('~w', [S]), halt"
# Should show: [assign(...), assign(...), ...]
```

## Future Enhancements

Potential improvements for the visualization:

1. **Calendar View** — Visual calendar with color-coded events
2. **Conflict Detection** — Highlight scheduling conflicts
3. **Export to PDF/Excel** — Save schedules in other formats
4. **Statistics Dashboard** — Room utilization, group load balancing
5. **Web Interface** — Flask/Streamlit web-based viewer
6. **Interactive Grid** — Click on cells to see details
7. **Constraint Visualization** — Show which constraints affect each assignment
8. **Multi-schedule Comparison** — Compare different generated schedules

## Architecture

```
schedule_viewer.py (Terminal interactive UI)
    ↓
    ├── TerminalScheduleViewer (formatting & display)
    ├── ScheduleParser (Prolog output parsing)
    └── PrologInterface (Prolog system communication)

schedule_visualizer.py (GUI with Tkinter)
    ↓
    ├── ScheduleGUI (Tkinter widgets)
    ├── ScheduleVisualizer (data organization)
    ├── ScheduleParser (Prolog output parsing)
    └── PrologInterface (Prolog system communication)
```

## Notes

- Schedules are generated fresh each time (not cached)
- Generation may take 10-30 seconds depending on scenario
- All assignments use 24-hour slot indexing (1-5 per day)
- Room and group IDs follow INSAT naming conventions
- Day order is fixed: Monday through Saturday

## License

Part of the INSAT Campus Scheduling System project (May 2026)

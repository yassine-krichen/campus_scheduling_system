# Quick Start Guide - Schedule Visualization

## Two Ways to Visualize Your Schedules

### Option 1: Terminal Viewer (Recommended for Quick Views)
Interactive menu-driven viewer in your terminal.

```bash
python schedule_viewer.py
```

Then choose from the menu:
```
1. Summary         - Statistics overview
2. By Room         - See what's in each room
3. By Group        - See each group's schedule
4. By Day          - See daily breakdown
5. Timetable Grid  - Slot-by-slot view
6. All Views       - Show everything
0. Exit
```

**Fastest way to see a schedule:**
```bash
python schedule_viewer.py
# Then press: 1, Enter, 0, Enter
```

---

### Option 2: GUI Viewer (Graphical Interface)
Windowed interface with clickable buttons.

```bash
python schedule_visualizer.py
```

Or from terminal viewer:
```bash
python schedule_viewer.py --gui
```

Then click buttons to switch between views.

---

## Example Output

### Summary View
```
================================================================================
SCHEDULE SUMMARY
================================================================================
Total assignments:      32
Rooms in use:           8
Groups scheduled:       2
Days in use:            6/6
Max slots per day:      6
```

### By Room View
```
ROOM: ROOM_01
────────────────────────────────────────
Day          Slot   Course                      Group
────────────────────────────────────────
monday       1      gl3_lp_lec                  gl3_a
monday       2      mpi_analysis_td             mpi_1
tuesday      3      iia_algo_lec                iia_1
...
```

### By Group View
```
GROUP: GL3_A
────────────────────────────────────────
Day          Slot   Course                      Room
────────────────────────────────────────
monday       1      gl3_lp_lec                  room_01
wednesday    2      gl3_net_lec                 room_05
friday       4      gl3_web_lec                 room_03
...
```

### By Day View
```
MONDAY
────────────────────────────────────────
Slot   Course                      Group          Room
────────────────────────────────────────
1      gl3_lp_lec                  gl3_a          room_01
1      mpi_analysis_td             mpi_1          room_15
2      iia_algo_lec                iia_1          room_03
...
```

### Timetable Grid
```
MONDAY

  Slot 1:
    - gl3_lp_lec (gl3_a) > room_01
    - mpi_analysis_td (mpi_1) > room_15
    
  Slot 2:
    - iia_algo_lec (iia_1) > room_03
    - ch2_chem_lec (ch2_a) > room_08
```

---

## Requirements

- **Python 3.7+**
- **SWI-Prolog** (in PATH)
- **Tkinter** (for GUI - usually included)

### Check if you have everything:
```bash
python --version           # Should show 3.7+
swipl --version           # Should show SWI-Prolog 10.0.1+
```

---

## Tips & Tricks

### 1. Generate Multiple Schedules
Each time you run a viewer, it generates a fresh schedule. Run multiple times to see different valid schedules.

```bash
python schedule_viewer.py  # Generates schedule 1
python schedule_viewer.py  # Generates schedule 2 (probably different!)
```

### 2. Pipe Output to File
Save a schedule view to a text file:

```bash
# Terminal viewer
echo "1" | python schedule_viewer.py > schedule_summary.txt 2>&1

# Or all views
echo "6" | python schedule_viewer.py > full_schedule.txt 2>&1
```

### 3. Compare Views
- **By Room** - Check if rooms are well-utilized
- **By Group** - Verify no time conflicts for students
- **By Day** - See daily load distribution
- **Summary** - Get quantitative metrics

---

## Troubleshooting

**Q: "swipl command not found"**
- A: Install SWI-Prolog and add it to PATH

**Q: GUI doesn't show**
- A: On Linux: `sudo apt install python3-tk`
- A: On Mac: `brew install python-tk`

**Q: "Failed to generate schedule"**
- A: Check if Prolog files are valid: `python test_scheduler.py`

**Q: Viewer is very slow**
- A: This is normal for complex scenarios. Schedule generation can take 10-30 seconds.

---

## What Each Viewer Shows

| Feature | Terminal | GUI |
|---------|----------|-----|
| Quick viewing | ✅ | ✅ |
| Interactive menu | ✅ | ❌ |
| Clicking buttons | ❌ | ✅ |
| Scrollable | Partial | ✅ |
| Scriptable | ✅ | ❌ |
| Pipe to file | ✅ | ❌ |

---

## Next Steps

1. **Run your first visualization:**
   ```bash
   python schedule_viewer.py
   ```

2. **Try different views** to understand your schedule

3. **Generate multiple schedules** to see alternatives

4. **Check the full documentation:**
   ```bash
   cat VISUALIZATION_README.md
   ```

5. **Suggest improvements** for the visualization tools

---

For detailed information, see: **VISUALIZATION_README.md**

#!/usr/bin/env python3
from __future__ import annotations
"""
Schedule Visualizer for INSAT Campus Scheduling System
Provides GUI and terminal-based visualization of generated schedules
"""

import subprocess
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional
try:
    import tkinter as tk
    from tkinter import ttk, messagebox
except ModuleNotFoundError:
    tk = None
    ttk = None
    messagebox = None
import re


@dataclass
class Assignment:
    """Represents a schedule assignment"""
    course_id: str
    group_id: str
    room_id: str
    day: str
    slot: int

    def __str__(self):
        return f"{self.course_id} | {self.group_id} | {self.room_id} | {self.day}:{self.slot}"


class ScheduleParser:
    """Parse Prolog assignment output into Assignment objects"""
    
    DAYS_ORDER = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
    
    @staticmethod
    def parse_assignments(prolog_output: str) -> List[Assignment]:
        """
        Parse Prolog output containing assignments.
        Tries two formats:
        1. Pipe-separated table format from display_schedule:
           course_id | group_id | room_id | day slot number
        2. Prolog assign/4 format: 
           assign(course, group, room, slot(day, num))
        """
        assignments = []
        
        # Try pipe-separated format first (from display_schedule)
        lines = prolog_output.strip().split('\n')
        for line in lines:
            line = line.strip()
            if not line or '|' not in line:
                continue
            
            parts = [p.strip() for p in line.split('|')]
            if len(parts) >= 4:
                course_id = parts[0]
                group_id = parts[1]
                room_id = parts[2]
                day_slot = parts[3]  # e.g., "tuesday slot 2"
                
                # Parse "day slot number" format
                slot_match = re.search(r'(\w+)\s+slot\s+(\d+)', day_slot)
                if slot_match:
                    day = slot_match.group(1)
                    slot = int(slot_match.group(2))
                    assignments.append(Assignment(
                        course_id=course_id,
                        group_id=group_id,
                        room_id=room_id,
                        day=day,
                        slot=slot
                    ))
        
        # If no assignments found, try assign() format
        if not assignments:
            pattern = r'assign\(([^,]+),\s*([^,]+),\s*([^,]+),\s*slot\(([^,]+),\s*(\d+)\)\)'
            matches = re.findall(pattern, prolog_output)
            
            for course, group, room, day, slot in matches:
                assignments.append(Assignment(
                    course_id=course.strip(),
                    group_id=group.strip(),
                    room_id=room.strip(),
                    day=day.strip(),
                    slot=int(slot)
                ))
        
        return assignments


class PrologInterface:
    """Interface with Prolog system"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.main_pl = project_root / "main.pl"
    
    def generate_schedule(self) -> Optional[List[Assignment]]:
        """Generate a schedule from Prolog"""
        try:
            print("[DEBUG] Starting schedule generation...")
            # Query the raw schedule term. This is more reliable than parsing
            # run_scheduler/0's human-readable table output.
            cmd = [
                'swipl', '-q', '-s', str(self.main_pl),
                '-g', 'generate_schedule(S), write(S), halt.'
            ]
            print("[DEBUG] Command: {}".format(' '.join(cmd)))
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=str(self.project_root)
            )
            
            print("[DEBUG] Return code: {}".format(result.returncode))
            print("[DEBUG] Output length: {}".format(len(result.stdout) if result.stdout else 0))
            if result.stderr:
                print("[DEBUG] Stderr: {}".format(result.stderr[:200]))
            
            if result.returncode != 0:
                print("[DEBUG] Prolog returned non-zero exit code")
                return None
            
            print("[DEBUG] Parsing assignments...")
            assignments = ScheduleParser.parse_assignments(result.stdout)
            print("[DEBUG] Parsed {} assignments".format(len(assignments)))
            return assignments
        except Exception as e:
            print("[DEBUG] ERROR generating schedule: {}".format(str(e)))
            import traceback
            traceback.print_exc()
            return None
    
    def get_scenario_data(self) -> Optional[Dict]:
        """Get scenario courses and groups"""
        try:
            cmd = [
                'swipl', '-q', '-f', str(self.main_pl),
                '-t', 'scenario_courses(C), scenario_groups(G), format("courses:~w groups:~w", [C, G]), halt'
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=10,
                cwd=str(self.project_root)
            )
            
            if result.returncode != 0:
                return None
            
            # Parse output
            output = result.stdout
            return {"output": output}
        except Exception:
            return None


class ScheduleVisualizer:
    """Main visualization engine"""
    
    def __init__(self, assignments: List[Assignment]):
        print("[DEBUG] ScheduleVisualizer init with {} assignments".format(len(assignments)))
        self.assignments = assignments
        self.days_order = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
        print("[DEBUG] ScheduleVisualizer initialized successfully")
    
    def get_by_room(self) -> Dict[str, List[Assignment]]:
        """Group assignments by room"""
        result = {}
        for assign in self.assignments:
            if assign.room_id not in result:
                result[assign.room_id] = []
            result[assign.room_id].append(assign)
        
        # Sort by day and slot
        for room in result:
            result[room].sort(key=lambda a: (
                self.days_order.index(a.day) if a.day in self.days_order else 999,
                a.slot
            ))
        
        return result
    
    def get_by_group(self) -> Dict[str, List[Assignment]]:
        """Group assignments by group"""
        result = {}
        for assign in self.assignments:
            if assign.group_id not in result:
                result[assign.group_id] = []
            result[assign.group_id].append(assign)
        
        for group in result:
            result[group].sort(key=lambda a: (
                self.days_order.index(a.day) if a.day in self.days_order else 999,
                a.slot
            ))
        
        return result
    
    def get_by_day(self) -> Dict[str, List[Assignment]]:
        """Group assignments by day"""
        result = {day: [] for day in self.days_order}
        
        for assign in self.assignments:
            if assign.day in result:
                result[assign.day].append(assign)
        
        for day in result:
            result[day].sort(key=lambda a: a.slot)
        
        return result
    
    def format_table_by_room(self) -> str:
        """Format room view as table"""
        by_room = self.get_by_room()
        
        lines = [
            "=" * 100,
            "SCHEDULE BY ROOM",
            "=" * 100
        ]
        
        for room in sorted(by_room.keys()):
            lines.append(f"\n{'─' * 100}")
            lines.append(f"  ROOM: {room.upper()}")
            lines.append(f"{'─' * 100}")
            lines.append(f"  {'Day':<12} {'Slot':<6} {'Course':<30} {'Group':<15}")
            lines.append(f"  {'-' * 96}")
            
            for assign in by_room[room]:
                lines.append(
                    f"  {assign.day:<12} {assign.slot:<6} {assign.course_id:<30} {assign.group_id:<15}"
                )
        
        return "\n".join(lines)
    
    def format_table_by_group(self) -> str:
        """Format group view as table"""
        by_group = self.get_by_group()
        
        lines = [
            "=" * 100,
            "SCHEDULE BY GROUP",
            "=" * 100
        ]
        
        for group in sorted(by_group.keys()):
            lines.append(f"\n{'─' * 100}")
            lines.append(f"  GROUP: {group.upper()}")
            lines.append(f"{'─' * 100}")
            lines.append(f"  {'Day':<12} {'Slot':<6} {'Course':<30} {'Room':<15}")
            lines.append(f"  {'-' * 96}")
            
            for assign in by_group[group]:
                lines.append(
                    f"  {assign.day:<12} {assign.slot:<6} {assign.course_id:<30} {assign.room_id:<15}"
                )
        
        return "\n".join(lines)
    
    def format_table_by_day(self) -> str:
        """Format day view as table"""
        by_day = self.get_by_day()
        
        lines = [
            "=" * 100,
            "SCHEDULE BY DAY",
            "=" * 100
        ]
        
        for day in self.days_order:
            if by_day[day]:
                lines.append(f"\n{'─' * 100}")
                lines.append(f"  {day.upper()}")
                lines.append(f"{'─' * 100}")
                lines.append(f"  {'Slot':<6} {'Course':<30} {'Group':<15} {'Room':<15}")
                lines.append(f"  {'-' * 96}")
                
                for assign in by_day[day]:
                    lines.append(
                        f"  {assign.slot:<6} {assign.course_id:<30} {assign.group_id:<15} {assign.room_id:<15}"
                    )
        
        return "\n".join(lines)
    
    def format_summary(self) -> str:
        """Format summary statistics"""
        by_room = self.get_by_room()
        by_group = self.get_by_group()
        by_day = self.get_by_day()
        
        occupied_rooms = len(by_room)
        occupied_groups = len(by_group)
        occupied_days = sum(1 for day in by_day if by_day[day])
        total_slots = len(self.assignments)
        
        lines = [
            "=" * 100,
            "SCHEDULE SUMMARY",
            "=" * 100,
            f"Total assignments:      {total_slots}",
            f"Rooms in use:           {occupied_rooms}",
            f"Groups scheduled:       {occupied_groups}",
            f"Days in use:            {occupied_days}/6",
            f"Max slots per day:      {max(len(by_day[d]) for d in by_day) if any(by_day.values()) else 0}",
        ]
        
        return "\n".join(lines)


class ScheduleGUI:
    """Tkinter GUI for schedule visualization"""
    
    def __init__(self, root: tk.Tk, visualizer: ScheduleVisualizer):
        print("[DEBUG] ScheduleGUI init starting...")
        self.root = root
        self.visualizer = visualizer
        self.root.title("Campus Schedule Visualizer")
        self.root.geometry("1200x700")
        print("[DEBUG] Tkinter root configured")
        
        self._setup_ui()
        print("[DEBUG] UI setup complete")
    
    def _setup_ui(self):
        """Setup the GUI elements"""
        print("[DEBUG] _setup_ui starting...")
        # Top frame with buttons
        top_frame = ttk.Frame(self.root)
        top_frame.pack(side=tk.TOP, fill=tk.X, padx=10, pady=10)
        print("[DEBUG] Top frame created")
        
        ttk.Button(
            top_frame, text="View by Room",
            command=self._show_by_room
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            top_frame, text="View by Group",
            command=self._show_by_group
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            top_frame, text="View by Day",
            command=self._show_by_day
        ).pack(side=tk.LEFT, padx=5)
        
        ttk.Button(
            top_frame, text="Summary",
            command=self._show_summary
        ).pack(side=tk.LEFT, padx=5)
        
        # Main display area
        self.text_frame = ttk.Frame(self.root)
        self.text_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Text widget with scrollbar
        self.text_widget = tk.Text(
            self.text_frame, wrap=tk.NONE, font=("Courier", 10)
        )
        self.text_widget.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        scrollbar = ttk.Scrollbar(
            self.text_frame, orient=tk.VERTICAL, command=self.text_widget.yview
        )
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.text_widget.config(yscrollcommand=scrollbar.set)
        
        # Show summary by default
        print("[DEBUG] _setup_ui displaying summary...")
        self._show_summary()
        print("[DEBUG] _setup_ui complete")
    
    def _show_text(self, text: str):
        """Display text in the text widget"""
        print("[DEBUG] _show_text called with {} chars".format(len(text)))
        self.text_widget.config(state=tk.NORMAL)
        self.text_widget.delete(1.0, tk.END)
        self.text_widget.insert(1.0, text)
        self.text_widget.config(state=tk.DISABLED)
        print("[DEBUG] Text widget updated")
    
    def _show_by_room(self):
        self._show_text(self.visualizer.format_table_by_room())
    
    def _show_by_group(self):
        self._show_text(self.visualizer.format_table_by_group())
    
    def _show_by_day(self):
        self._show_text(self.visualizer.format_table_by_day())
    
    def _show_summary(self):
        summary = self.visualizer.format_summary()
        details = "\n\n" + self.visualizer.format_table_by_day()
        self._show_text(summary + details)


def main():
    print("[DEBUG] ===== SCHEDULE VISUALIZER STARTED =====")
    try:
        if tk is None:
            print("ERROR: Tkinter is not installed with this Python distribution.")
            print("Use 'python schedule_viewer.py' for the terminal viewer, or reinstall Python with Tcl/Tk support.")
            sys.exit(1)

        project_root = Path(__file__).parent
        print("[DEBUG] Project root: {}".format(project_root))
        
        print("Connecting to Prolog system...")
        prolog = PrologInterface(project_root)
        print("[DEBUG] PrologInterface created")
        
        print("Generating schedule...")
        assignments = prolog.generate_schedule()
        
        if not assignments:
            print("FAILED: Could not generate schedule")
            sys.exit(1)
        
        print("SUCCESS: Generated schedule with {} assignments".format(len(assignments)))
        print("Launching GUI...")
        print("[DEBUG] Creating ScheduleVisualizer...")
        
        visualizer = ScheduleVisualizer(assignments)
        print("[DEBUG] Creating Tkinter root...")
        
        # Launch GUI
        root = tk.Tk()
        print("[DEBUG] Creating ScheduleGUI...")
        gui = ScheduleGUI(root, visualizer)
        print("[DEBUG] GUI created, starting mainloop...")
        root.mainloop()
        print("[DEBUG] Mainloop ended")
    except Exception as e:
        print("ERROR: {}".format(str(e)))
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        print("[DEBUG] ===== SCHEDULE VISUALIZER ENDED =====")


if __name__ == "__main__":
    main()

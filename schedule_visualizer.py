#!/usr/bin/env python3
"""
Schedule Visualizer for INSAT Campus Scheduling System
Provides GUI and terminal-based visualization of generated schedules
"""

import subprocess
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional
import tkinter as tk
from tkinter import ttk, messagebox
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
        Parse Prolog output containing assignments
        Format: assign(course_id, group_id, room_id, slot(day, slot_num))
        """
        assignments = []
        
        # Find all assign(...) terms
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
            cmd = [
                'swipl', '-q', '-f', str(self.main_pl),
                '-t', 'generate_schedule(S), format("~w", [S]), halt'
            ]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=str(self.project_root)
            )
            
            if result.returncode != 0:
                return None
            
            return ScheduleParser.parse_assignments(result.stdout)
        except Exception as e:
            print(f"Error generating schedule: {e}")
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
        self.assignments = assignments
        self.days_order = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
    
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
        self.root = root
        self.visualizer = visualizer
        self.root.title("Campus Schedule Visualizer")
        self.root.geometry("1200x700")
        
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the GUI elements"""
        # Top frame with buttons
        top_frame = ttk.Frame(self.root)
        top_frame.pack(side=tk.TOP, fill=tk.X, padx=10, pady=10)
        
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
        self._show_summary()
    
    def _show_text(self, text: str):
        """Display text in the text widget"""
        self.text_widget.config(state=tk.NORMAL)
        self.text_widget.delete(1.0, tk.END)
        self.text_widget.insert(1.0, text)
        self.text_widget.config(state=tk.DISABLED)
    
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
    try:
        project_root = Path(__file__).parent
        
        print("Connecting to Prolog system...")
        prolog = PrologInterface(project_root)
        
        print("Generating schedule...")
        assignments = prolog.generate_schedule()
        
        if not assignments:
            print("FAILED: Could not generate schedule")
            sys.exit(1)
        
        print("SUCCESS: Generated schedule with {} assignments".format(len(assignments)))
        print("Launching GUI...")
        
        visualizer = ScheduleVisualizer(assignments)
        
        # Launch GUI
        root = tk.Tk()
        gui = ScheduleGUI(root, visualizer)
        root.mainloop()
    except Exception as e:
        print("ERROR: {}".format(str(e)))
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

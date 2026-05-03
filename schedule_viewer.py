#!/usr/bin/env python3
"""
Simple terminal-based schedule viewer
Display generated schedules in the terminal with table formatting
"""

import subprocess
import sys
import os
from pathlib import Path
from typing import List, Dict, Optional
import re
from dataclasses import dataclass


DEFAULT_PROLOG_TIMEOUT = 120


def get_prolog_timeout() -> int:
    """Return the Prolog subprocess timeout in seconds."""
    raw_timeout = os.environ.get("SCHED_TIMEOUT", str(DEFAULT_PROLOG_TIMEOUT))
    try:
        timeout = int(raw_timeout)
    except ValueError:
        timeout = DEFAULT_PROLOG_TIMEOUT
    return max(1, timeout)


@dataclass
class Assignment:
    """Represents a schedule assignment"""
    course_id: str
    group_id: str
    room_id: str
    day: str
    slot: int


class ScheduleParser:
    """Parse Prolog assignment output"""
    
    @staticmethod
    def parse_assignments(prolog_output: str) -> List[Assignment]:
        """Parse Prolog output into Assignment objects
        
        Tries to parse two formats:
        1. Pipe-separated table format from display_schedule output:
           course_id | group_id | room_id | day slot number
        2. Prolog assign/4 format: assign(course, group, room, slot(day, num))
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


class TerminalScheduleViewer:
    """Terminal-based schedule visualization"""
    
    DAYS_ORDER = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.assignments: List[Assignment] = []
    
    def generate_schedule(self) -> bool:
        """Generate schedule from Prolog using the raw assign/4 output"""
        try:
            timeout = get_prolog_timeout()
            # Query raw assign/4 terms instead of parsing run_scheduler/0's
            # human-readable table output.
            cmd = [
                'swipl', '-q', '-s', str(self.project_root / "main.pl"),
                '-g', 'generate_schedule(S), write(S), halt.'
            ]
            
            result = subprocess.run(
                cmd, capture_output=True, text=True,
                timeout=timeout, cwd=str(self.project_root)
            )
            
            if result.returncode != 0:
                print("\nDEBUG: Prolog error detected")
                print("Return code: {}".format(result.returncode))
                if result.stderr:
                    print("STDERR: {}".format(result.stderr[:300]))
                if result.stdout:
                    print("STDOUT: {}".format(result.stdout[:300]))
                return False
            
            if not result.stdout.strip():
                print("\nDEBUG: Prolog returned empty output")
                return False
            
            self.assignments = ScheduleParser.parse_assignments(result.stdout)
            return len(self.assignments) > 0
        except subprocess.TimeoutExpired:
            print("ERROR: Prolog timeout (>{} seconds)".format(get_prolog_timeout()))
            print("Hint: full_campus can take longer; try setting SCHED_TIMEOUT=180.")
            return False
        except Exception as e:
            print("ERROR: {}".format(e))
            return False
    
    def print_summary(self):
        """Print schedule summary"""
        by_room = self._group_by_room()
        by_group = self._group_by_group()
        by_day = self._group_by_day()
        
        print("\n" + "=" * 80)
        print("SCHEDULE SUMMARY".center(80))
        print("=" * 80)
        print(f"Total assignments:      {len(self.assignments)}")
        print(f"Rooms in use:           {len(by_room)}")
        print(f"Groups scheduled:       {len(by_group)}")
        print(f"Days in use:            {sum(1 for d in by_day if by_day[d])}/6")
        print()
    
    def print_by_room(self):
        """Print schedule organized by room"""
        by_room = self._group_by_room()
        
        print("\n" + "=" * 100)
        print("SCHEDULE BY ROOM".center(100))
        print("=" * 100)
        
        for room in sorted(by_room.keys()):
            print(f"\nROOM: {room.upper()}")
            print("─" * 100)
            print(f"{'Day':<12} {'Slot':<6} {'Course':<35} {'Group':<15}")
            print("─" * 100)
            
            for assign in by_room[room]:
                print(f"{assign.day:<12} {assign.slot:<6} {assign.course_id:<35} {assign.group_id:<15}")
    
    def print_by_group(self):
        """Print schedule organized by group"""
        by_group = self._group_by_group()
        
        print("\n" + "=" * 100)
        print("SCHEDULE BY GROUP".center(100))
        print("=" * 100)
        
        for group in sorted(by_group.keys()):
            print(f"\nGROUP: {group.upper()}")
            print("─" * 100)
            print(f"{'Day':<12} {'Slot':<6} {'Course':<35} {'Room':<15}")
            print("─" * 100)
            
            for assign in by_group[group]:
                print(f"{assign.day:<12} {assign.slot:<6} {assign.course_id:<35} {assign.room_id:<15}")
    
    def print_by_day(self):
        """Print schedule organized by day"""
        by_day = self._group_by_day()
        
        print("\n" + "=" * 100)
        print("SCHEDULE BY DAY".center(100))
        print("=" * 100)
        
        for day in self.DAYS_ORDER:
            if by_day[day]:
                print(f"\n{day.upper()}")
                print("─" * 100)
                print(f"{'Slot':<6} {'Course':<35} {'Group':<15} {'Room':<15}")
                print("─" * 100)
                
                for assign in by_day[day]:
                    print(f"{assign.slot:<6} {assign.course_id:<35} {assign.group_id:<15} {assign.room_id:<15}")
    
    def print_timetable_grid(self):
        """Print a simple grid timetable by day and slot"""
        by_day = self._group_by_day()
        
        print("\n" + "=" * 100)
        print("TIMETABLE GRID (by Day and Slot)".center(100))
        print("=" * 100)
        
        # Get max slot
        max_slot = max(a.slot for a in self.assignments) if self.assignments else 0
        
        for day in self.DAYS_ORDER:
            if by_day[day]:
                print(f"\n{day.upper()}")
                print("─" * 100)
                
                # Create slot-based view
                slots = {}
                for assign in by_day[day]:
                    if assign.slot not in slots:
                        slots[assign.slot] = []
                    slots[assign.slot].append(assign)
                
                for slot_num in sorted(slots.keys()):
                    print(f"\n  Slot {slot_num}:")
                    for assign in slots[slot_num]:
                        print(f"    - {assign.course_id:<30} ({assign.group_id}) > {assign.room_id}")
    def _group_by_room(self) -> Dict[str, List[Assignment]]:
        """Group assignments by room"""
        result = {}
        for assign in self.assignments:
            if assign.room_id not in result:
                result[assign.room_id] = []
            result[assign.room_id].append(assign)
        
        for room in result:
            result[room].sort(key=lambda a: (
                self.DAYS_ORDER.index(a.day) if a.day in self.DAYS_ORDER else 999,
                a.slot
            ))
        
        return result
    
    def _group_by_group(self) -> Dict[str, List[Assignment]]:
        """Group assignments by group"""
        result = {}
        for assign in self.assignments:
            if assign.group_id not in result:
                result[assign.group_id] = []
            result[assign.group_id].append(assign)
        
        for group in result:
            result[group].sort(key=lambda a: (
                self.DAYS_ORDER.index(a.day) if a.day in self.DAYS_ORDER else 999,
                a.slot
            ))
        
        return result
    
    def _group_by_day(self) -> Dict[str, List[Assignment]]:
        """Group assignments by day"""
        result = {day: [] for day in self.DAYS_ORDER}
        
        for assign in self.assignments:
            if assign.day in result:
                result[assign.day].append(assign)
        
        for day in result:
            result[day].sort(key=lambda a: a.slot)
        
        return result


def print_menu():
    """Print interactive menu"""
    print("\n" + "=" * 80)
    print("SCHEDULE VIEWER - SELECT VIEW".center(80))
    print("=" * 80)
    print("1. Summary")
    print("2. By Room")
    print("3. By Group")
    print("4. By Day")
    print("5. Timetable Grid")
    print("6. All Views")
    print("0. Exit")
    print("=" * 80)


def main():
    project_root = Path(__file__).parent
    
    if len(sys.argv) > 1 and sys.argv[1] == '--gui':
        print("Launching FastAPI schedule visualizer...")
        from schedule_visualizer import main as run_web_visualizer

        run_web_visualizer()
        return
    
    # Terminal mode
    viewer = TerminalScheduleViewer(project_root)
    
    print("Connecting to Prolog system...")
    print("Generating schedule...")
    
    if not viewer.generate_schedule():
        print("\nFAILED: Could not generate schedule")
        print("\nDEBUG: Check that:")
        print("  1. SWI-Prolog is installed: run 'swipl --version'")
        print("  2. The main.pl file is not corrupted")
        print("  3. Run 'python test_scheduler.py' to test Prolog system")
        sys.exit(1)
    
    print("SUCCESS: Generated schedule with {} assignments\n".format(len(viewer.assignments)))
    
    # Interactive menu
    while True:
        print_menu()
        choice = input("Enter choice (0-6): ").strip()
        
        if choice == "0":
            print("Goodbye!")
            break
        elif choice == "1":
            viewer.print_summary()
        elif choice == "2":
            viewer.print_by_room()
        elif choice == "3":
            viewer.print_by_group()
        elif choice == "4":
            viewer.print_by_day()
        elif choice == "5":
            viewer.print_timetable_grid()
        elif choice == "6":
            viewer.print_summary()
            viewer.print_by_room()
            viewer.print_by_group()
            viewer.print_by_day()
            viewer.print_timetable_grid()
        else:
            print("INVALID: Invalid choice")


if __name__ == "__main__":
    main()

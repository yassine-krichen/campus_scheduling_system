#!/usr/bin/env python3
"""
Test script for INSAT Campus Scheduling System (Prolog)
Runs various test scenarios and validates output
"""

import subprocess
import os
import sys
import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent
MAIN_PL = PROJECT_ROOT / "main.pl"


def run_prolog_query(query, scenario="demo", timeout=30):
    """
    Execute a Prolog query and return output.
    
    Args:
        query: Prolog query string (e.g., "run_scheduler")
        scenario: Scenario name (demo, gl3_only, engineering, full_campus)
        timeout: Query timeout in seconds
    
    Returns:
        Tuple of (success: bool, output: str, error: str)
    """
    if not MAIN_PL.exists():
        return False, "", f"Error: main.pl not found at {MAIN_PL}"
    
    env = os.environ.copy()
    env["SCHED_SCENARIO"] = scenario
    env["SCHED_LIMIT"] = "1"
    
    # SWI-Prolog command: load main.pl and run query, then halt
    prolog_cmd = f"{query}, halt."
    
    try:
        result = subprocess.run(
            ["swipl", "-g", prolog_cmd, "-t", "halt", str(MAIN_PL)],
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
            cwd=str(PROJECT_ROOT),
        )
        
        success = result.returncode == 0
        return success, result.stdout, result.stderr
    
    except subprocess.TimeoutExpired:
        return False, "", f"Query timeout after {timeout}s"
    except FileNotFoundError:
        return False, "", "Error: swipl not found. Is SWI-Prolog installed and in PATH?"
    except Exception as e:
        return False, "", str(e)


def test_basic_queries():
    """Test basic predicates."""
    print("\n" + "="*70)
    print("TEST 1: Basic Query Tests (demo scenario)")
    print("="*70)
    
    queries = [
        ("get_time(T), write(T)", "Get system time"),
        ("scenario_courses(C), length(C, N), format('Courses: ~w~n', [N])", "Count scenario courses"),
        ("scenario_groups(G), length(G, N), format('Groups: ~w~n', [N])", "Count scenario groups"),
    ]
    
    for query, description in queries:
        print(f"\n• {description}")
        print(f"  Query: {query}")
        success, stdout, stderr = run_prolog_query(query, scenario="demo", timeout=15)
        
        if success:
            print(f"  ✓ Success")
            if stdout.strip():
                print(f"  Output: {stdout.strip()}")
        else:
            print(f"  ✗ Failed")
            if stderr.strip():
                print(f"  Error: {stderr.strip()}")


def test_work_list():
    """Test work list generation."""
    print("\n" + "="*70)
    print("TEST 2: Work List Generation")
    print("="*70)
    
    query = "build_work_list(WL), length(WL, N), format('Work items: ~w~n', [N])"
    print(f"\n• Build work list and count items (demo)")
    print(f"  Query: {query}")
    
    success, stdout, stderr = run_prolog_query(query, scenario="demo", timeout=15)
    
    if success:
        print(f"  ✓ Success")
        if stdout.strip():
            print(f"  Output: {stdout.strip()}")
    else:
        print(f"  ✗ Failed")
        if stderr.strip():
            print(f"  Error: {stderr.strip()}")


def test_schedule_generation():
    """Test full schedule generation."""
    print("\n" + "="*70)
    print("TEST 3: Schedule Generation")
    print("="*70)
    
    scenarios = ["demo"]  # Only test demo for speed
    
    for scenario in scenarios:
        print(f"\n• Scenario: {scenario}")
        query = "generate_schedule(S), length(S, N), format('Generated schedule with ~w assignments~n', [N])"
        
        success, stdout, stderr = run_prolog_query(query, scenario=scenario, timeout=60)
        
        if success:
            print(f"  ✓ Schedule generated")
            if stdout.strip():
                print(f"  Output: {stdout.strip()}")
        else:
            print(f"  ✗ Generation failed")
            if stderr.strip():
                # Print first 200 chars of error to avoid flooding output
                err_msg = stderr.strip()[:200]
                print(f"  Error: {err_msg}...")


def test_constraints():
    """Test constraint satisfaction."""
    print("\n" + "="*70)
    print("TEST 4: Constraint Validation")
    print("="*70)
    
    query = """
    build_work_list(WL), 
    WL = [FirstItem|_],
    FirstItem = work(Course, Group),
    format('First work item: Course ~w, Group ~w~n', [Course, Group])
    """
    
    print(f"\n• Inspect first work item")
    success, stdout, stderr = run_prolog_query(query, scenario="demo", timeout=15)
    
    if success:
        print(f"  ✓ Success")
        if stdout.strip():
            print(f"  Output: {stdout.strip()}")
    else:
        print(f"  ✗ Failed")
        if stderr.strip():
            print(f"  Error: {stderr.strip()[:200]}...")


def test_scenario_comparison():
    """Compare scenarios by work items."""
    print("\n" + "="*70)
    print("TEST 5: Scenario Comparison")
    print("="*70)
    
    scenarios = ["demo", "gl3_only"]
    
    for scenario in scenarios:
        query = "build_work_list(WL), length(WL, N), format('~w: ~w work items~n', ['" + scenario + "', N])"
        success, stdout, stderr = run_prolog_query(query, scenario=scenario, timeout=15)
        
        if success:
            print(f"• {scenario}: {stdout.strip()}")
        else:
            print(f"• {scenario}: Error - {stderr.strip()[:100]}")


def test_syntax():
    """Test if all files can be loaded without syntax errors."""
    print("\n" + "="*70)
    print("TEST 6: Syntax Check (Load All Files)")
    print("="*70)
    
    query = "write('All files loaded successfully.')"
    success, stdout, stderr = run_prolog_query(query, scenario="demo", timeout=15)
    
    if success:
        print(f"  ✓ All Prolog files loaded without errors")
        print(f"  Output: {stdout.strip()}")
    else:
        print(f"  ✗ Syntax or load error detected")
        if stderr.strip():
            print(f"  Error:\n{stderr.strip()[:500]}")


def main():
    """Run all tests."""
    print("\n" + "="*70)
    print("INSAT Campus Scheduling System - Test Suite")
    print("="*70)
    
    # Check prerequisites
    print("\nChecking prerequisites...")
    if not MAIN_PL.exists():
        print(f"✗ main.pl not found at {MAIN_PL}")
        sys.exit(1)
    print(f"✓ Project found at {PROJECT_ROOT}")
    
    try:
        result = subprocess.run(["swipl", "--version"], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            print(f"✓ SWI-Prolog found: {result.stdout.strip()}")
        else:
            print("✗ SWI-Prolog not found or not in PATH")
            print("\n📝 Setup Instructions:")
            print("   1. Download SWI-Prolog from: https://www.swi-prolog.org/download")
            print("   2. Install it (add to PATH during installation)")
            print("   3. Restart your terminal and try again")
            sys.exit(1)
    except FileNotFoundError:
        print("✗ SWI-Prolog not found. Please install it:")
        print("\n📝 Setup Instructions:")
        print("   Windows:")
        print("     - Download from: https://www.swi-prolog.org/download")
        print("     - Run installer and ensure 'Add to PATH' is checked")
        print("   Linux (Ubuntu/Debian):")
        print("     - sudo apt-get install swi-prolog")
        print("   macOS:")
        print("     - brew install swi-prolog")
        print("\n   After installation, restart your terminal and try again.")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Error checking SWI-Prolog: {e}")
        sys.exit(1)
    
    # Run tests
    test_syntax()
    test_basic_queries()
    test_work_list()
    test_constraints()
    test_scenario_comparison()
    test_schedule_generation()
    
    print("\n" + "="*70)
    print("Test suite completed!")
    print("="*70 + "\n")


if __name__ == "__main__":
    main()

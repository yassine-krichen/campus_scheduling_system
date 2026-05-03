@echo off
REM Campus Schedule Visualizer - GUI Launcher for Windows
REM This script launches the GUI schedule visualizer properly on Windows

cd /d "%~dp0"

echo Launching Campus Schedule Visualizer...
echo.

python schedule_visualizer.py

pause

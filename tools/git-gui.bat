@echo off
REM Double-click this to launch the Git Control Panel GUI.
REM Bypasses PowerShell's execution-policy prompt for just this one script
REM run -- doesn't change any system-wide policy.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0git-gui.ps1"

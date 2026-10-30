@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync_date_tester.ps1" %*

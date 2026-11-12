@echo off
start "Servidor do site" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor-site.ps1"

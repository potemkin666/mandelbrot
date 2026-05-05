@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "STATE_DIR=%CD%\.launcher"
set "PID_FILE=%STATE_DIR%\mandel.pid"
set "MODE_FILE=%STATE_DIR%\mode.txt"
set "LOG_FILE=%STATE_DIR%\mandel.log"

if not exist "%MODE_FILE%" if not exist "%PID_FILE%" (
  echo Nothing looks active right now.
  exit /b 0
)

set "MODE="
if exist "%MODE_FILE%" set /p MODE=<"%MODE_FILE%"

if /I "%MODE%"=="docker" (
  echo Stopping Docker containers for this project...
  docker compose down
  if errorlevel 1 (
    echo Docker Compose reported a problem while stopping.
  ) else (
    echo Docker services stopped.
  )
  goto :cleanup
)

if not exist "%PID_FILE%" (
  echo No saved Mandel process id was found.
  goto :cleanup
)

set /p PID=<"%PID_FILE%"
echo Stopping Mandel process tree rooted at PID %PID% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$root=%PID%; function Stop-Tree([int]$id){ $children = Get-CimInstance Win32_Process -Filter \"ParentProcessId=$id\" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessId; foreach($child in $children){ Stop-Tree $child }; $proc = Get-Process -Id $id -ErrorAction SilentlyContinue; if($proc){ Stop-Process -Id $id -Force; Write-Output ('Stopped PID ' + $id) } }; Stop-Tree $root"
if errorlevel 1 (
  echo Mandel could not confirm that the saved process was still running.
) else (
  echo Mandel has been stopped.
)

:cleanup
if exist "%PID_FILE%" del "%PID_FILE%" >nul 2>nul
if exist "%MODE_FILE%" del "%MODE_FILE%" >nul 2>nul
if exist "%STATE_DIR%\url.txt" del "%STATE_DIR%\url.txt" >nul 2>nul
echo Launcher state cleaned up.
if exist "%LOG_FILE%" echo Last log file kept at %LOG_FILE%

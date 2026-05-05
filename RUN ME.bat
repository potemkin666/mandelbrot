@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%CD%"
set "STATE_DIR=%ROOT%\.launcher"
set "LOG_FILE=%STATE_DIR%\mandel.log"
set "PID_FILE=%STATE_DIR%\mandel.pid"
set "MODE_FILE=%STATE_DIR%\mode.txt"
set "URL_FILE=%STATE_DIR%\url.txt"
set "DEFAULT_PORT=3000"
set "HOST=127.0.0.1"

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>nul

echo.
echo ==============================================================
echo   MANDEL // SIGNAL AQUARIUM

echo   Local-first launch shell

echo ==============================================================
echo.

call :cleanup_stale
if errorlevel 1 exit /b 0

set "HAS_DOCKER=0"
set "HAS_NODE=0"
set "HAS_PYTHON=0"
set "HAS_VITE=0"
set "HAS_NEXT=0"
set "HAS_TAURI=0"
set "HAS_ELECTRON=0"
set "HAS_PYPROJECT=0"
set "HAS_REQUIREMENTS=0"
set "HAS_PY_ENTRY=0"

if exist "docker-compose.yml" set "HAS_DOCKER=1"
if exist "compose.yaml" set "HAS_DOCKER=1"
if exist "package.json" set "HAS_NODE=1"
if exist "vite.config.ts" set "HAS_VITE=1"
if exist "vite.config.js" set "HAS_VITE=1"
if exist "vite.config.mts" set "HAS_VITE=1"
if exist "vite.config.mjs" set "HAS_VITE=1"
if exist "next.config.js" set "HAS_NEXT=1"
if exist "next.config.mjs" set "HAS_NEXT=1"
if exist "pyproject.toml" set "HAS_PYPROJECT=1"
if exist "requirements.txt" set "HAS_REQUIREMENTS=1"
if exist "app.py" set "HAS_PY_ENTRY=1"
if exist "main.py" set "HAS_PY_ENTRY=1"
if exist "src-tauri\tauri.conf.json" set "HAS_TAURI=1"
if exist "electron-builder.json" set "HAS_ELECTRON=1"
if exist "electron\package.json" set "HAS_ELECTRON=1"

echo [1/6] Looking around the folder...
if "%HAS_NODE%"=="1" echo   - package.json found
if "%HAS_VITE%"=="1" echo   - Vite app detected
if "%HAS_DOCKER%"=="1" echo   - Docker Compose files found
if "%HAS_TAURI%"=="1" echo   - Tauri desktop files found
if "%HAS_PYPROJECT%"=="1" echo   - pyproject.toml found
if "%HAS_REQUIREMENTS%"=="1" echo   - requirements.txt found

set "MODE="
if "%HAS_NODE%"=="1" if "%HAS_VITE%"=="1" set "MODE=node-vite"
if not defined MODE if "%HAS_NODE%"=="1" if "%HAS_NEXT%"=="1" set "MODE=node-next"
if not defined MODE if "%HAS_PYPROJECT%"=="1" set "MODE=python"
if not defined MODE if "%HAS_REQUIREMENTS%"=="1" set "MODE=python"
if not defined MODE if "%HAS_DOCKER%"=="1" set "MODE=docker"

if not defined MODE (
  echo.
  echo I could not figure out the safest launch path for this folder.
  echo Read README-FIRST.txt, then TROUBLESHOOTING.txt if you get stuck.
  goto :error_pause
)

if /I "%MODE%"=="node-vite" goto :launch_node_vite
if /I "%MODE%"=="node-next" goto :launch_node_next
if /I "%MODE%"=="python" goto :launch_python
if /I "%MODE%"=="docker" goto :launch_docker

echo.
echo This launcher found "%MODE%", but does not know how to start it yet.
goto :error_pause

:launch_node_vite
echo [2/6] Choosing the native Node + Vite route.
call :require_command node "Node.js is required for this app."
if errorlevel 1 goto :missing_dependency
call :require_command npm "Node.js is installed, but npm is missing."
if errorlevel 1 goto :missing_dependency
call :pick_port %DEFAULT_PORT%
set "URL=http://%HOST%:%PORT%"
echo %URL%>"%URL_FILE%"
if not "%PORT%"=="%DEFAULT_PORT%" echo   - Port %DEFAULT_PORT% was busy, so Mandel picked %PORT% instead.
if not exist "node_modules" (
  echo [3/6] Installing local dependencies for this folder...
  if exist package-lock.json (
    call npm ci
  ) else (
    call npm install
  )
  if errorlevel 1 (
    echo.
    echo Mandel could not finish installing its local packages.
    echo Please check your internet connection, then try RUN ME again.
    goto :error_pause
  )
) else (
  echo [3/6] Local dependencies already exist. Nice.
)

echo [4/6] Starting Mandel on %URL% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:WM_HOST='%HOST%'; $env:WM_PORT='%PORT%'; $env:WM_AUTO_OPEN_BROWSER='false'; $env:BROWSER='none'; $log='%LOG_FILE%'; $pid='%PID_FILE%'; $mode='%MODE_FILE%'; $cmd='npm run dev'; $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmd + ' > \"' + $log + '\" 2>&1' -WorkingDirectory '%ROOT%' -PassThru; Set-Content -Path $pid -Value $proc.Id; Set-Content -Path $mode -Value 'node-vite';"
if errorlevel 1 (
  echo.
  echo Mandel could not start its local Node process.
  goto :error_pause
)
goto :wait_for_url

:launch_node_next
echo [2/6] This folder looks like a Node app, but not the Vite flavor this launcher knows best.
echo Please see TROUBLESHOOTING.txt for the closest manual path.
goto :error_pause

:launch_python
echo [2/6] Python app detected.
call :require_command python "Python is required for this app."
if errorlevel 1 goto :missing_dependency
call :pick_port 8000
set "URL=http://%HOST%:%PORT%"
echo %URL%>"%URL_FILE%"
if not exist ".venv\Scripts\python.exe" (
  echo [3/6] Creating a local Python environment...
  python -m venv .venv
  if errorlevel 1 (
    echo.
    echo Mandel could not create the local .venv folder.
    goto :error_pause
  )
)
if exist "requirements.txt" (
  echo [4/6] Installing local Python packages...
  call ".venv\Scripts\python.exe" -m pip install -r requirements.txt
  if errorlevel 1 (
    echo.
    echo Mandel could not install the required Python packages.
    goto :error_pause
  )
)
if exist "app.py" (
  set "PY_ENTRY=app.py"
) else if exist "main.py" (
  set "PY_ENTRY=main.py"
) else (
  echo.
  echo Python was detected, but no app.py or main.py entry file was found.
  goto :error_pause
)
echo [5/6] Starting Mandel on %URL% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:HOST='%HOST%'; $env:PORT='%PORT%'; $log='%LOG_FILE%'; $pid='%PID_FILE%'; $mode='%MODE_FILE%'; $cmd='.venv\\Scripts\\python.exe %PY_ENTRY%'; $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', $cmd + ' > \"' + $log + '\" 2>&1' -WorkingDirectory '%ROOT%' -PassThru; Set-Content -Path $pid -Value $proc.Id; Set-Content -Path $mode -Value 'python';"
if errorlevel 1 goto :error_pause
goto :wait_for_url

:launch_docker
echo [2/6] Falling back to Docker Compose.
call :require_command docker "Docker Desktop is required for this app."
if errorlevel 1 goto :missing_docker

docker info >nul 2>nul
if errorlevel 1 (
  echo.
  echo Docker Desktop is required for this app.
  echo Install it, open Docker Desktop, then double-click RUN ME.bat again.
  goto :error_pause
)

call :pick_port %DEFAULT_PORT%
set "URL=http://%HOST%:%PORT%"
echo %URL%>"%URL_FILE%"
set "WM_PORT=%PORT%"
echo [3/6] Building and starting the local containers...
docker compose up -d --build
if errorlevel 1 (
  echo.
  echo Docker Compose did not start cleanly.
  echo Please read TROUBLESHOOTING.txt for the plain-English rescue steps.
  goto :error_pause
)
echo docker>"%MODE_FILE%"
goto :wait_for_url

:wait_for_url
echo [5/6] Waiting for Mandel to answer on %URL% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$url='%URL%'; $deadline=(Get-Date).AddMinutes(4); while((Get-Date) -lt $deadline){ try { $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3; if($response.StatusCode -ge 200 -and $response.StatusCode -lt 500){ exit 0 } } catch { Start-Sleep -Seconds 2 } }; exit 1"
if errorlevel 1 (
  echo.
  echo Mandel has not answered yet.
  echo - Expected local address: %URL%
  echo - Full log file: %LOG_FILE%
  if exist "%LOG_FILE%" (
    echo.
    echo --- Last lines from the log ---
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Path '%LOG_FILE%' -Tail 40"
  )
  goto :error_pause
)

echo [6/6] Opening your browser...
start "" "%URL%"
echo.
echo Mandel is live at %URL%
echo Use STOP.bat when you want the local shell to go quiet.
echo.
exit /b 0

:cleanup_stale
if not exist "%PID_FILE%" exit /b 0
for /f %%I in (%PID_FILE%) do set "OLDPID=%%I"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process -Id %OLDPID% -ErrorAction SilentlyContinue) { exit 1 }"
if errorlevel 1 (
  echo A Mandel process already seems to be running.
  if exist "%URL_FILE%" (
    set /p EXISTING_URL=<"%URL_FILE%"
    echo Opening !EXISTING_URL! instead of starting a duplicate.
    start "" "!EXISTING_URL!"
    exit /b 1
  )
  echo Use STOP.bat first if you want a clean restart.
  goto :error_pause
)
del "%PID_FILE%" >nul 2>nul
exit /b 0

:pick_port
set "PORT=%~1"
for /f %%P in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$start=[int]%~1; function Test-Port([int]$port){ try { $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse('127.0.0.1'), $port); $listener.Start(); $listener.Stop(); return $true } catch { return $false } }; $port=$start; while(-not (Test-Port $port)){ $port++ }; Write-Output $port"') do set "PORT=%%P"
exit /b 0

:require_command
where %~1 >nul 2>nul
if errorlevel 1 (
  echo.
  echo %~2
  exit /b 1
)
exit /b 0

:missing_dependency
echo Install the missing tool, then double-click RUN ME.bat again.
goto :error_pause

:missing_docker
echo Docker Desktop is required for this app.
echo Install it, open Docker Desktop, then double-click RUN ME.bat again.
goto :error_pause

:error_pause
echo.
echo Mandel is staying open so you can read what happened.
pause
exit /b 1

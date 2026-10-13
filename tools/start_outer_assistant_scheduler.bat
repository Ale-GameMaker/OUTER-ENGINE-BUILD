@echo off
setlocal
cd /d "%~dp0\.."
where py >nul 2>nul
if %errorlevel%==0 (
    py -3 "%~dp0outer_assistant_scheduler.py"
) else (
    python "%~dp0outer_assistant_scheduler.py"
)
if errorlevel 1 (
    echo.
    echo Scheduler exited with an error. Check Python and the JSON config.
    pause
)
endlocal

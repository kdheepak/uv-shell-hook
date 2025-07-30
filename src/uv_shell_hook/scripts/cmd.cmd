@echo off
setlocal enabledelayedexpansion

REM --- Main entry point ---
set "CMD=%1"
shift

if /I "%CMD%"=="activate" goto activate
if /I "%CMD%"=="deactivate" goto deactivate

REM Unknown command: pass through to uv executable if exists
if "%CMD%"=="" goto usage
uv %CMD% %*
exit /b %ERRORLEVEL%

:usage
echo Usage: uv activate [path]
echo        uv deactivate
exit /b 1

:activate
REM Set input path or current directory
if "%~1"=="" (
    set "input_path=%cd%"
) else (
    set "input_path=%~1"
)

REM Remove trailing backslash if exists
if "!input_path:~-1!"=="\" set "input_path=!input_path:~0,-1!"

call :find_venv_path "!input_path!"

if not defined venv_path (
    call :print_venv_not_found "!input_path!"
    exit /b 1
)

if exist "!activate_script!" (
    call "!activate_script!"
    if errorlevel 1 (
        echo Error: Failed to activate virtual environment
        exit /b 1
    )
    echo Activated: !venv_path!
    exit /b 0
) else (
    echo Error: Activation script not found: !activate_script!
    exit /b 1
)

:deactivate
if not defined VIRTUAL_ENV (
    echo Error: No virtual environment is active
    exit /b 1
)

REM Check if deactivate.bat exists in Scripts folder
set "deactivate_script=%VIRTUAL_ENV%\Scripts\deactivate.bat"
if exist "!deactivate_script!" (
    set "old_virtual_env=%VIRTUAL_ENV%"
    call "!deactivate_script!"
    if errorlevel 1 (
        echo Error: Failed to deactivate virtual environment
        exit /b 1
    )
    echo Deactivated: !old_virtual_env!
    exit /b 0
) else (
    echo Error: deactivate function not available in this session
    exit /b 1
)

:find_venv_path
set "input=%~1"
set "venv_path="
set "activate_script="

REM Determine virtualenvs_folder
if defined WORKON_HOME (
    set "virtualenvs_folder=%WORKON_HOME%"
) else (
    set "virtualenvs_folder=%USERPROFILE%\.virtualenvs"
)

REM Check possible locations in order of preference

REM 1. Check input_path/.venv/Scripts/activate.bat
if exist "%input%\.venv\Scripts\activate.bat" (
    set "venv_path=%input%\.venv"
    set "activate_script=%input%\.venv\Scripts\activate.bat"
    goto :eof
)

REM 2. Check input_path/.venv/Scripts/activate (Unix-style)
if exist "%input%\.venv\Scripts\activate" (
    set "venv_path=%input%\.venv"
    set "activate_script=%input%\.venv\Scripts\activate"
    goto :eof
)

REM 3. Check if input_path itself is a venv (ends with .venv or has Scripts/activate.bat)
if exist "%input%\Scripts\activate.bat" (
    set "venv_path=%input%"
    set "activate_script=%input%\Scripts\activate.bat"
    goto :eof
)

REM 4. Check if input_path itself is a venv (Unix-style activate)
if exist "%input%\Scripts\activate" (
    set "venv_path=%input%"
    set "activate_script=%input%\Scripts\activate"
    goto :eof
)

REM 5. Check WORKON_HOME/input_path/.venv/Scripts/activate.bat
if exist "%virtualenvs_folder%\%input%\.venv\Scripts\activate.bat" (
    set "venv_path=%virtualenvs_folder%\%input%\.venv"
    set "activate_script=%virtualenvs_folder%\%input%\.venv\Scripts\activate.bat"
    goto :eof
)

REM 6. Check WORKON_HOME/input_path/Scripts/activate.bat
if exist "%virtualenvs_folder%\%input%\Scripts\activate.bat" (
    set "venv_path=%virtualenvs_folder%\%input%"
    set "activate_script=%virtualenvs_folder%\%input%\Scripts\activate.bat"
    goto :eof
)

REM 7. Check WORKON_HOME/input_path/Scripts/activate (Unix-style)
if exist "%virtualenvs_folder%\%input%\Scripts\activate" (
    set "venv_path=%virtualenvs_folder%\%input%"
    set "activate_script=%virtualenvs_folder%\%input%\Scripts\activate"
    goto :eof
)

REM No venv found - variables remain empty
goto :eof

:print_venv_not_found
set "input=%~1"

if defined WORKON_HOME (
    set "virtualenvs_folder=%WORKON_HOME%"
) else (
    set "virtualenvs_folder=%USERPROFILE%\.virtualenvs"
)

echo Error: Virtual environment not found at "%input%"
echo.
echo Locations checked:
echo   %input%\.venv\
echo   %input%\
echo   %virtualenvs_folder%\%input%\.venv\
echo   %virtualenvs_folder%\%input%\
echo.
echo You can create a virtual environment using:
echo   uv venv .venv
goto :eof

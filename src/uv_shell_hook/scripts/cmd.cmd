@echo off
setlocal enabledelayedexpansion

REM --- Main entry point ---
set CMD=%1
shift

if /I "%CMD%"=="activate" goto activate
if /I "%CMD%"=="deactivate" goto deactivate

REM Unknown command: pass through to uv executable if exists
if "%CMD%"=="" goto usage
uv %CMD% %*
exit /b 0

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
if "%input_path:~-1%"=="\" set "input_path=%input_path:~0,-1%"

call :find_venv_path "%input_path%"
if not defined venv_path (
    call :print_venv_not_found "%input_path%"
    exit /b 1
)

if exist "%activate_script%" (
    call "%activate_script%"
    if errorlevel 1 (
        echo Error: Failed to activate virtual environment
        exit /b 1
    )
    echo Activated virtual environment: %venv_path%
    exit /b 0
) else (
    echo Error: Activation script not found: %activate_script%
    exit /b 1
)


:deactivate
if not defined VIRTUAL_ENV (
    echo Warning: No virtual environment is active.
    exit /b 1
)

REM deactivate usually defined in the activated environment session
REM Check if deactivate.bat exists in Scripts folder
if exist "%VIRTUAL_ENV%\Scripts\deactivate.bat" (
    call "%VIRTUAL_ENV%\Scripts\deactivate.bat"
    if errorlevel 1 (
        echo Error: Failed to deactivate virtual environment
        exit /b 1
    )
    echo Deactivated virtual environment: %VIRTUAL_ENV%
    exit /b 0
) else (
    echo Error: deactivate function not available in this session.
    exit /b 1
)

exit /b 0


:find_venv_path
setlocal
set "input=%~1"
set "venv_path="
set "activate_script="
set "virtualenvs_folder="

REM Determine virtualenvs_folder
if defined WORKON_HOME (
    set "virtualenvs_folder=%WORKON_HOME%"
) else (
    set "virtualenvs_folder=%USERPROFILE%\.virtualenvs"
)

REM Check possible locations
if exist "%input%\.venv\Scripts\activate.bat" (
    endlocal & set "venv_path=%input%\.venv"
    endlocal & set "activate_script=%venv_path%\Scripts\activate.bat"
    goto :eof
)
if exist "%input%\.venv\Scripts\activate" (
    endlocal & set "venv_path=%input%\.venv"
    endlocal & set "activate_script=%venv_path%\Scripts\activate"
    goto :eof
)
if exist "%input%\Scripts\activate.bat" (
    endlocal & set "venv_path=%input%"
    endlocal & set "activate_script=%venv_path%\Scripts\activate.bat"
    goto :eof
)
if exist "%input%\Scripts\activate" (
    endlocal & set "venv_path=%input%"
    endlocal & set "activate_script=%venv_path%\Scripts\activate"
    goto :eof
)
if exist "%virtualenvs_folder%\%input%\Scripts\activate.bat" (
    endlocal & set "venv_path=%virtualenvs_folder%\%input%"
    endlocal & set "activate_script=%venv_path%\Scripts\activate.bat"
    goto :eof
)
if exist "%virtualenvs_folder%\%input%\Scripts\activate" (
    endlocal & set "venv_path=%virtualenvs_folder%\%input%"
    endlocal & set "activate_script=%venv_path%\Scripts\activate"
    goto :eof
)

REM No venv found
endlocal & set "venv_path="
exit /b 0

:print_venv_not_found
setlocal
set "input=%~1"
if defined WORKON_HOME (
    set "virtualenvs_folder=%WORKON_HOME%"
) else (
    set "virtualenvs_folder=%USERPROFILE%\.virtualenvs"
)
echo Error: Virtual environment not found in "%input%"
echo Locations checked:
echo   %input%\.venv\
echo   %input%\
echo   %virtualenvs_folder%\%input%\
echo You can create a virtual environment using:
echo   python -m venv <name-of-env>
endlocal
exit /b 0

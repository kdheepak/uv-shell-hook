@echo off
setlocal enabledelayedexpansion

rem Normalize arguments
if "%~1"=="" goto run_uv
if /i "%~1"=="--help" goto run_uv
if /i "%~1"=="-h" goto run_uv
if /i "%~1"=="activate" goto activate
if /i "%~1"=="deactivate" goto deactivate
goto run_uv

:activate
set "input_path=%~2"
if "%input_path%"=="" set "input_path=."

rem Remove trailing backslash
if "%input_path:~-1%"=="\" set "input_path=%input_path:~0,-1%"

rem Set WORKON_HOME with default
set "workon_home=%WORKON_HOME%"
if "%workon_home%"=="" set "workon_home=%USERPROFILE%\.virtualenvs"

rem Search for venv
set "venv_path="
set "search_paths=%input_path%\.venv;%input_path%;%workon_home%\%input_path%\.venv;%workon_home%\%input_path%"

for %%p in (%search_paths:;= %) do (
    if exist "%%p\Scripts\activate.bat" (
        set "venv_path=%%p"
        goto found_venv
    )
)

:venv_not_found
echo [91m[1mError:[0m [91mVirtual environment not found[0m >&2
echo [2mSearched for:[0m [93m%input_path%[0m >&2
echo [2mLocations checked:[0m >&2
for %%p in (%search_paths:;= %) do echo   - %%p >&2
exit /b 1

:found_venv
set "activate_script=%venv_path%\Scripts\activate.bat"
call "%activate_script%"

if !errorlevel! equ 0 (
    echo [92m[1m✓[0m [92mActivated:[0m [96m%venv_path%[0m

    rem Show Python version
    where python >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "tokens=2" %%v in ('python --version 2^>^&1') do (
            echo [2m  Python %%v[0m
        )
    )
) else (
    echo [91m[1mError:[0m [91mFailed to activate virtual environment[0m >&2
    exit /b 1
)
goto end

:deactivate
if "%VIRTUAL_ENV%"=="" (
    echo [93m[1mWarning:[0m [93mNo virtual environment is active[0m >&2
    exit /b 1
)

set "old_venv=%VIRTUAL_ENV%"

if exist "%VIRTUAL_ENV%\Scripts\deactivate.bat" (
    call "%VIRTUAL_ENV%\Scripts\deactivate.bat"
) else (
    rem Manual deactivation
    set "VIRTUAL_ENV="
    set "PATH=!PATH:%VIRTUAL_ENV%\Scripts;=!"
)

echo [93m[1m✗[0m [93mDeactivated:[0m [96m%old_venv%[0m
goto end

:run_uv
uv.exe %*

:end
endlocal
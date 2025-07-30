function uv {
    param([Parameter(ValueFromRemainingArguments=$true)]$Args)

    # Enhanced color support with fallback
    if ($Host.UI.SupportsVirtualTerminal) {
        $RED = "`e[0;31m"
        $GREEN = "`e[0;32m"
        $YELLOW = "`e[0;33m"
        $CYAN = "`e[0;36m"
        $BOLD = "`e[1m"
        $DIM = "`e[2m"
        $NOCOLOR = "`e[0m"
    } else {
        # Fallback for older PowerShell versions
        $RED = ""
        $GREEN = ""
        $YELLOW = ""
        $CYAN = ""
        $BOLD = ""
        $DIM = ""
        $NOCOLOR = ""
    }

    if ($Args.Count -eq 0) {
        & uv.exe
        return
    }

    switch ($Args[0]) {
        "activate" {
            $inputPath = if ($Args.Count -gt 1) { $Args[1] } else { "." }
            $inputPath = $inputPath.TrimEnd('/', '\')
            $venvPath = $null
            $workonHome = if ($env:WORKON_HOME) { $env:WORKON_HOME } else { Join-Path $HOME ".virtualenvs" }

            # Search paths
            $searchPaths = @(
                (Join-Path $inputPath ".venv"),
                $inputPath,
                (Join-Path $workonHome $inputPath ".venv"),
                (Join-Path $workonHome $inputPath)
            )

            # Find the first existing venv
            foreach ($path in $searchPaths) {
                if ((Test-Path $path -PathType Container) -and
                    (Test-Path (Join-Path $path "Scripts" "Activate.ps1") -PathType Leaf)) {
                    $venvPath = $path
                    break
                }
            }

            if (-not $venvPath) {
                Write-Host "${RED}${BOLD}Error:${NOCOLOR} ${RED}Virtual environment not found${NOCOLOR}" -ForegroundColor Red
                Write-Host "${DIM}Searched for:${NOCOLOR} ${YELLOW}$inputPath${NOCOLOR}"
                Write-Host "${DIM}Locations checked:${NOCOLOR}"
                $searchPaths | ForEach-Object { Write-Host "  • $_" }
                return 1
            }

            # Activate
            $activateScript = Join-Path $venvPath "Scripts" "Activate.ps1"
            & $activateScript

            Write-Host "${GREEN}${BOLD}✓${NOCOLOR} ${GREEN}Activated:${NOCOLOR} ${CYAN}$venvPath${NOCOLOR}" -ForegroundColor Green

            # Show Python version
            if (Get-Command python -ErrorAction SilentlyContinue) {
                $pyVersion = & python --version 2>&1
                Write-Host "${DIM}  $pyVersion${NOCOLOR}"
            }
        }

        "deactivate" {
            if (-not $env:VIRTUAL_ENV) {
                Write-Host "${YELLOW}${BOLD}Warning:${NOCOLOR} ${YELLOW}No virtual environment is active${NOCOLOR}" -ForegroundColor Yellow
                return 1
            }

            $oldVenv = $env:VIRTUAL_ENV
            if (Get-Command deactivate -ErrorAction SilentlyContinue) {
                deactivate
                Write-Host "${YELLOW}${BOLD}✗${NOCOLOR} ${YELLOW}Deactivated:${NOCOLOR} ${CYAN}$oldVenv${NOCOLOR}" -ForegroundColor Yellow
            } else {
                Write-Host "${RED}${BOLD}Error:${NOCOLOR} ${RED}deactivate function not available${NOCOLOR}" -ForegroundColor Red
                return 1
            }
        }

        default {
            & uv.exe @Args
        }
    }
}

function uv {
    param(
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    # Logging helper functions
    function Info([string]$Message) {
        Write-Host "✓ $Message" -ForegroundColor Green
    }

    function Warn([string]$Message) {
        Write-Host "Warning: $Message" -ForegroundColor Yellow
    }

    function Error([string]$Message) {
        Write-Host "Error: $Message" -ForegroundColor Red
    }

    function Note([string]$Message) {
        Write-Host $Message -ForegroundColor DarkGray
    }

    if (-not $Command) {
        Write-Host "Usage: uv {activate|deactivate|...}" -ForegroundColor White
        return
    }

    switch ($Command) {
        "activate" {
            $InputPath = if ($Args.Count -gt 0) { $Args[0] } else { "." }
            $VenvPath = ""
            $VirtualenvsFolder = if ($env:WORKON_HOME) { $env:WORKON_HOME } else { Join-Path $env:USERPROFILE ".virtualenvs" }
            $ActivateScript = ""

            # Normalize input path
            $InputPath = $InputPath.TrimEnd('\', '/')

            if ($InputPath -eq ".") {
                $InputPath = Get-Location
            } elseif (-not [System.IO.Path]::IsPathRooted($InputPath)) {
                $InputPath = Join-Path (Get-Location) $InputPath
            }

            $PossiblePaths = @(
                (Join-Path $InputPath ".venv"),
                $InputPath,
                (Join-Path $VirtualenvsFolder $InputPath),
                (Join-Path $VirtualenvsFolder (Split-Path $InputPath -Leaf))
            )

            foreach ($Path in $PossiblePaths) {
                if (Test-Path $Path -PathType Container) {
                    if (Test-Path (Join-Path $Path "Scripts\activate.ps1")) {
                        $VenvPath = $Path
                        $ActivateScript = Join-Path $Path "Scripts\activate.ps1"
                        break
                    } elseif (Test-Path (Join-Path $Path "bin\activate")) {
                        $VenvPath = $Path
                        $ActivateScript = Join-Path $Path "Scripts\activate.ps1"
                        if (-not (Test-Path $ActivateScript)) {
                            Error "PowerShell activation script not found. This venv may not be compatible with PowerShell."
                            return
                        }
                        break
                    }
                }
            }

            if (-not $VenvPath -or -not (Test-Path $VenvPath)) {
                Error "Virtual environment not found"
                Note "Searched for: $InputPath"
                Note "Locations checked:"
                Write-Host "  - $(Join-Path $VirtualenvsFolder "$InputPath\.venv")" -ForegroundColor Cyan
                Write-Host "  - $(Join-Path $VirtualenvsFolder $InputPath)" -ForegroundColor Cyan
                Write-Host "  - $(Join-Path $InputPath ".venv")" -ForegroundColor Cyan
                Write-Host "  - $InputPath" -ForegroundColor Cyan
                Note "You can create a virtual environment using:"
                Write-Host "uv venv <name-of-env>" -ForegroundColor Cyan
                return
            }

            if (Test-Path $ActivateScript) {
                & $ActivateScript
                Info "Activated: $VenvPath"
            } else {
                Error "Activation script not found: $ActivateScript"
            }
        }

        "deactivate" {
            $OldVenv = $env:VIRTUAL_ENV
            if (-not $OldVenv) {
                Warn "No virtual environment is active"
                return
            }

            if (Get-Command deactivate -ErrorAction SilentlyContinue) {
                deactivate
                Info "Deactivated: $OldVenv"
            } else {
                Error "deactivate function not available"
            }
        }

        default {
            if ($Args.Count -gt 0) {
                & uv.exe $Command @Args
            } else {
                & uv.exe $Command
            }
        }
    }
}

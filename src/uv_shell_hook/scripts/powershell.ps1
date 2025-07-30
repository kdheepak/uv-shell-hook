function uv {
    param(
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    switch ($Command) {
        'activate' {
            $Path = if ($Args) { $Args[0] } else { '.venv' }

            # Check common venv locations
            $VenvPath = $null
            $Locations = @(
                (Join-Path (Get-Location) $Path),
                (Join-Path (Get-Location) '.venv'),
                (Join-Path ($env:WORKON_HOME ?? "$env:USERPROFILE\.virtualenvs") $Path)
            )

            foreach ($Loc in $Locations) {
                $ActivateScript = Join-Path $Loc 'Scripts\activate.ps1'
                if (Test-Path $ActivateScript) {
                    $VenvPath = $Loc
                    break
                }
            }

            if ($VenvPath) {
                & (Join-Path $VenvPath 'Scripts\activate.ps1')
                Write-Host "✓ Activated: $VenvPath" -ForegroundColor Green
            } else {
                Write-Host "Virtual environment not found: $Path" -ForegroundColor Red
            }
        }

        'deactivate' {
            if ($env:VIRTUAL_ENV -and (Get-Command deactivate -ErrorAction SilentlyContinue)) {
                deactivate
                Write-Host "✓ Deactivated" -ForegroundColor Green
            } else {
                Write-Host "No virtual environment is active" -ForegroundColor Yellow
            }
        }

        default {
            & uv.exe $Command @Args
        }
    }
}

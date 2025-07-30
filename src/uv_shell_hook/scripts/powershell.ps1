function uv {
    param(
        [Parameter(Position=0)]
        [string]$Command,

        [Parameter(Position=1, ValueFromRemainingArguments=$true)]
        [string[]]$Args
    )

    switch ($Command) {
        'activate' {
            $WorkonHome = if ($env:WORKON_HOME) { $env:WORKON_HOME } else { "$env:USERPROFILE\.virtualenvs" }

            if ($Args) {
                $Name = $Args[0]
                $Locations = @(
                    (Join-Path (Get-Location) $Name),
                    (Join-Path $WorkonHome $Name)
                )
            } else {
                $Locations = @(
                    (Join-Path (Get-Location) '.venv')
                )
            }

            $VenvPath = $null
            foreach ($Loc in $Locations) {
                $ActivateScript = Join-Path $Loc 'Scripts\activate.ps1'
                if (Test-Path $ActivateScript) {
                    $VenvPath = $Loc
                    break
                }
            }

            if ($VenvPath) {
                & (Join-Path $VenvPath 'Scripts\activate.ps1')
                Write-Host "Activated: $VenvPath" -ForegroundColor Green
            } else {
                Write-Host "Virtual environment not found: $($Args[0])" -ForegroundColor Red
                exit 1
            }
        }

        'deactivate' {
            if ($env:VIRTUAL_ENV -and (Get-Command deactivate -ErrorAction SilentlyContinue)) {
                deactivate
                Write-Host "Deactivated: $env:VIRTUAL_ENV" -ForegroundColor Green
            } else {
                Write-Host "No virtual environment is active" -ForegroundColor Yellow
                exit 1
            }
        }

        default {
            & uv.exe $Command @Args
        }
    }
}

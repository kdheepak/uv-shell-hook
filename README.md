# `uv-shell-hook`

A cross-platform shell integration for [uv](https://github.com/astral-sh/uv) that adds convenient
`uv activate` and `uv deactivate` commands to manage Python virtual environments across different
shells and operating systems.

## Features

- **Cross-platform support**: Works on Linux, macOS, and Windows
- **Multi-shell support**: bash, zsh, Fish, PowerShell, and Windows CMD
- **Consistent interface**: Same `uv activate` and `uv deactivate` commands across all shells
- **Virtual environment discovery**: Automatically finds virtual environments in multiple locations

## Installation

```bash
$ uv tool install uv-shell-hook
$ uv-shell-hook --help

# or use it with uvx directly

$ uvx uv-shell-hook --help
```

## Quick Start

Choose your shell and follow the setup instructions below:

### Bash

Add the `uv` function to your shell:

```bash
# Add to ~/.bashrc or ~/.bash_profile
eval "$(uv-shell-hook bash)"
```

Or manually add the function:

```bash
uv-shell-hook bash >> ~/.bashrc
source ~/.bashrc
```

### Zsh

Add the `uv` function to your shell:

```zsh
# Add to ~/.zshrc
eval "$(uv-shell-hook zsh)"
```

Or manually add the function:

```zsh
uv-shell-hook zsh >> ~/.zshrc
source ~/.zshrc
```

### Fish

Add the `uv` function to your shell:

```fish
# Add to ~/.config/fish/config.fish
uv-shell-hook fish | source
```

Or manually add the function:

```fish
uv-shell-hook fish >> ~/.config/fish/config.fish
```

### PowerShell

Add the `uv` function to your PowerShell profile:

```powershell
# Add to your PowerShell profile (run $PROFILE to see location)
uv-shell-hook powershell | Out-String | Invoke-Expression
```

Or save it permanently:

```powershell
uv-shell-hook powershell | Add-Content $PROFILE
```

### Windows CMD

Save the batch script and add it to your `PATH`:

```cmd
# Save the batch script
uv-shell-hook cmd > uv.bat

# Move to a directory in your `PATH` (e.g., C:\Windows\System32 or create a local bin directory)
move uv.bat C:\Users\%USERNAME%\bin\
```

Make sure the directory containing `uv.bat` is in your system `PATH`.

## Usage

Once installed, you can use the enhanced `uv` commands in any supported shell:

### Activate a Virtual Environment

The `uv activate` command will search for virtual environments in the following locations (in
order):

1. `<path>/.venv` - Local .venv directory
2. `<path>` itself (if it ends with `.venv`)
3. `~/.virtualenvs/<name>` - Named environment directory

```bash
# Activate virtual environment in current directory
uv activate

# Activate virtual environment in specific path
uv activate ./my-project

# Activate virtual environment by name from ~/.virtualenvs/my-project
# i.e. mimic `workon myproject` from virtualenvwrapper or `conda activate myproject` from conda
uv activate my-project

# Activate specific .venv path
uv activate /path/to/project/.venv
```

### Deactivate Virtual Environment

```bash
# Deactivate currently active virtual environment
uv deactivate
```

### Other `uv` Commands

All other `uv` commands work exactly as before:

```bash
uv init
uv add requests
uv run python script.py
uv sync
# ... any other `uv` command
```

## Troubleshooting

If you encounter issues, try the following:

- Ensure the shell configuration file is sourced correctly (e.g., `source ~/.bashrc` or
  `source ~/.zshrc`).
- Check that the `uv-shell-hook` command is available in your `PATH`.
- Verify that the virtual environment exists in the expected location.
- If using Fish, ensure you have the latest version of Fish shell that supports the syntax used.
- For PowerShell, ensure your execution policy allows running scripts
  (`Set-ExecutionPolicy RemoteSigned`).
- If you have issues with CMD, ensure the `uv.bat` file is in a directory included in your system
  `PATH`.
- Check the `uv` documentation for any updates or changes to command usage.
- If you have custom virtual environment locations, ensure they are correctly set in your shell
  configuration.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

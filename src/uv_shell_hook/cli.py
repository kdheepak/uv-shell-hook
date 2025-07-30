"""
uv-shell-hook - Enhanced virtual environment activation for uv
"""

import sys
import typer
from typing import Optional
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

from .version import __version__

# Initialize console at module level
console = Console(legacy_windows=True)
app = typer.Typer(help=__doc__, add_completion=False)


# Shell detection helper
def detect_shell() -> str:
    """Detect the current shell."""
    import os

    shell = os.environ.get("SHELL", "").lower()
    if "fish" in shell:
        return "fish"
    elif "zsh" in shell:
        return "zsh"
    elif "bash" in shell:
        return "bash"
    elif sys.platform == "win32":
        if "powershell" in os.environ.get("PSModulePath", "").lower():
            return "powershell"
        return "cmd"
    return "unknown"


def version_callback(value: bool):
    if value:
        console.print(f"[bold yellow]uv-shell-hook {__version__}[/]")
        raise typer.Exit()


# Configuration constants
VENV_SEARCH_PATHS = [
    "{input_path}/.venv",
    "{input_path}",  # if it ends with .venv
    "{workon_home}/{input_path}/.venv",
    "{workon_home}/{input_path}",
]


def _get_script_content(script_name: str) -> str:
    """Read script content from file."""
    script_path = Path(__file__).parent / "scripts" / script_name
    if not script_path.exists():
        raise FileNotFoundError(f"Script file not found: {script_path}")
    return script_path.read_text(encoding="utf-8")


def _get_shell_function():
    """Get the shell function code for uv command override (bash/zsh)."""
    return _get_script_content("bash.sh")


def _get_powershell_function():
    """Get the PowerShell function code for uv command override."""
    return _get_script_content("powershell.ps1")


def _get_fish_function():
    """Get the Fish shell function code for uv command override."""
    return _get_script_content("fish.fish")


def _get_cmd_batch():
    """Get the CMD batch script code for uv command override."""
    return _get_script_content("cmd.cmd")


def get_installation_instructions(shell: str) -> str:
    """Get installation instructions for the given shell."""
    instructions = {
        "bash": """# Add to ~/.bashrc or ~/.bash_profile:
eval "$(uv-shell-hook bash)"

# Or manually:
uv-shell-hook bash >> ~/.bashrc""",
        "zsh": """# Add to ~/.zshrc:
eval "$(uv-shell-hook zsh)"

# Or manually:
uv-shell-hook zsh >> ~/.zshrc""",
        "fish": """# Add to ~/.config/fish/config.fish:
uv-shell-hook fish | source

# Or manually:
uv-shell-hook fish >> ~/.config/fish/config.fish""",
        "powershell": """# Add to your PowerShell profile:
uv-shell-hook powershell | Out-String | Invoke-Expression

# Or manually add to $PROFILE:
uv-shell-hook powershell >> $PROFILE""",
        "cmd": """# Create a batch file in your PATH:
uv-shell-hook cmd > %USERPROFILE%\\bin\\uv.bat

# Make sure %USERPROFILE%\\bin is in your PATH""",
    }

    return instructions.get(shell, "# Unknown shell. Please refer to documentation.")


@app.command()
def install_instructions(
    shell: Optional[str] = typer.Option(
        None, "--shell", "-s", help="Target shell (auto-detected if not specified)"
    ),
):
    """Install the uv shell hook for your shell."""
    if not shell:
        shell = detect_shell()
        if shell == "unknown":
            console.print("[red]Could not detect shell. Please specify with --shell[/]")
            raise typer.Exit(1)

    console.print(f"[green]Installing uv shell hook for {shell}...[/]\n")

    instructions = get_installation_instructions(shell)
    console.print(
        Panel(instructions, title=f"Installation for {shell}", border_style="blue")
    )

    console.print(
        "\n[yellow]Note:[/] You'll need to restart your shell or source your config file for changes to take effect."
    )


@app.command()
def zsh():
    """Print zsh shell function for uv command override."""
    syntax = Syntax(
        _get_script_content("bash.sh"), "zsh", theme="github", line_numbers=False
    )
    console.print(syntax)


@app.command()
def bash():
    """Print bash shell function for uv command override."""
    syntax = Syntax(
        _get_script_content("bash.sh"), "bash", theme="github", line_numbers=False
    )
    console.print(syntax)


@app.command()
def powershell():
    """Print PowerShell function for uv command override."""
    syntax = Syntax(
        _get_powershell_function(), "powershell", theme="github", line_numbers=False
    )
    console.print(syntax)


@app.command()
def fish():
    """Print Fish shell function for uv command override."""
    syntax = Syntax(_get_fish_function(), "fish", theme="github", line_numbers=False)
    console.print(syntax)


@app.command()
def cmd():
    """Print CMD batch script for uv command override."""
    syntax = Syntax(_get_cmd_batch(), "batch", theme="github", line_numbers=False)
    console.print(syntax)


@app.command()
def test():
    """Test the shell detection and environment finding logic."""
    shell = detect_shell()
    console.print(f"[blue]Detected shell:[/] {shell}")

    import os

    console.print(f"[blue]WORKON_HOME:[/] {os.environ.get('WORKON_HOME', 'Not set')}")
    console.print(f"[blue]VIRTUAL_ENV:[/] {os.environ.get('VIRTUAL_ENV', 'Not set')}")

    # Show where venvs would be searched
    console.print("\n[blue]Virtual environment search locations:[/]")
    workon = os.environ.get("WORKON_HOME", os.path.expanduser("~/.virtualenvs"))
    for template in VENV_SEARCH_PATHS:
        path = template.format(input_path="myproject", workon_home=workon)
        path_exists = os.path.exists(os.path.expanduser(path))
        exists_mark = "✓" if path_exists else "✗"
        exists_color = "green" if path_exists else "red"
        console.print(f"  [{exists_color}]{exists_mark}[/] {path}")


@app.callback(invoke_without_command=True)
def main(
    ctx: typer.Context,
    version: bool = typer.Option(
        False, "--version", callback=version_callback, help="Show version and exit"
    ),
):
    """Enhanced virtual environment activation for uv."""
    if ctx.invoked_subcommand is None:
        # Show a nice welcome message with examples
        console.print(
            Panel.fit(
                "[bold]uv-shell-hook[/] - Enhanced virtual environment activation for uv\n\n"
                "[yellow]Examples:[/]\n"
                "  uv-shell-hook install              # Auto-detect and install for your shell\n"
                "  uv-shell-hook bash                 # Print bash function\n"
                "  uv-shell-hook test                 # Test shell detection\n\n"
                "[dim]After installation, use:[/]\n"
                "  uv activate                # Activate .venv in current directory\n"
                "  uv activate myproject      # Activate named environment\n"
                "  uv deactivate              # Deactivate current environment",
                title="Welcome",
                border_style="blue",
            )
        )

        console.print(
            f"\n[dim]Version {__version__} • Run 'uv-shell-hook --help' for more options[/]"
        )
        raise typer.Exit()


if __name__ == "__main__":
    app()

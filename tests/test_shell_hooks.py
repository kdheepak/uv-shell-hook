"""Tests for shell hook functionality."""

import os
import subprocess
import tempfile
import pytest
from pathlib import Path


@pytest.fixture
def project_root():
    """Get the project root directory."""
    return Path(__file__).parent.parent


@pytest.fixture
def temp_project():
    """Create a temporary project directory with a virtual environment."""
    with tempfile.TemporaryDirectory() as temp_dir:
        project_dir = Path(temp_dir) / "test_project"
        project_dir.mkdir()

        # Create virtual environment
        subprocess.run(
            ["uv", "venv", ".venv"], cwd=project_dir, check=True, capture_output=True
        )

        yield project_dir


@pytest.fixture
def bash_hook_file(project_root: Path):
    """Create a temporary file with the bash hook sourced."""
    # Get the bash hook content directly from the script file
    script_path = project_root / "src" / "uv_shell_hook" / "scripts" / "bash.sh"
    script_content = script_path.read_text()

    with tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False) as f:
        f.write(script_content)
        hook_file = Path(f.name)

    yield hook_file

    # Cleanup
    hook_file.unlink()


@pytest.fixture
def zsh_hook_file(project_root: Path):
    """Create a temporary file with the zsh hook sourced."""
    # Zsh uses the same script as bash
    script_path = project_root / "src" / "uv_shell_hook" / "scripts" / "bash.sh"
    script_content = script_path.read_text()

    with tempfile.NamedTemporaryFile(mode="w", suffix=".zsh", delete=False) as f:
        f.write(script_content)
        hook_file = Path(f.name)

    yield hook_file

    # Cleanup
    hook_file.unlink()


@pytest.fixture
def fish_hook_file(project_root: Path):
    """Create a temporary file with the fish hook sourced."""
    # Get the fish hook content directly from the script file
    script_path = project_root / "src" / "uv_shell_hook" / "scripts" / "fish.fish"
    script_content = script_path.read_text()

    with tempfile.NamedTemporaryFile(mode="w", suffix=".fish", delete=False) as f:
        f.write(script_content)
        hook_file = Path(f.name)

    yield hook_file

    # Cleanup
    hook_file.unlink()


@pytest.fixture
def cmd_hook_file(project_root: Path):
    """Create a temporary file with the cmd shell hook sourced."""
    script_path = project_root / "src" / "uv_shell_hook" / "scripts" / "cmd.cmd"
    script_content = script_path.read_text()

    with tempfile.NamedTemporaryFile(mode="w", suffix=".cmd", delete=False) as f:
        f.write(script_content)
        hook_file = Path(f.name)

    yield hook_file

    hook_file.unlink()


@pytest.fixture
def powershell_hook_file(project_root: Path):
    """Create a temporary file with the PowerShell hook sourced."""
    # Get the PowerShell hook content directly from the script file
    script_path = project_root / "src" / "uv_shell_hook" / "scripts" / "powershell.ps1"
    script_content = script_path.read_text()

    with tempfile.NamedTemporaryFile(mode="w", suffix=".ps1", delete=False) as f:
        f.write(script_content)
        hook_file = Path(f.name)

    yield hook_file

    # Cleanup
    hook_file.unlink()


def run_bash_with_hook(
    command: str, cwd: Path, hook_file: Path
) -> subprocess.CompletedProcess:
    """Run a bash command with the shell hook sourced from file."""
    full_command = f"source {hook_file} && {command}"

    return subprocess.run(
        ["bash", "-c", full_command], cwd=cwd, capture_output=True, text=True
    )


def run_zsh_with_hook(
    command: str, cwd: Path, hook_file: Path
) -> subprocess.CompletedProcess:
    """Run a zsh command with the shell hook sourced from file."""
    full_command = f"source {hook_file} && {command}"

    return subprocess.run(
        ["zsh", "-c", full_command], cwd=cwd, capture_output=True, text=True
    )


def run_fish_with_hook(
    command: str, cwd: Path, hook_file: Path
) -> subprocess.CompletedProcess:
    """Run a fish command with the shell hook sourced from file."""
    full_command = f"source {hook_file}; and {command}"

    # Run fish with clean environment to avoid config issues
    env = os.environ.copy()
    env["HOME"] = str(cwd)  # Use temp directory as HOME to avoid config conflicts

    return subprocess.run(
        ["fish", "--no-config", "-c", full_command],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


def get_short_path_name(long_name):
    import ctypes

    _buf = ctypes.create_unicode_buffer(260)
    ctypes.windll.kernel32.GetShortPathNameW(long_name, _buf, 260)
    return _buf.value


def run_cmd_with_hook(
    command: str, cwd: Path, hook_file: Path
) -> subprocess.CompletedProcess:
    """Run a cmd.exe command with the shell hook sourced from file."""
    hook_path = get_short_path_name(str(hook_file.resolve()))
    full_command = command.replace("uv", f"call {hook_path}")

    return subprocess.run(
        ["cmd", "/d", "/c", full_command],
        cwd=cwd,
        capture_output=True,
        text=True,
        shell=True,
    )


def run_powershell_with_hook(
    command: str, cwd: Path, hook_file: Path
) -> subprocess.CompletedProcess:
    """Run a PowerShell command with the shell hook sourced from file."""
    full_command = f". {hook_file}; {command}"

    return subprocess.run(
        [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            full_command,
        ],
        cwd=cwd,
        capture_output=True,
        text=True,
    )


@pytest.mark.skipif(os.name == "nt", reason="Bash tests only run on Unix-like systems")
class TestBashHook:
    """Test bash shell hook functionality."""

    def test_activate_virtual_environment(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test activating a virtual environment."""
        result = run_bash_with_hook(
            "uv activate && echo 'VIRTUAL_ENV='$VIRTUAL_ENV",
            temp_project,
            bash_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        assert str(temp_project / ".venv") in result.stdout

    def test_deactivate_virtual_environment(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test deactivating a virtual environment."""
        result = run_bash_with_hook(
            "uv activate && uv deactivate && echo 'VIRTUAL_ENV='$VIRTUAL_ENV",
            temp_project,
            bash_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        # After deactivation, VIRTUAL_ENV should be empty
        lines = result.stdout.strip().split("\n")
        virtual_env_line = [line for line in lines if line.startswith("VIRTUAL_ENV=")][
            -1
        ]
        assert virtual_env_line == "VIRTUAL_ENV="

    def test_activate_nonexistent_environment(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test that activating a non-existent environment fails."""
        result = run_bash_with_hook(
            "uv activate nonexistent", temp_project, bash_hook_file
        )

        assert result.returncode != 0
        assert "Virtual environment not found" in result.stderr

    def test_deactivate_when_none_active(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test that deactivating when no environment is active fails gracefully."""
        result = run_bash_with_hook("uv deactivate", temp_project, bash_hook_file)

        assert result.returncode != 0
        # The error message can be either of these depending on the environment state
        assert (
            "No virtual environment is active" in result.stderr
            or "deactivate function not available" in result.stderr
        )

    def test_regular_uv_commands_passthrough(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test that regular uv commands still work."""
        result = run_bash_with_hook("uv --version", temp_project, bash_hook_file)

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "uv" in result.stdout.lower()

    def test_python_path_in_activated_environment(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test that Python path points to the virtual environment when activated."""
        result = run_bash_with_hook(
            "uv activate && which python", temp_project, bash_hook_file
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert str(temp_project / ".venv") in result.stdout

    def test_activation_success_message(self, temp_project: Path, bash_hook_file: Path):
        """Test that activation shows success message."""
        result = run_bash_with_hook("uv activate", temp_project, bash_hook_file)

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout

    def test_deactivation_success_message(
        self, temp_project: Path, bash_hook_file: Path
    ):
        """Test that deactivation shows success message."""
        result = run_bash_with_hook(
            "uv activate && uv deactivate", temp_project, bash_hook_file
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout
        assert "Deactivated:" in result.stdout


@pytest.mark.skipif(os.name == "nt", reason="Zsh tests only run on Unix-like systems")
class TestZshHook:
    """Test zsh shell hook functionality."""

    def test_activate_virtual_environment(
        self, temp_project: Path, zsh_hook_file: Path
    ):
        """Test activating a virtual environment."""
        result = run_zsh_with_hook(
            "uv activate && echo 'VIRTUAL_ENV='$VIRTUAL_ENV",
            temp_project,
            zsh_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        assert str(temp_project / ".venv") in result.stdout

    def test_deactivate_virtual_environment(
        self, temp_project: Path, zsh_hook_file: Path
    ):
        """Test deactivating a virtual environment."""
        result = run_zsh_with_hook(
            "uv activate && uv deactivate && echo 'VIRTUAL_ENV='$VIRTUAL_ENV",
            temp_project,
            zsh_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        # After deactivation, VIRTUAL_ENV should be empty
        lines = result.stdout.strip().split("\n")
        virtual_env_line = [line for line in lines if line.startswith("VIRTUAL_ENV=")][
            -1
        ]
        assert virtual_env_line == "VIRTUAL_ENV="

    def test_regular_uv_commands_passthrough(
        self, temp_project: Path, zsh_hook_file: Path
    ):
        """Test that regular uv commands still work."""
        result = run_zsh_with_hook("uv --version", temp_project, zsh_hook_file)

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "uv" in result.stdout.lower()


@pytest.mark.skipif(os.name == "nt", reason="Fish tests only run on Unix-like systems")
class TestFishHook:
    """Test fish shell hook functionality."""

    def test_activate_virtual_environment(
        self, temp_project: Path, fish_hook_file: Path
    ):
        """Test activating a virtual environment."""
        result = run_fish_with_hook(
            "uv activate && echo 'VIRTUAL_ENV='$VIRTUAL_ENV",
            temp_project,
            fish_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        assert str(temp_project / ".venv") in result.stdout

    def test_deactivate_virtual_environment(
        self, temp_project: Path, fish_hook_file: Path
    ):
        """Test deactivating a virtual environment."""
        result = run_fish_with_hook(
            "uv activate; and uv deactivate",
            temp_project,
            fish_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout
        assert "Deactivated:" in result.stdout

    def test_regular_uv_commands_passthrough(
        self, temp_project: Path, fish_hook_file: Path
    ):
        """Test that regular uv commands still work."""
        result = run_fish_with_hook("uv --version", temp_project, fish_hook_file)

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "uv" in result.stdout.lower()


@pytest.mark.skipif(os.name != "nt", reason="cmd tests only run on Windows")
class TestCmdHook:
    """Test Windows cmd shell hook functionality."""

    def test_activate_virtual_environment(
        self, temp_project: Path, cmd_hook_file: Path
    ):
        result = run_cmd_with_hook(
            "uv activate && echo VIRTUAL_ENV=%VIRTUAL_ENV%",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        assert str(temp_project / ".venv").replace("/", "\\") in result.stdout

    # def test_deactivate_virtual_environment(
    #     self, temp_project: Path, cmd_hook_file: Path
    # ):
    #     result = run_cmd_with_hook(
    #         "uv activate && uv deactivate && echo VIRTUAL_ENV=%VIRTUAL_ENV%",
    #         temp_project,
    #         cmd_hook_file,
    #     )
    #     assert result.returncode == 0, f"Command failed: {result.stderr}"
    #     assert "VIRTUAL_ENV=" in result.stdout
    #     lines = result.stdout.strip().splitlines()
    #     virtual_env_line = [line for line in lines if line.startswith("VIRTUAL_ENV=")][
    #         -1
    #     ]
    #     assert virtual_env_line == "VIRTUAL_ENV="

    def test_activate_nonexistent_environment(
        self, temp_project: Path, cmd_hook_file: Path
    ):
        result = run_cmd_with_hook(
            "uv activate nonexistent",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode != 0
        assert "Virtual environment not found" in result.stderr + result.stdout

    def test_deactivate_when_none_active(self, temp_project: Path, cmd_hook_file: Path):
        # Reset environment and functions if needed; simulate no active env
        result = run_cmd_with_hook(
            "set VIRTUAL_ENV= && uv deactivate",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode != 0
        assert (
            "No virtual environment is active" in result.stderr + result.stdout
            or "deactivate function not available" in result.stderr + result.stdout
        )

    def test_regular_uv_commands_passthrough(
        self, temp_project: Path, cmd_hook_file: Path
    ):
        result = run_cmd_with_hook(
            "uv --version",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "uv" in result.stdout.lower()

    def test_activation_success_message(self, temp_project: Path, cmd_hook_file: Path):
        result = run_cmd_with_hook(
            "uv activate",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout

    def test_deactivation_success_message(
        self, temp_project: Path, cmd_hook_file: Path
    ):
        result = run_cmd_with_hook(
            "uv activate && uv deactivate",
            temp_project,
            cmd_hook_file,
        )
        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout
        assert "Deactivated:" in result.stdout


@pytest.mark.skipif(os.name != "nt", reason="PowerShell tests only run on Windows")
class TestPowershellHook:
    """Test PowerShell shell hook functionality."""

    def test_activate_virtual_environment(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test activating a virtual environment."""
        result = run_powershell_with_hook(
            "uv activate; Write-Output 'VIRTUAL_ENV='$env:VIRTUAL_ENV",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "VIRTUAL_ENV=" in result.stdout
        # assert str(temp_project / ".venv").replace("\\", "/") in result.stdout.replace(
        #     "\\", "/"
        # )

    def test_deactivate_virtual_environment(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test deactivating a virtual environment."""
        result = run_powershell_with_hook(
            "uv activate; uv deactivate",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout
        assert "Deactivated:" in result.stdout

    def test_activate_nonexistent_environment(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test that activating a non-existent environment fails."""
        result = run_powershell_with_hook(
            "uv activate nonexistent",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode != 0
        assert "Virtual environment not found" in result.stdout

    def test_deactivate_when_none_active(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test that deactivating when no environment is active fails gracefully."""
        result = run_powershell_with_hook(
            "$env:VIRTUAL_ENV=''; Remove-Item function:deactivate -ErrorAction SilentlyContinue; uv deactivate",
            temp_project,
            powershell_hook_file,
        )
        assert result.returncode != 0
        assert "No virtual environment is active" in result.stdout

    def test_regular_uv_commands_passthrough(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test that regular uv commands still work."""
        result = run_powershell_with_hook(
            "uv --version",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "uv" in result.stdout.lower()

    def test_activation_success_message(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test that activation shows success message."""
        result = run_powershell_with_hook(
            "uv activate",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout

    def test_deactivation_success_message(
        self, temp_project: Path, powershell_hook_file: Path
    ):
        """Test that deactivation shows success message."""
        result = run_powershell_with_hook(
            "uv activate; uv deactivate",
            temp_project,
            powershell_hook_file,
        )

        assert result.returncode == 0, f"Command failed: {result.stderr}"
        assert "Activated:" in result.stdout
        assert "Deactivated:" in result.stdout

function uv --wraps=uv --description 'Enhanced uv with virtual environment activation'
    # Color definitions
    set -l RED '\033[0;31m'
    set -l GREEN '\033[0;32m'
    set -l YELLOW '\033[0;33m'
    set -l BLUE '\033[0;34m'
    set -l CYAN '\033[0;36m'
    set -l BOLD '\033[1m'
    set -l DIM '\033[2m'
    set -l NOCOLOR '\033[0m'

    if test (count $argv) -eq 0
        command uv
        return
    end

    switch $argv[1]
        case activate
            set -l input_path "."
            if test (count $argv) -gt 1
                set input_path $argv[2]
            end

            # Remove trailing slash
            set input_path (string trim -c '/' $input_path)

            set -l workon_home "$WORKON_HOME"
            if test -z "$workon_home"
                set workon_home "$HOME/.virtualenvs"
            end

            # Search for virtual environment
            set -l venv_path ""
            set -l search_paths "$input_path/.venv" "$input_path" "$workon_home/$input_path"

            for path in $search_paths
                if test -d "$path" -a \( -f "$path/bin/activate" -o -f "$path/Scripts/activate" \)
                    set venv_path "$path"
                    break
                end
            end

            # Check if virtual environment exists
            if test -z "$venv_path" -o ! -d "$venv_path"
                echo -e "$RED$BOLD"Error:"$NOCOLOR $RED"Virtual environment not found"$NOCOLOR" >&2
                echo -e "$DIM"Searched for:"$NOCOLOR $YELLOW$input_path$NOCOLOR" >&2
                echo -e "$DIM"Locations checked:"$NOCOLOR" >&2
                for path in $search_paths
                    echo "  • $path" >&2
                end
                return 1
            end

            # Determine activation script location based on platform
            set -l activate_script
            if test -n "$WINDIR" -o (uname -s | string match -q "*MSYS*") -o (uname -s | string match -q "*CYGWIN*")
                set activate_script "$venv_path/Scripts/activate"
            else
                set activate_script "$venv_path/bin/activate"
            end

            # Source the activation script
            if test -f "$activate_script"
                source "$activate_script"
                echo -e "$GREEN$BOLD"✓"$NOCOLOR $GREEN"Activated:"$NOCOLOR $CYAN$venv_path$NOCOLOR"

                # Show Python version for confirmation
                if command -v python >/dev/null 2>&1
                    set -l py_version (python --version 2>&1 | string split ' ')[2]
                    echo -e "$DIM"  Python $py_version"$NOCOLOR"
                end
            else
                echo -e "$RED$BOLD"Error:"$NOCOLOR $RED"Activation script not found: $YELLOW$activate_script$NOCOLOR" >&2
                return 1
            end

        case deactivate
            # Check if we're in a virtual environment
            if test -z "$VIRTUAL_ENV"
                echo -e "$YELLOW$BOLD"Warning:"$NOCOLOR $YELLOW"No virtual environment is active"$NOCOLOR" >&2
                return 1
            end

            # Store the old venv path
            set -l old_venv "$VIRTUAL_ENV"

            # Call the deactivate function if it exists
            if functions -q deactivate
                deactivate
                echo -e "$YELLOW$BOLD"✗"$NOCOLOR $YELLOW"Deactivated:"$NOCOLOR $CYAN$old_venv$NOCOLOR"
            else
                echo -e "$RED$BOLD"Error:"$NOCOLOR $RED"deactivate function not available"$NOCOLOR" >&2
                return 1
            end

        case '*'
            # For all other commands, run the actual uv executable
            command uv $argv
    end
end

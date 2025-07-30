function uv
    # Logging helpers using Fish's set_color
    function info
        echo (set_color green --bold)"✓"(set_color normal) (set_color green)"$argv"(set_color normal)
    end

    function warn
        echo (set_color yellow --bold)"Warning:"(set_color normal) (set_color yellow)"$argv"(set_color normal) >&2
    end

    function error
        echo (set_color red --bold)"Error:"(set_color normal) (set_color red)"$argv"(set_color normal) >&2
    end

    function note
        echo (set_color --dim)"$argv"(set_color normal) >&2
    end

    if test -z "$argv[1]"
        echo (set_color --bold)"Usage:"(set_color normal)" uv {activate|deactivate|...}" >&2
        return 1
    end

    switch $argv[1]
        case activate
            set -l input_path $argv[2]
            if test -z "$input_path"
                set input_path "."
            end

            set -l venv_path ""
            set -l virtualenvs_folder $WORKON_HOME
            if test -z "$virtualenvs_folder"
                set virtualenvs_folder "$HOME/.virtualenvs"
            end
            set -l activate_script ""
            set -l is_windows false

            # Normalize input path - remove trailing slash
            set input_path (string trim --right --chars=/ "$input_path")

            # Check for Windows environment
            if test -n "$WINDIR"; or string match -q "msys*" $OSTYPE; or string match -q "cygwin*" $OSTYPE
                set is_windows true
            end

            # Virtual environment detection
            if test -f "$input_path/.venv/Scripts/activate.fish"
                set venv_path "$input_path/.venv"
                set activate_script "$venv_path/Scripts/activate.fish"
            else if test -f "$input_path/.venv/bin/activate.fish"
                set venv_path "$input_path/.venv"
                set activate_script "$venv_path/bin/activate.fish"
            else if test -f "$input_path/Scripts/activate.fish"
                set venv_path "$input_path"
                set activate_script "$venv_path/Scripts/activate.fish"
            else if test -f "$input_path/bin/activate.fish"
                set venv_path "$input_path"
                set activate_script "$venv_path/bin/activate.fish"
            else if test -f "$virtualenvs_folder/$input_path/Scripts/activate.fish"
                set venv_path "$virtualenvs_folder/$input_path"
                set activate_script "$venv_path/Scripts/activate.fish"
            else if test -f "$virtualenvs_folder/$input_path/bin/activate.fish"
                set venv_path "$virtualenvs_folder/$input_path"
                set activate_script "$venv_path/bin/activate.fish"
            end

            # Handle missing venv
            if test -z "$venv_path"; or not test -d "$venv_path"
                error "Virtual environment not found"
                note "Searched for: "(set_color yellow)"$input_path"(set_color normal)
                note "Locations checked:"
                echo "  - "(set_color cyan)"$virtualenvs_folder/$input_path/.venv"(set_color normal) >&2
                echo "  - "(set_color cyan)"$virtualenvs_folder/$input_path"(set_color normal) >&2
                echo "  - "(set_color cyan)"$input_path/.venv"(set_color normal) >&2
                echo "  - "(set_color cyan)"$input_path"(set_color normal) >&2
                note "You can create a virtual environment using:"
                echo (set_color cyan)"uv venv <name-of-env>"(set_color normal) >&2
                return 1
            end

            # Activate the environment
            if test -f "$activate_script"
                source "$activate_script"
                info "Activated: "(set_color cyan)"$venv_path"(set_color normal)
            else
                error "Activation script not found: "(set_color yellow)"$activate_script"(set_color normal)
                return 1
            end

        case deactivate
            set -l old_venv $VIRTUAL_ENV

            if test -z "$old_venv"
                warn "No virtual environment is active"
                return 1
            end

            if functions -q deactivate
                deactivate
                info "Deactivated: "(set_color cyan)"$old_venv"(set_color normal)
            else
                error "deactivate function not available"
                return 1
            end

        case '*'
            # Pass all other commands to the actual uv executable
            command uv $argv
    end
end

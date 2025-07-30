uv() {
    # Color definitions - using proper escape sequences
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local BLUE='\033[0;34m'
    local CYAN='\033[0;36m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NOCOLOR='\033[0m'

    case "${1:-}" in
        activate)
            local input_path="${2:-.}"
            local venv_path=""
            local workon_home="${WORKON_HOME:-$HOME/.virtualenvs}"

            # Normalize input path
            input_path="${input_path%/}"  # Remove trailing slash

            # Search for virtual environment
            local search_paths=(
                "${input_path}/.venv"
                "${input_path}"
                "${workon_home}/${input_path}/.venv"
                "${workon_home}/${input_path}"
            )

            for path in "${search_paths[@]}"; do
                if [[ -d "$path" ]] && [[ -f "$path/bin/activate" || -f "$path/Scripts/activate" ]]; then
                    venv_path="$path"
                    break
                fi
            done

            # Determine activation script location based on platform
            local activate_script
            if [[ $OSTYPE == "msys" || $OSTYPE == "cygwin" || -n ${WINDIR:-} ]]; then
                activate_script="${venv_path}/Scripts/activate"
            else
                activate_script="${venv_path}/bin/activate"
            fi

            # Check if virtual environment exists
            if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
                echo -e "${RED}${BOLD}Error:${NOCOLOR} ${RED}Virtual environment not found${NOCOLOR}" >&2
                echo -e "${DIM}Searched for:${NOCOLOR} ${YELLOW}${input_path}${NOCOLOR}" >&2
                echo -e "${DIM}Locations checked:${NOCOLOR}" >&2
                printf '%s\n' "${search_paths[@]}" | sed 's/^/  • /' >&2
                return 1
            fi

            # Source the activation script
            if [[ -f "$activate_script" ]]; then
                # shellcheck source=/dev/null
                . "$activate_script"
                echo -e "${GREEN}${BOLD}✓${NOCOLOR} ${GREEN}Activated:${NOCOLOR} ${CYAN}${venv_path}${NOCOLOR}"

                # Show Python version for confirmation
                if command -v python >/dev/null 2>&1; then
                    local py_version=$(python --version 2>&1 | cut -d' ' -f2)
                    echo -e "${DIM}  Python ${py_version}${NOCOLOR}"
                fi
            else
                echo -e "${RED}${BOLD}Error:${NOCOLOR} ${RED}Activation script not found: ${YELLOW}${activate_script}${NOCOLOR}" >&2
                return 1
            fi
            ;;

        deactivate)
            # Check if we're in a virtual environment
            if [[ -z ${VIRTUAL_ENV:-} ]]; then
                echo -e "${YELLOW}${BOLD}Warning:${NOCOLOR} ${YELLOW}No virtual environment is active${NOCOLOR}" >&2
                return 1
            fi

            # Store the old venv path
            local old_venv="$VIRTUAL_ENV"

            # Call the deactivate function if it exists
            if command -v deactivate >/dev/null 2>&1; then
                deactivate
                echo -e "${YELLOW}${BOLD}✗${NOCOLOR} ${YELLOW}Deactivated:${NOCOLOR} ${CYAN}${old_venv}${NOCOLOR}"
            else
                echo -e "${RED}${BOLD}Error:${NOCOLOR} ${RED}deactivate function not available${NOCOLOR}" >&2
                return 1
            fi
            ;;

        *)
            # For all other commands, run the actual uv executable
            command uv "$@"
            ;;
    esac
}

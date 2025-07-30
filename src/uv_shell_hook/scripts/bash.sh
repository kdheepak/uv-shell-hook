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
            local virtualenvs_folder="${WORKON_HOME:-$HOME/.virtualenvs}"
            
            # Normalize input path
            input_path="${input_path%/}" # Remove trailing slash
            
            # Check multiple locations for the virtual environment activation script
            if [[ -f "${input_path}/.venv/Scripts/activate" ]]; then
                venv_path="${input_path}/.venv"
                elif [[ -f "${input_path}/.venv/bin/activate" ]]; then
                venv_path="${input_path}/.venv"
                elif [[ -f "${input_path}/Scripts/activate" ]]; then
                venv_path="${input_path}"
                elif [[ -f "${input_path}/bin/activate" ]]; then
                venv_path="${input_path}"
                elif [[ -f "${virtualenvs_folder}/${input_path}/Scripts/activate" ]]; then
                venv_path="${virtualenvs_folder}/${input_path}"
                elif [[ -f "${virtualenvs_folder}/${input_path}/bin/activate" ]]; then
                venv_path="${virtualenvs_folder}/${input_path}"
            fi
            
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
                echo -e "  - ${CYAN}${virtualenvs_folder}/${input_path}/.venv${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${virtualenvs_folder}/${input_path}${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${input_path}/.venv${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${input_path}${NOCOLOR}" >&2
                echo -e "${DIM}You can also create a virtual environment using:${NOCOLOR}" >&2
                echo -e "${CYAN}uv venv <name-of-env>${NOCOLOR}" >&2
                
                return 1
            fi
            
            # Source the activation script
            if [[ -f "$activate_script" ]]; then
                # shellcheck source=/dev/null
                source "$activate_script"
                echo -e "${GREEN}${BOLD}✓${NOCOLOR} ${GREEN}Activated:${NOCOLOR} ${CYAN}${venv_path}${NOCOLOR}"
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

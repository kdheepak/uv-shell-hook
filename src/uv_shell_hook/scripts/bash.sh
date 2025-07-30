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
    
    # Logging helpers
    info()  { echo -e "${GREEN}${BOLD}✓${NOCOLOR} ${GREEN}$1${NOCOLOR}"; }
    warn()  { echo -e "${YELLOW}${BOLD}Warning:${NOCOLOR} ${YELLOW}$1${NOCOLOR}" >&2; }
    error() { echo -e "${RED}${BOLD}Error:${NOCOLOR} ${RED}$1${NOCOLOR}" >&2; }
    note()  { echo -e "${DIM}$1${NOCOLOR}" >&2; }
    
    if [[ -z "${1:-}" ]]; then
        echo -e "${BOLD}Usage:${NOCOLOR} uv {activate|deactivate|...}" >&2
        return 1
    fi
    
    case "$1" in
        activate)
            local input_path="${2:-.}"
            local venv_path=""
            local virtualenvs_folder="${WORKON_HOME:-$HOME/.virtualenvs}"
            local activate_script=""
            local is_windows=false
            
            # Normalize input path
            input_path="${input_path%/}" # Remove trailing slash
            
            # Check for Windows environment
            if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || -n "${WINDIR:-}" ]]; then
                is_windows=true
            fi
            
            # Virtual environment detection
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
            
            # Determine correct activate script
            if [[ "$is_windows" == true ]]; then
                activate_script="${venv_path}/Scripts/activate"
            else
                activate_script="${venv_path}/bin/activate"
            fi
            
            # Handle missing venv
            if [[ -z "$venv_path" || ! -d "$venv_path" ]]; then
                error "Virtual environment not found"
                note "Searched for: ${YELLOW}${input_path}${NOCOLOR}"
                note "Locations checked:"
                echo -e "  - ${CYAN}${virtualenvs_folder}/${input_path}/.venv${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${virtualenvs_folder}/${input_path}${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${input_path}/.venv${NOCOLOR}" >&2
                echo -e "  - ${CYAN}${input_path}${NOCOLOR}" >&2
                note "You can create a virtual environment using:"
                echo -e "${CYAN}uv venv <name-of-env>${NOCOLOR}" >&2
                return 1
            fi
            
            # Activate the environment
            if [[ -f "$activate_script" ]]; then
                # shellcheck source=/dev/null
                source "$activate_script"
                info "Activated: ${CYAN}${venv_path}${NOCOLOR}"
            else
                error "Activation script not found: ${YELLOW}${activate_script}${NOCOLOR}"
                return 1
            fi
        ;;
        
        deactivate)
            local old_venv="${VIRTUAL_ENV:-}"
            
            if [[ -z "$old_venv" ]]; then
                warn "No virtual environment is active"
                return 1
            fi
            
            if command -v deactivate >/dev/null 2>&1; then
                deactivate
                info "Deactivated: ${CYAN}${old_venv}${NOCOLOR}"
            else
                error "deactivate function not available"
                return 1
            fi
        ;;
        
        *)
            # Pass all other commands to the actual uv executable
            command uv "$@"
        ;;
    esac
}

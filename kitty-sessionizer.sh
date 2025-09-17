#!/usr/bin/env bash
## Globals ##
CONFIG_FILE_NAME="kitty-sessionizer.conf"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"
VERSION="0.1"
PERSISTENT_SESSION_STORAGE="$XDG_DATA_HOME/kitty-sessions/"
SESSION_FILE_PREFIX=/tmp/kitty-sessions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

show_help(){
        printf "%s\n" \
            "Usage: kitty-sessionizer [OPTIONS]" \
            "Options:" \
            "  -h, --help             Display this help message" \
            "  -s, --session <name>   session command index" \
            "  -p, --persistent       create Session in XDG_DATA_HOME instead of tmp" \
            "  -x, --close-session    will close the selected session" \
            "  -v, --version          print the current version" \
            " " \
            "For more information about kitty session visit: https://sw.kovidgoyal.net/kitty/overview/#startup-sessions"
}
## Variables ##
session=""
session_path=""

## Entry point ##
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

if [[ -f "$CONFIG_FILE_NAME" ]]; then
    source "$CONFIG_FILE_NAME"
fi


while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -h | --help)
        show_help
        exit
        ;;
    -s | --session)
        # TODO: Add a function to select 1-5 prominent sessions
        # Something like kitty-sessionizer -s 0
        session_name="$2"
        echo "Not implemented yet" >&2
        exit 1
        shift
        shift
        ;;
    -v | --version)
        printf "kitty-sessionizer %s created by LazyStabilty" "$VERSION"
        exit
        ;;
    -p | --persistent)
        SESSION_FILE_PREFIX="$PERSISTENT_SESSION_STORAGE"
        shift
        ;;
    -x | --close-session)
        close_session=true
        shift
        ;;
    *)
        show_help
        exit 1
        ;;
    esac
done

## Functions ##
find_dirs() {
    # TODO: Add prominent sessions with custom naming
    # Something like $SESSION="super-duper name"
    # TODO: Persistent session also need to be searched and put in front of normal ones

    # note: TS_SEARCH_PATHS is an array of paths to search for directories
    # if the path ends with :number, it will search for directories with a max depth of number ;)
    # if there is no number, it will search for directories with a max depth defined by TS_MAX_DEPTH or 1 if not set
    for entry in "${TS_SEARCH_PATHS[@]}"; do
        # Check if entry as :number as suffix then adapt the maxdepth parameter
        if [[ "$entry" =~ ^([^:]+):([0-9]+)$ ]]; then
            path="${BASH_REMATCH[1]}"
            depth="${BASH_REMATCH[2]}"
        else
            path="$entry"
        fi

        [[ -d "$path" ]] && find "$path" -mindepth 1 -maxdepth "${depth:-${TS_MAX_DEPTH:-1}}" -path '*/.git' -prune -o -type d -print
    done
}

# Creates a default file, change ./default.session if you want it to look different
create_session_file(){
    cat "$SCRIPT_DIR"/default.session > "$SESSION_FILE_PREFIX/$session.session"
    sed -i s#@@session-path@@#"$session_path"# "$SESSION_FILE_PREFIX/$session.session" 
    sed -i s#@@session@@#"$session"# "$SESSION_FILE_PREFIX/$session.session" 
}

## Script ##
[[ -z $session_path ]] && session_path=$(find_dirs | fzf --prompt "Switch to session > " || exit 1)

[[ -z "$session_path" ]] && {
    printf "No session selected" >&2
    show_help
    exit 1
} 

# If Session is not yet set,
[[ -z "$session" ]] && session=${session_path##*/}

mkdir -p "$SESSION_FILE_PREFIX"

if [[ -f "$PERSISTENT_SESSION_STORAGE/$session.session" ]]; then
    SESSION_FILE_PREFIX="$PERSISTENT_SESSION_STORAGE"
elif [[ ! -f "$SESSION_FILE_PREFIX/$session.session" ]]; then
    create_session_file
fi


# Open or close the session
if [[ -n "$close_session" ]]; then
    # BUG: This does error with list index out of range
    # kitten @ action close_session "$SESSION_FILE_PREFIX/$session.session"
    kitten @ action close_session "$session"
else
    kitten @ action goto_session "$SESSION_FILE_PREFIX/$session.session"
fi

#!/usr/bin/env bash
## Globals ##
CONFIG_FILE_NAME="kitty-sessionizer.conf"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"
VERSION="0.1"
PERSISTENT_SESSION_STORAGE="$XDG_DATA_HOME/kitty-sessions/"
SESSION_FILE_PREFIX=/tmp/kitty-sessions

show_help(){
        printf "%s\n" \
            "Usage: kitty-sessionizer [OPTIONS]" \
            "Options:" \
            "  -h, --help                   Display this help message" \
            "  -s, --session <name>         Open the specified session" \
            "  -n, --create-named-session   Create Session in XDG_DATA_HOME instead of tmp" \
            "                               Enter a name and a path, if path is left empty" \
            "                               The picker opens for you to choose a path" \
            "  -v, --version                Print the current version" \
            " " \
            "For more information about kitty session visit: https://sw.kovidgoyal.net/kitty/overview/#startup-sessions"
}
log(){
    echo "$*"
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
        session_path="not-empty"
        session="$2"
        shift
        shift
        ;;
    -v | --version)
        printf "kitty-sessionizer %s created by LazyStabilty" "$VERSION"
        exit
        ;;
    -n | --create-named-session)
        SESSION_FILE_PREFIX="$PERSISTENT_SESSION_STORAGE"
        shift
        ;;
    *)
        show_help
        exit 1
        ;;
    esac
done

if [[ "$SESSION_FILE_PREFIX" == "$PERSISTENT_SESSION_STORAGE" ]]; then
    read -rp "Session Name:" session
    read -erp "Session path:" session_path
fi
log "kitty-sessionizer($VERSION): session=$session path=$session_path"

## Functions ##
find_dirs() {
    find "$PERSISTENT_SESSION_STORAGE"  -type f  -name '*.kitty-session' -print0 | xargs -0 -- basename -s .kitty-session

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

# Creates a default file, change ./default.kitty-session if you want it to look different
create_session_file(){
    log "Creating session file: $SESSION_FILE_PREFIX/$session.kitty-session"
    cat "$CONFIG_DIR"/default.kitty-session > "$SESSION_FILE_PREFIX/$session.kitty-session"
    sed -i s#@@session-path@@#"$session_path"# "$SESSION_FILE_PREFIX/$session.kitty-session" 
    sed -i s#@@session@@#"$session"# "$SESSION_FILE_PREFIX/$session.kitty-session" 
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

log "Variables set: session=$session path=$session_path"

mkdir -p "$SESSION_FILE_PREFIX"

if [[ -f "$PERSISTENT_SESSION_STORAGE/$session.kitty-session" ]]; then
    SESSION_FILE_PREFIX="$PERSISTENT_SESSION_STORAGE"
elif [[ ! -f "$SESSION_FILE_PREFIX/$session.kitty-session" ]]; then
    create_session_file
fi


log "Opening:$SESSION_FILE_PREFIX/$session.kitty-session"
kitten @ action goto_session "$SESSION_FILE_PREFIX/$session.kitty-session"

# Focus the first tab
title=$(awk '/^new_tab/ {
    line = substr($0, 9);
    if (length(line) > 0) {
        first = substr(line, 1, 1);
        rest = substr(line, 2);
        gsub(/[[:space:]]/, "\\s", rest);
        print first rest;
    }
    exit
}' "$SESSION_FILE_PREFIX/$session.kitty-session")
log "title of focused tab:$title"
kitten @ focus-tab --match "title:$title"

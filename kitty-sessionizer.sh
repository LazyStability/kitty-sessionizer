#!/usr/bin/env bash

TS_SEARCH_PATHS=(/data/Software:1)
SESSION_FILE_PREFIX="$XDG_DATA_HOME/kitty-sessions"

find_dirs() {

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

SESSION_PATH=$(find_dirs | fzf --prompt "Switch to session > ")
SESSION=${SESSION_PATH#/data/Software/}

mkdir -p "$SESSION_FILE_PREFIX"

[[ ! -f "$SESSION_FILE_PREFIX/$SESSION.session" ]] && printf "%s\n"\
                                                        "cd $SESSION_PATH/$SESSION" \
                                                        "launch vim new_tab onefetch" \
                                                        "cd $SESSION_PATH/$SESSION" \
                                                        "launch --hold onefetch" \
                                                        "new_tab terminal" \
                                                        "cd $SESSION_PATH/$SESSION" \
                                                        "launch zsh" \
                                                        > "$SESSION_FILE_PREFIX/$SESSION.session"

kitten @ action goto_session "$SESSION_FILE_PREFIX/$SESSION.session"

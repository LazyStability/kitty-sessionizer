[This issue](https://github.com/kovidgoyal/kitty/issues/8911) motivated me to create a sessionizer similar to the [original](https://github.com/ThePrimeagen/tmux-sessionizer/tree/master).
This is for now a WIP.

The tools will look & create kitty-session files in two directories `XDG_DATA_HOME/kitty-sessions` and `/tmp/kitty-sessions`, with the first surviving reboot.
The sessions files in `XDG_DATA_HOME` will be prioritized.

# Requirements
- `fzf` installed
- kitty nightly, or build from source, later than commit `e1d8565fb68570113fef979a68ef70fbe99e67c0`
- A `default.kitty-session` in your kitty-sessionizer config directory
    - In it `@@session@@` and `@@session-path@@` files will be substituted.
    - Only use whitespaces and `-` as seperators in tab names

# Todo:
- [ ] Create a kitten based on the procedure
- [ ] Remove Code from the primeagen repo because of possible licensing issues 

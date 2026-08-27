#!/usr/bin/env bash
# tmux-flash trigger script — runs when the flash key is pressed in copy-mode.
#
# The trick that makes multi-character incremental search possible in tmux:
# tmux itself can only hand a script one keystroke at a time (command-prompt),
# so instead we swap a *replica pane* over the real one. The replica runs
# flash.py, which owns its own tty and can read keys in a loop. Meanwhile the
# original pane keeps its copy-mode state — scroll position and any active
# selection — completely untouched in a hidden window.
#
# Flow:
#   1. Snapshot the original pane: geometry, cursor, and visible text.
#   2. Spawn flash.py in a detached window, then swap it into our slot.
#   3. flash.py interacts with the user, then swaps itself back out and
#      moves the original pane's copy-mode cursor to the chosen target.
set -eu

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# One display-message round-trip for everything we need about the pane.
info="$(tmux display-message -p '#{pane_id};#{scroll_position};#{copy_cursor_x};#{copy_cursor_y};#{cursor_x};#{cursor_y};#{pane_width};#{pane_height};#{pane_in_mode}')"
IFS=';' read -r pane scroll copy_cx copy_cy pane_cx pane_cy w h inmode <<<"$info"

from_normal="$(tmux show-option -gqv '@flash-from-normal-mode')"
if [ "$inmode" = "1" ]; then
  cx="$copy_cx"
  cy="$copy_cy"
  enter_copy_mode=0
else
  [ "$from_normal" = "on" ] || exit 0
  scroll=0
  cx="$pane_cx"
  cy="$pane_cy"
  enter_copy_mode=1
fi

# Capture exactly the visible viewport. capture-pane line 0 is the top of the
# *unscrolled* screen, so when scrolled up by N the visible region is -N to
# (height - N - 1). Searching only what is on screen is deliberate: it mirrors
# flash.nvim and never trawls through scrollback.
start=$((0 - scroll))
end=$((h - scroll - 1))
cap="$(mktemp)"
tmux capture-pane -p -t "$pane" -S "$start" -E "$end" > "$cap"

labels="$(tmux show-option -gqv '@flash-labels')"

# Spawn the replica detached (-d) so it never becomes the current window on
# its own, and print (-P) its pane id so we can swap it into place.
replica="$(tmux new-window -dP -F '#{pane_id}' -n flash \
  "exec /usr/bin/env python3 '$DIR/flash.py' --orig '$pane' --capture '$cap' --cx '$cx' --cy '$cy' --width '$w' --height '$h' --labels '${labels:-asdfghjklqwertyuiopzxcvbnm}' --enter-copy-mode '$enter_copy_mode'")"

tmux swap-pane -s "$replica" -t "$pane"
tmux select-pane -t "$replica"

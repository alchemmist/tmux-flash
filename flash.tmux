#!/usr/bin/env bash
# tmux-flash TPM entry point.
#
# TPM executes every *.tmux file at the repo root when the plugin loads.
# All this does is bind the trigger key in copy-mode-vi; everything else
# happens in flash.sh / flash.py when the key is pressed.
#
# Options (set in tmux.conf before the plugin loads):
#   @flash-key     trigger key in copy-mode-vi  (default: s)
#   @flash-labels  jump label alphabet          (default: asdfghjklqwertyuiopzxcvbnm)

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

key="$(tmux show-option -gqv '@flash-key')"

tmux bind-key -T copy-mode-vi "${key:-s}" run-shell -b "$CURRENT_DIR/flash.sh"

# tmux-flash

[flash.nvim](https://github.com/folke/flash.nvim)-style navigation for tmux
copy-mode: incremental multi-character search over the **visible pane text**,
with jump labels. Type a few characters, matches narrow live, press the label
next to the one you want, and the copy-mode cursor jumps there — **extending
your selection if one is active**.

<!-- TODO: add screenshot / recording here -->


https://github.com/user-attachments/assets/58507484-3bcd-491c-b8d8-9e422079160d


## Why

flash.nvim's workflow in visual mode: start a selection with `v`, press
`s`, type a string, press the label — and your selection now ends exactly
where you wanted. Nothing in the tmux ecosystem replicated that:

- [tmux-jump](https://github.com/schasse/tmux-jump) only reads a **single**
  character (a limitation of `tmux command-prompt -1`, its input mechanism)
  and cancels copy-mode before jumping, destroying any active selection.
- [tmux-thumbs](https://github.com/fcsonline/tmux-thumbs) /
  [tmux-fingers](https://github.com/Morantron/tmux-fingers) hint pre-defined
  patterns (URLs, paths, hashes) for _copying_, not free-text _navigation_.
- tmux's built-in copy-mode search (`/`) searches the entire scrollback
  history, not just what you're looking at — and has no labels.

## How it works

tmux can't hand a script a live keystroke stream — `command-prompt` gives you
one key per invocation. tmux-flash gets around this with the replica-pane
technique (pioneered by tmux-fingers):

1. The trigger key runs [`flash.sh`](flash.sh), which snapshots the pane's
   visible text, geometry, cursor, and scroll position.
2. It spawns [`flash.py`](flash.py) in a detached window and `swap-pane`s it
   over the real pane. The replica owns its own tty, so it can read raw
   keystrokes in a loop and render matches/labels with ANSI styling. Your
   real pane sits untouched in the background window, still in copy-mode,
   selection and scroll intact.
3. When you pick a target, the replica swaps itself back out and positions
   the real pane's copy-mode cursor using plain cursor motions
   (`top-line` / `cursor-down` / `cursor-right`). Motions — unlike any kind
   of goto — **extend an active selection**, which is what makes the
   `v` → search → label workflow behave exactly like flash.nvim.

Behavior deliberately mirrors flash.nvim's defaults:

| flash.nvim                                        | tmux-flash |
| ------------------------------------------------- | ---------- |
| exact-match search mode                           | same       |
| smartcase (lowercase = insensitive)               | same       |
| labels shown from the first typed character       | same       |
| label drawn _after_ the match                     | same       |
| labels that could continue the search are skipped | same       |
| matches labeled nearest-to-cursor first           | same       |
| backdrop dimming                                  | same       |
| jump lands on match start                         | same       |

## Install

### TPM

```tmux
set -g @plugin 'AndreVicencio/tmux-flash'
```

Then `prefix + I` to install.

### Manual

```sh
git clone https://github.com/AndreVicencio/tmux-flash ~/.config/tmux/tmux-flash
```

```tmux
# in tmux.conf
run-shell ~/.config/tmux/tmux-flash/flash.tmux
```

## Usage

| Key               | Action                                    |
| ----------------- | ----------------------------------------- |
| `prefix + [`      | enter copy-mode (tmux built-in)           |
| `s`               | start flash search                        |
| _type characters_ | narrow matches live                       |
| _label key_       | jump to that match                        |
| `Enter`           | jump to the closest match                 |
| `Backspace`       | edit the pattern                          |
| `Esc` / `Ctrl-C`  | cancel, leaving copy-mode state untouched |

The selection workflow: `prefix + [` → `v` → `s` → type → label →
selection now spans from your anchor to the target → `y` to yank.

## Options

Set in `tmux.conf` (defaults shown):

```tmux
set -g @flash-key 's'                            # trigger key in copy-mode-vi
set -g @flash-labels 'asdfghjklqwertyuiopzxcvbnm' # label alphabet, in order
set -g @flash-from-normal-mode 'off'              # allow triggering before copy-mode
```

With `@flash-from-normal-mode` set to `on`, the trigger may run directly from
normal mode. The search only captures the visible viewport. Choosing a target
enters copy-mode and moves its cursor there; cancelling leaves copy-mode off.

## Requirements

- tmux ≥ 3.1 (needs the `copy_cursor_x/y` formats; developed and tested on 3.6)
- Python 3 (preinstalled on macOS with the developer tools, and on
  effectively every Linux distro — no third-party packages used)
- `mode-keys vi` (`set-window-option -g mode-keys vi`) — the binding lives in
  the `copy-mode-vi` key table

**No dependency on any other tmux plugin.** TPM is optional (see manual
install). Coexists happily with tmux-yank, vim-tmux-navigator, catppuccin,
resurrect/continuum, etc.

## Limitations

- Searches the visible viewport only — by design, like flash.nvim's current
  window. Scroll first, then flash.
- While the search is active, a transient window named `flash` exists in the
  session (the hidden half of the pane swap). It disappears the moment the
  search ends.
- On lines containing double-width characters (CJK), the label may render
  visually shifted; the jump itself still lands on the correct character.

## Credits

- [flash.nvim](https://github.com/folke/flash.nvim) by @folke — the behavior
  this plugin mirrors.
- [tmux-fingers](https://github.com/Morantron/tmux-fingers) — origin of the
  replica-pane technique.

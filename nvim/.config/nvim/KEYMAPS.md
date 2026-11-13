# Neovim keymap cheatsheet

Leader = Space (also local leader). Keys are case-sensitive.
N = Normal, V = Visual including Select, X = Visual only, I = Insert,
T = Terminal. Ctrl and Shift are written C- and S-.
This lists active custom mappings and explicit plugin keymap overrides;
plugins and Neovim also supply defaults, which are not exhaustively listed.

## Open this reference

| Keys | Mode | Action |
| --- | --- | --- |
| Space ? | N | Open/focus this cheatsheet in a floating window |
| q / Esc | N, cheatsheet | Close the float and return to editing |

Use normal scrolling (j/k, Ctrl-d/u, gg/G) and / to search in the float.
The document is a read-only snapshot; reopen it after editing KEYMAPS.md.

## Files, search and buffers

| Keys | Mode | Action |
| --- | --- | --- |
| sf | N | Open Oil file explorer in a float |
| h | N, Oil | Go to parent directory |
| q | N, Oil | Close explorer |
| ;f | N | Find files, including hidden files |
| ;r | N | Live grep, including hidden files |
| ;; | N | Resume last picker |
| ;b | N | Pick buffer; jump to its existing window/tab if visible |
| ;e | N | Pick diagnostics |
| ;c | N | Pick incoming LSP calls |
| ;n | N | Notification history |
| Space bd | N | Delete hidden listed buffers; skip unsaved buffers |
| Space yf | N | Copy path relative to current directory plus #Lline to clipboard |
| Space yp | N | Copy absolute path plus #Lline to clipboard |
| Space cc | V | Copy selected lines as fenced code with filename and line metadata |

## Tabs and windows

| Keys | Mode | Action |
| --- | --- | --- |
| te | N | Open a new empty tab |
| Tab / S-Tab | N | Next / previous tab |
| ss / sv | N | Horizontal / vertical split |
| sh / sj / sk / sl | N | Focus left / below / above / right window |
| C-m | N | Jump forward in jumplist (built-in C-i behavior) |

C-m may also be sent by Enter, depending on the terminal keyboard protocol.
Tab replaces the usual C-i jumplist shortcut when those keys are indistinguishable.

## Editing and registers

| Keys | Mode | Action |
| --- | --- | --- |
| x | N | Delete character without changing registers |
| Space p / Space P | N | Paste last yank (register 0) after / before cursor |
| Space p | V | Replace selection with last yank (register 0) |
| Space c / Space d | N, V | Change / delete via black-hole register; in N, follow with a motion |
| Space C / Space D | N, V | Black-hole variants of C / D |
| + / - | N | Increment / decrement number |
| dw | N | Delete backward using vb then black-hole delete (overrides normal dw) |
| C-a | N | Select entire buffer linewise |
| Space o / Space O | N | Open line below / above, clear auto-inserted text, enter Insert mode |

Some short leader mappings are also prefixes: Space c (ca, cc, cr, cR, cl)
and Space d (debug and CodeDiff shortcuts). Neovim waits for a possible longer
mapping; pause for the short action or complete the longer sequence promptly.

## Language tools and diagnostics

| Keys | Mode | Action |
| --- | --- | --- |
| gd | N | Definition picker; do not reuse an existing target window |
| gD | N | Declaration picker |
| gy | N | Type definition picker |
| grr | N | References picker |
| gI | N | TypeScript source definition with vtsls; otherwise LSP implementation |
| K | N | Hover documentation |
| gK | N | Signature help |
| C-k | I | Signature help |
| C-j | N | Next diagnostic, with floating details |
| Space ca | N, X | Code action |
| Space cr | N | Rename symbol |
| Space cR | N | Rename file through Snacks |
| Space cl | N | LSP configuration picker |
| Space f | N, X | Format via Conform (Visual selection when supported) |
| ]] / [[ | N, T | Next / previous highlighted reference; accepts count |
| Space i | N | Currently does nothing; inlay hint toggle is commented out |

LSP actions require a suitable attached language server. Formatting also runs
on save; :ToggleFormatter toggles save formatting for the current buffer.

## Git and diffs

| Keys | Mode | Action |
| --- | --- | --- |
| ;g | N | Open Lazygit; selected files return to the launching pane |
| ;h | N | Pick Git diff hunks |
| Space gb | N | Blame current line |
| Space gB | N | Blame buffer |
| Space go | N | Open file at current line's blamed commit in a new tab |
| Space gs | N | Stage buffer when unstaged hunks exist; otherwise unstage buffer |
| Space gh | N | Stage/unstage current hunk |
| Space gd | N | Toggle MiniDiff overlay |
| ]c / [c | N | Next / previous MiniDiff hunk (also used by CodeDiff defaults) |
| Space dv | N | Toggle CodeDiff |
| Space dh | N | CodeDiff history for current file |
| Space dH | N | CodeDiff repository history |

## Debugging (.NET adapter configured)

| Keys | Mode | Action |
| --- | --- | --- |
| F5 | N | Start / continue debugging |
| F10 | N | Step over |
| F11 | N | Step into |
| F12 | N | Step out |
| Space db | N | Toggle breakpoint |
| Space dB | N | Set conditional breakpoint (prompts for condition) |
| Space dq | N | Terminate debug session |
| Space dr | N | Toggle debug REPL |
| Space du | N | Toggle debug UI |

Debug UI also opens/closes with the session. netcoredbg must be on PATH.
:EasyDotnet initializes optional project tooling; then use :Dotnet.

## Completion and contextual mappings

| Keys / setting | Context | Action |
| --- | --- | --- |
| C-y | Insert completion | Select and accept completion (explicit override) |
| enter preset | Blink completion | Uses Blink's Enter-oriented preset |
| cmdline preset | Command line | Uses Blink's command-line preset |
| Left / Right | Command line | Blink mappings disabled; retain cursor movement |
| q / Esc | package.json helper float | Close helper float (no global opener key is configured) |

mini.pairs is enabled in Insert and command-line modes, with its default pair
mappings. Oil, Snacks pickers, CodeDiff, MiniDiff, gitlinker and other plugins
retain additional defaults. To inspect the current effective mapping, use
:verbose nmap <keys>, :verbose xmap <keys>, or :verbose imap <keys>.
For example: :verbose nmap <Space>ca.

## Sources and maintenance

Review these files when updating this document:

- lua/vicmartos/config/keymaps.lua: core editing and cheatsheet shortcut.
- lua/vicmartos/plugins/keymaps.lua: navigation, LSP, Git and diff shortcuts.
- lua/vicmartos/plugins/dotnet.lua: debugger mappings.
- lua/vicmartos/plugins/editor.lua: completion presets and MiniDiff overrides.
- lua/vicmartos/plugins/util.lua: Oil overrides.
- lua/vicmartos/utils/editor.lua: contextual helper mappings.

Space yf uses the current working directory, rather than detected project root.
There is no custom ZR restart mapping in this configuration.

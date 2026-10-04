# Neovim config

Neovim config (0.12+) managed with the built-in `vim.pack` plugin manager. No
plugin-manager wrapper, no mason: native LSP, mini.nvim UI modules, and a small
set of focused plugins.

## Overview

- **Leader**: `<Space>`
- **Colorscheme**: follows the active Omarchy theme; Kanagawa Wave is the fallback
- **Plugins**: `vim.pack` + lockfile (`nvim-pack-lock.json`)
- **LSP**: native `vim.lsp` (`lua_ls`, `roslyn_ls`)
- **Completion**: mini.completion + native cmdline autocompletion
- **Git**: fugitive (status/blame) + mini.diff (hunk signs) + diffs.nvim
- **Pickers**: fzf-lua (including `vim.ui.select`; `<leader>fz` opens its picker menu)
- **Sessions**: servery.nvim lists running sessions and folders under `~/personal`, `~/work`, `~/Work`, and `~/git`

## Plugins

| Plugin | Role |
|--------|------|
| Omarchy theme plugins | Aether, Kanagawa, and Tokyo Night |
| `rebelot/kanagawa.nvim` | Kanagawa Wave fallback outside Omarchy or after an error |
| `nvim-mini/mini.nvim` | icons, ai, surround, completion, diff, jump, jump2d, statusline, files |
| `tpope/vim-fugitive` | Git client (`:Git`, blame, etc.) |
| `ibhagwan/fzf-lua` | Default picker (ivy layout and `vim.ui.select`) |
| `wurli/servery.nvim` | Switch between persistent Neovim project sessions |
| `brianhuster/live-preview.nvim` | Live browser preview for Markdown, including Mermaid diagrams and KaTeX math |
| `barrettruth/diffs.nvim` | Diff views (Fugitive integration) |
| `nvim-treesitter/nvim-treesitter` (`main`) | Highlighting + indent |
| `neovim/nvim-lspconfig` | Maintained native LSP configurations, including `roslyn_ls` |
| `vim-test/vim-test` | Runs `dotnet test` in a terminal split (`:TestNearest` / `:TestLast` / `:TestSuite`) |
| `GustavEikaas/easy-dotnet.nvim` | Optional on-demand .NET commands, test runner UI, and test debugging |
| `mfussenegger/nvim-dap` | Debug adapter protocol client |
| `rcarriga/nvim-dap-ui` (+ `nvim-neotest/nvim-nio`) | Debug UI (nvim-nio is a dap-ui dependency) |
| `nvim-lua/plenary.nvim` | Lua library (easy-dotnet dependency) |

Manage plugins with `:lua vim.pack.update()` (review the update buffer, `:w` to
confirm) and `:lua vim.pack.del({ "name" })`. Offline inspect:
`:lua vim.pack.update(nil, { offline = true })`. Commit `nvim-pack-lock.json`
for reproducible setups.

On Omarchy 4, Neovim reads the active theme from
`~/.local/state/omarchy/current/theme/neovim.lua`. Open instances watch for
theme changes and apply the theme automatically. Aether keeps the generated
palette for Ethereal, Last Horizon, Lupine, Miasma, Ristretto, Vantablack, and
White. Kanagawa and Tokyo Night keep their own plugins. Other stock themes
use Neovim or mini.nvim colorschemes:

| Omarchy theme | Neovim colorscheme |
|---------------|--------------------|
| Catppuccin / Catppuccin Latte | `catppuccin` (dark / light) |
| Everforest / Lumon / Nord | `miniwinter` |
| Flexoki Light | `retrobox` (light) |
| Gruvbox | `retrobox` (dark) |
| Hackerman | `elflord` |
| Matte Black | `unokai` |
| Osaka Jade | `minispring` |
| Retro 82 | `minischeme` |
| Rosé Pine | `catppuccin` (light) |
| Solitude | `default` (dark) |

Omarchy's `mode` sets Neovim's `background` before the colorscheme loads.
Run `:OmarchyThemeReload` to force a refresh.

## Structure

```
init.lua                -- leader, vim.loader, module load order
after/lsp/
  roslyn_ls.lua         -- local Roslyn settings layered on nvim-lspconfig
lua/
  omarchy_theme.lua     -- vim.pack adapter and live Omarchy theme reload
  options.lua           -- defaults, true color, wildmode/pum, rg grepprg
  keymaps.lua           -- general keymaps
  herdr_review.lua      -- send line-referenced comments to a Herdr agent
  autocmds.lua          -- yank highlight, restore cursor
  cmdline.lua           -- cmdline autocompletion, fuzzy :find, live :Grep
  diagnostics.lua       -- diagnostic UI
  pack.lua              -- vim.pack hooks (TSUpdate on treesitter install/update)
  plugins/init.lua      -- ordered plugin loader
  plugins/*.lua         -- plugin setup and focused integrations, including nb
  formatting.lua        -- diff-based stylua formatting, else one selected LSP formatter
  lsp.lua               -- vim.lsp.enable
```

Each plugin module owns install, setup, and its keymaps. `init.lua` stays a
short explicit load order.

## Keymaps

| Key | Action |
|-----|--------|
| `<leader>ff` / `<leader>fg` / `<leader>fb` | fzf-lua: files (including dotfiles) / live ripgrep (including dotfiles) / buffers |
| `<leader>fh` / `<leader>fr` | fzf-lua: help / resume |
| `<leader>fz` | fzf-lua: choose an internal picker |
| `<leader>mp` / `<leader>ms` | Start / stop the live Markdown preview |
| `<leader>mf` | fzf-lua: choose a file to preview |
| `<leader>nn` / `<leader>np` / `<leader>na` | nb: create a general / project / area note in the current primary notebook |
| `<leader>nd` | nb: create or open today's note in `daily` |
| `<leader>nf` / `<leader>ns` / `<leader>nt` | nb-fzf: find notes / search contents / filter by tags |
| `<leader>nx` | nb-fzf: find exact `#next` lines and jump to the selected match |
| `<leader>ni` | nb-fzf: pick a note and insert a labeled nb wiki link |
| `<leader>ng` | nb: open the wiki link under the cursor |
| `<leader>e` / `<leader>E` | mini.files: current path / project root |
| `<leader>gg` | fugitive `:Git` status |
| `<leader>gf` | fzf-lua: changed files from Git status |
| `<leader>gr` | diffs.nvim: review repository changes against `HEAD` |
| `<leader>pp` | servery.nvim: switch Neovim session |
| `<leader>ac` | Insert a file/line review comment into the nearest Herdr agent's input (normal or visual mode) |
| `[h` / `]h` | mini.diff: prev / next hunk |
| `[H` / `]H` | mini.diff: first / last hunk |
| `gh` / `gH` | mini.diff: apply / reset hunk (`gh` also textobject) |
| `sa` / `sd` / `sr` | mini.surround: add / delete / replace |
| `<CR>` | mini.jump2d: jump within visible lines |
| `grd` | go to definition |
| `<leader>ld` | diagnostics → quickfix |
| `<Esc>` | clear search highlights |
| `<C-h/j/k/l>` | window navigation |
| `<Esc><Esc>` (terminal) | exit terminal mode |
| `<F5>` / `<F10>` / `<F11>` / `<F12>` | debug: continue / step over / into / out |
| `<leader>b` / `<leader>B` | debug: toggle / conditional breakpoint |
| `<leader>dq` / `<leader>dr` / `<leader>du` | debug: terminate / REPL / toggle UI |
| `<leader>tr` / `<leader>tl` / `<leader>ts` | vim-test: run nearest / last / suite (`dotnet test` in a terminal split) |
| `<leader>tt` | easy-dotnet: initialize if needed and toggle the testrunner |
| `<leader>td` | easy-dotnet: debug test under cursor (C# test buffers, after init) |

Run `:EasyDotnet` (or press `<leader>tt`) only when you want easy-dotnet's
optional workflow. It initializes the plugin without starting its LSP; test
discovery starts with the testrunner. Inside the testrunner: `r` run, `d`
debug, `R` run all, `p` peek stacktrace, `gf` go to source, `]f`/`[f`
next/prev failing test, `q` close. vim-test's `<leader>td` equivalent does not
exist: debugging tests always goes through easy-dotnet.

Stock Neovim LSP/diagnostic defaults still apply: `grn`, `grr`, `gri`, `gra`,
`gO`, `K`, `[d` `]d`, `[q` `]q`. `mini.jump` extends `f`/`F`/`t`/`T` across
lines; `mini.ai` adds textobjects; `mini.completion` handles insert completion
and signature help.

## Project sessions and Git review

`<leader>pp` lists running Neovim sessions and immediate, non-hidden project
folders under `~/personal`, `~/work`, `~/Work`, and `~/git`. Missing roots are
ignored. A folder with an active session may appear twice. `<Enter>` switches
without closing the previous session. In the picker, `<C-x>` closes the selected
session; servery refuses to close one with unsaved file changes.
With the pinned servery release, direct `:Sv /path` currently stops the old
session; use `<leader>pp` to keep it open.

After switching, `<leader>ff` searches files and `<leader>E` opens the file
explorer in the current project. `<leader>gf` picks changed files from Git
status. `<leader>gr` opens a full repository review against `HEAD`, including
staged, unstaged, and untracked changes, without needing a remote default
branch. The review's `gs` toggles the selected file between the full diff and
a side-by-side view; `:cnext` / `:cprev` move between changed files.

`<leader>ac` requires Neovim to run inside Herdr with the `herdr` CLI available.
It targets an agent in the same tab first, or another tab in the same workspace;
when several qualify, choose one from the picker. In Fugitive's `:Git` status,
place the cursor on a file entry to reference the whole file without line or
stage details. To comment on specific lines, expand the file's inline diff with
`=` and place the cursor on a code line (or select code lines). Deleted lines
are labeled as old-side references. The comment is inserted into the agent's
input without submitting it; review and submit it manually in the agent UI.

## Notes and tasks

Notes are stored in independent nb notebooks. A personal computer normally has
`personal` and `daily`; a work computer normally has `work` and `daily`.
General notes live at the primary notebook root, projects and areas use their
matching subfolders, and daily notes use `YYYY-MM-DD.md`. The same `nb-fzf`
backend powers terminal fzf and fzf-lua, so selections made in Neovim open in
the current instance. Creation follows `nb use personal` or `nb use work`;
combined searches cover whichever configured notebooks exist on the machine.

Projects require `#projects/<name>`, areas require `#areas/<name>`, and an exact
`#next` token marks a line for the next-actions picker. There is intentionally
no agenda or due-date processing.

## Markdown preview

Open a Markdown file and press `<leader>mp` (`:LivePreview start`) to preview it
in your default browser. The preview updates as you type and scrolls with the
editor. Fenced `mermaid` blocks render as diagrams without additional setup.
Press `<leader>ms` (`:LivePreview close`) to stop the server, or `<leader>mf`
(`:LivePreview pick`) to choose a file with fzf-lua. HTML, AsciiDoc and SVG are
also supported.

The server uses `127.0.0.1:5500` by default. If another Neovim instance is already
previewing on that port, stop its preview first or set a different port with
`:lua LivePreview.config.port = 5501`. No Node.js or build step is required.

## Cmdline

Native cmdline autocompletion (Neovim 0.12+):

- Popup suggestions while typing on `:`, `/`, and `?` (`Tab` / `<C-n>` / `<C-p>` to cycle)
- **`:find <query>`** — fuzzy file picker over `rg --files` (`findfunc` + cache)
- **`:Grep <pattern>`** — live ripgrep results as you type (after 2 chars, including multiword patterns)

Requires `rg` on `PATH` for `:Grep` / `grepprg`.

## Treesitter parsers

Installed by default: `lua`, `c_sharp`, `json`, `markdown`, `markdown_inline`,
`query`, `vim`, `vimdoc`. Others install on demand when a matching filetype is
opened (if available).

## System dependencies

| Tool | Used for |
|------|----------|
| `git` | fugitive, mini.diff, vim.pack |
| `fzf` | fzf-lua |
| `rg` | grepprg, `:Grep`, pickers |
| `nb` | Markdown notebooks, local Git history, search, tags, and editing |
| `nb-fzf` | Shared Bash/fzf and fzf-lua note workflow (provided by this repo) |
| `stylua` | Lua format on save |
| `lua-language-server` | Lua LSP |
| .NET SDK | Roslyn and `dotnet test` (vim-test, easy-dotnet) |
| `roslyn-language-server` | C# LSP (`dotnet tool install --global roslyn-language-server --prerelease`) |
| `netcoredbg` | DAP debugging of .NET tests via easy-dotnet (`yay -S netcoredbg` on Arch/Omarchy) |
| `EasyDotnet` global tool | Optional easy-dotnet workflow (`dotnet tool install -g EasyDotnet`) |

`nvim-lspconfig` supplies the `roslyn_ls` configuration but does not install
the Roslyn language-server executable. `netcoredbg` must be on `PATH` before
using `<leader>td`. The standalone `roslyn_ls` setup supports C#; Razor/CSHTML
support previously supplied by easy-dotnet is intentionally not enabled.

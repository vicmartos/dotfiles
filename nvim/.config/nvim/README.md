# Neovim

Neovim 0.12+ configuration adapted from craftzdog/dotfiles commit
420d5ad8e8d583396eb318fa4e4f4d608614dc96.
Reference: https://www.devas.life/effective-neovim-setup-for-agentic-coding-towards-2027/

GNU Stow installs this directory as ~/.config/nvim. Lua modules live under
lua/vicmartos: config contains core settings, plugins contains setup groups
and centralized mappings, utils contains shared helpers. after/lsp contains
native server overrides. All plugins are declared in plugins/init.lua.

## Dependencies

Neovim, Git, tree-sitter CLI, C compiler, curl, tar, Node/npm, ripgrep, fd,
lazygit, delta, a Nerd Font, and a working clipboard provider (wl-clipboard
on Wayland). Mason installs language servers and formatters without automatic
updates. Run :Mason to inspect installation progress.

.NET requires dotnet, roslyn-language-server, netcoredbg and the EasyDotnet
global tool on PATH. Roslyn is the only C# server; easy-dotnet starts on demand.

## Keys

Space is leader. ;f files, ;r grep, ;; resume, sf Oil, ;g Lazygit.
gd definition, grr references, K hover, Space ca code actions, Space cr rename.
Space f formats; :ToggleFormatter toggles buffer save formatting.
Space dv CodeDiff, Space dh file history, Space gd diff overlay.
Space yf copies relative file/line, Space yp absolute file/line.
Space ? opens the [full keymap cheatsheet](KEYMAPS.md) in a floating window;
q or Esc closes it. Scroll normally and use / to search.

.NET: :EasyDotnet initializes project tooling; use :Dotnet for commands.
F5 continues, F10 steps over, F11 steps in, F12 steps out.
Space db breakpoint, dB conditional breakpoint, dq terminate, dr REPL, du debug UI.

## Local adaptations

Namespace vicmartos/Vicmartos; Solarized Osaka vivid with transparency.
No Copilot or Omarchy theme following. No nb, Herdr, session manager or Markdown
preview integration. .NET retained with Snacks selection and C# parsing.
Lazygit commands use POSIX shell syntax. CSS server is provisioned; unprovisioned
GLSL server disabled. Current upstream behavior takes precedence over the article.

## Updates and rollback

Use :lua vim.pack.update(), review changes and save the update buffer to accept.
Track nvim-pack-lock.json. Review Mason upgrades manually. The original config
is saved at /tmp/nvim-migration-backup/original; runtime backups are timestamped
alongside their original directories. Copy the saved config back into this Stow
package and restore matching runtime backups to roll back. Keep a durable copy
of backups before reboot because /tmp may be cleared.

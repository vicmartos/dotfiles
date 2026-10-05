(setenv "LSP_USE_PLISTS" "true")
(setq inhibit-startup-screen t)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))
(tool-bar-mode -1)
(tooltip-mode -1)

;;; Set paths for both Emacs and its child processes.  GUI Emacs does not
;;; source .bashrc, where the user-installed .NET SDK is normally selected.
(let ((dotnet-root (expand-file-name "~/.dotnet")))
  (when (file-executable-p (expand-file-name "dotnet" dotnet-root))
    (setenv "DOTNET_ROOT" dotnet-root)))
(dolist (directory '("~/.dotnet" "~/.dotnet/tools" "~/.local/bin" "~/.opencode/bin"))
  (let ((expanded (expand-file-name directory)))
    (when (file-directory-p expanded)
      (add-to-list 'exec-path expanded)
      (setenv "PATH" (concat expanded path-separator (getenv "PATH"))))))

(let ((script (expand-file-name "~/.local/bin/init-emacs-env.sh")))
  (when (file-executable-p script)
    (dolist (line (split-string (shell-command-to-string script) "\n" t))
      (when (string-match "\\`env:\\([^=]+\\)=\\(.*\\)\\'" line)
        (setenv (match-string 1 line) (match-string 2 line))))))

;;; Performance: assume left-to-right text everywhere and skip bidirectional
;;; parenthesis algorithm — avoids unnecessary work on every redisplay cycle
;;; when you don't edit right-to-left languages
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

;;; Garbage collector — moderate threshold to avoid long GC pauses
;;; while keeping memory from growing unbounded
(setq gc-cons-threshold (* 20 1024 1024)
      gc-cons-percentage 0.1)

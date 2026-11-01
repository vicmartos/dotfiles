;;; my-omarchy-theme.el --- Omarchy 4 theme sync -*- lexical-binding: t; -*-

;; This integration intentionally loads only the theme-related pieces of the
;; omarchy-emacs package.  Its main omarchy.el also changes fonts, shells,
;; server startup, and save hooks, which are owned by this Emacs config.

(require 'cl-lib)
(require 'filenotify)
(require 'subr-x)

(defconst my/omarchy-current-directory
  (expand-file-name "~/.local/state/omarchy/current")
  "Directory containing Omarchy 4's active theme state.")

(defconst my/omarchy-theme-directory
  (expand-file-name "theme" my/omarchy-current-directory)
  "Directory containing the active Omarchy 4 theme assets.")

(defconst my/omarchy-theme-name-file
  (expand-file-name "theme.name" my/omarchy-current-directory)
  "Omarchy 4 file watched for theme changes.")

(defconst my/omarchy-package-theme-file
  "/usr/share/omarchy-emacs/config/themes/omarchy-theme.el"
  "Theme definition supplied by the omarchy-emacs package.")

(defconst my/omarchy-package-template-file
  "/usr/share/omarchy-emacs/omarchy-colors.el.tpl"
  "Color template supplied by the omarchy-emacs package.")

(defconst my/omarchy-user-template-file
  (expand-file-name "~/.config/omarchy/themed/omarchy-colors.el.tpl")
  "Color template rendered by Omarchy when its theme changes.")

(defconst my/omarchy-generated-colors-file
  (expand-file-name "omarchy-colors.el" my/omarchy-theme-directory)
  "Generated Elisp color definitions for the active Omarchy theme.")

(defconst my/omarchy-theme-hook-source
  (locate-user-emacs-file "etc/omarchy-emacs")
  "Tracked theme-only Omarchy hook installed into the user hook directory.")

(defconst my/omarchy-theme-hook-target
  (expand-file-name "~/.config/omarchy/hooks/theme-set.d/omarchy-emacs")
  "Installed theme-only hook used by Omarchy 4.")

(defconst my/omarchy-font-hook-target
  (expand-file-name "~/.config/omarchy/hooks/font-set.d/omarchy-emacs")
  "Full-integration font hook installed by omarchy-emacs.")

(defvar my/omarchy--theme-watch nil
  "File notification descriptor for Omarchy theme changes.")

(defun my/omarchy--file-contents (file)
  "Return FILE's literal contents, or nil when it cannot be read."
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents-literally file)
      (buffer-string))))

(defun my/omarchy-theme-sync-available-p ()
  "Return non-nil when the Omarchy 4 theme integration is available."
  (and (file-directory-p "/usr/share/omarchy")
       (file-readable-p my/omarchy-theme-name-file)
       (file-readable-p
        (expand-file-name "colors.toml" my/omarchy-theme-directory))
       (file-readable-p my/omarchy-package-theme-file)
       (file-readable-p my/omarchy-package-template-file)
       (executable-find "omarchy-theme-color")
       (executable-find "omarchy")))

(defun my/omarchy--render-colors ()
  "Render the active Omarchy palette as Elisp color definitions."
  (let ((colors-file (expand-file-name "colors.toml"
                                       my/omarchy-theme-directory)))
    (when (and (file-readable-p colors-file)
               (file-readable-p my/omarchy-user-template-file)
               (file-writable-p my/omarchy-theme-directory))
      (let ((table
             (with-temp-buffer
               (when (zerop
                      (call-process "omarchy-theme-color" nil t nil
                                    "--file" colors-file "--all"))
                 (split-string (buffer-string) "\n" t)))))
        (when table
          (with-temp-buffer
            (insert-file-contents my/omarchy-user-template-file)
            (dolist (row table)
              (pcase-let ((`(,key ,value . ,_)
                           (split-string row "\t")))
                (when (and key value)
                  (goto-char (point-min))
                  (while (search-forward (format "{{ %s }}" key) nil t)
                    (replace-match value t t)))))
            (write-region (point-min) (point-max)
                          my/omarchy-generated-colors-file nil 'quiet))
          t)))))

(defun my/omarchy--sync-color-template ()
  "Install the packaged color template and render it when needed."
  (let* ((packaged (my/omarchy--file-contents
                    my/omarchy-package-template-file))
         (current (my/omarchy--file-contents
                   my/omarchy-user-template-file))
         (template-changed (not (equal packaged current))))
    (when template-changed
      (make-directory (file-name-directory my/omarchy-user-template-file) t)
      (copy-file my/omarchy-package-template-file
                 my/omarchy-user-template-file t))
    (when (or template-changed
              (not (file-readable-p my/omarchy-generated-colors-file)))
      (unless (my/omarchy--render-colors)
        (error "Could not render the current Omarchy colors")))))

(defun my/omarchy-apply-theme ()
  "Load the active Omarchy colors and apply its packaged Emacs theme."
  (interactive)
  (if (not (file-readable-p my/omarchy-generated-colors-file))
      (message "Omarchy colors are unavailable; keeping the current theme")
    (unwind-protect
        (progn
          ;; Semantic colors may be absent from older third-party theme
          ;; palettes. Clear their previous values before loading the newly
          ;; generated file.
          (dolist (symbol '(omarchy-color-muted omarchy-color-selection
                            omarchy-color-dark-fg omarchy-color-light-fg
                            omarchy-color-bright-fg omarchy-color-dark-bg
                            omarchy-color-darker-bg omarchy-color-lighter-bg
                            omarchy-color-orange))
            (makunbound symbol))
          (load-file my/omarchy-generated-colors-file)
          (when (memq 'omarchy custom-enabled-themes)
            (disable-theme 'omarchy))
          (put 'omarchy 'theme-settings nil)
          (setq custom-known-themes
                (delq 'omarchy custom-known-themes))
          (load-file my/omarchy-package-theme-file)
          (enable-theme 'omarchy))
      ;; Reapply the graphical font specs after loading the color theme.
      ;; Never copy the selected frame's attributes into global defaults:
      ;; a daemon's terminal frame has a font height of 1.
      (when (and (bound-and-true-p fontaine-current-preset)
                 (fboundp 'fontaine-set-preset))
        (fontaine-set-preset fontaine-current-preset)))
    t))

(defun my/omarchy--managed-hook-p (file)
  "Return non-nil when FILE is managed by this config or omarchy-emacs."
  (let ((contents (my/omarchy--file-contents file)))
    (and contents
         (or (string-match-p "my-dotfiles:managed" contents)
             (string-match-p "omarchy-emacs:managed" contents)))))

(defun my/omarchy--install-theme-hook ()
  "Install the tracked theme hook without overwriting custom hooks."
  (when (file-readable-p my/omarchy-theme-hook-source)
    (if (and (file-exists-p my/omarchy-theme-hook-target)
             (not (my/omarchy--managed-hook-p
                   my/omarchy-theme-hook-target)))
        (message "Custom Omarchy Emacs theme hook found; leaving it unchanged")
      (unless (equal (my/omarchy--file-contents my/omarchy-theme-hook-source)
                     (my/omarchy--file-contents my/omarchy-theme-hook-target))
        (unless (zerop (call-process "omarchy" nil nil nil
                                     "hook" "install" "theme-set"
                                     my/omarchy-theme-hook-source))
          (error "Could not install the Omarchy Emacs theme hook"))))))

(defun my/omarchy--remove-package-font-hook ()
  "Remove omarchy-emacs' managed font hook, preserving custom hooks."
  (when (and (file-exists-p my/omarchy-font-hook-target)
             (let ((contents
                    (my/omarchy--file-contents my/omarchy-font-hook-target)))
               (and contents
                    (string-match-p "omarchy-emacs:managed" contents))))
    (delete-file my/omarchy-font-hook-target)))

(defun my/omarchy--watch-theme ()
  "Watch Omarchy 4's theme name and reload the theme after changes."
  (when my/omarchy--theme-watch
    (ignore-errors (file-notify-rm-watch my/omarchy--theme-watch)))
  (setq my/omarchy--theme-watch
        (file-notify-add-watch
         my/omarchy-theme-name-file '(change)
         (lambda (_event)
           (condition-case error-data
               (my/omarchy-apply-theme)
             (error
              (message "Could not reload Omarchy theme: %s"
                       (error-message-string error-data))))))))

(defun my/omarchy-theme-sync-enable ()
  "Enable theme-only synchronization with Omarchy 4.
Return non-nil when the integration was enabled successfully."
  (when (my/omarchy-theme-sync-available-p)
    (condition-case error-data
        (progn
          (my/omarchy--sync-color-template)
          (unless (my/omarchy-apply-theme)
            (error "Could not apply the current Omarchy theme"))
          ;; Hook maintenance and file notifications make live updates more
          ;; reliable, but neither should prevent the current palette from
          ;; loading successfully at startup.
          (dolist (operation
                   '(("install theme hook" . my/omarchy--install-theme-hook)
                     ("remove font hook" . my/omarchy--remove-package-font-hook)
                     ("watch theme file" . my/omarchy--watch-theme)))
            (condition-case operation-error
                (funcall (cdr operation))
              (error
               (message "Could not %s: %s"
                        (car operation)
                        (error-message-string operation-error)))))
          t)
      (error
       (message "Omarchy theme sync disabled: %s"
                (error-message-string error-data))
       nil))))

(provide 'my-omarchy-theme)
;;; my-omarchy-theme.el ends here

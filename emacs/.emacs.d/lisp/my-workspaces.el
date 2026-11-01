;;; my-workspaces.el --- Shared workspaces and buffer selection -*- lexical-binding: t; -*-

(require 'persp-mode)
(require 'project)
(require 'seq)

(defun my/persp-terminal-frame-p (frame)
  "Return non-nil when FRAME should be excluded from workspaces."
  (not (display-graphic-p frame)))

;; Install before enabling persp-mode, including for standalone `emacs -nw'.
;; Its frame filter also prevents terminal clients from triggering autoresume.
(add-hook 'persp-filter-frame-functions #'my/persp-terminal-frame-p)

(defun my/persp-read-buffer-in-gui (original &rest args)
  "Use ORIGINAL for GUI frames and ordinary buffer reading in terminals."
  (if (display-graphic-p)
      (apply original args)
    (let ((read-buffer-function persp-saved-read-buffer-function))
      (apply #'read-buffer (seq-take args 4)))))

;; persp-mode's read-buffer-function is global, even on excluded frames.
(advice-add 'persp-read-buffer :around #'my/persp-read-buffer-in-gui)

(defun my/switch-to-buffer ()
  "Switch workspace buffers in the GUI, or project buffers in a terminal."
  (interactive)
  (call-interactively
   (if (display-graphic-p)
       #'persp-switch-to-buffer
     (if (project-current nil) #'consult-project-buffer #'consult-buffer))))

(defun my/list-buffers ()
  "List workspace buffers in the GUI, or project buffers in a terminal."
  (interactive)
  (call-interactively
   (if (display-graphic-p)
       #'my/persp-list-buffers
     (if (project-current nil) #'project-list-buffers #'list-buffers))))

(defun my/add-or-switch-buffer ()
  "Add a workspace buffer in the GUI, or select any buffer in a terminal."
  (interactive)
  (call-interactively
   (if (display-graphic-p) #'persp-add-buffer #'consult-buffer)))

(defun my/kill-buffer ()
  "Kill or detach a workspace buffer in the GUI; kill normally in a terminal."
  (interactive)
  (call-interactively
   (if (display-graphic-p) #'persp-kill-buffer #'kill-buffer)))

(defun my/initial-buffer ()
  "Open the invoking directory in terminal frames, or scratch in GUI frames."
  (if (display-graphic-p)
      (get-scratch-buffer-create)
    (dired-noselect default-directory)))

;; emacsclient calls this with the invoking shell's default-directory.
;; Explicit file arguments take precedence over initial-buffer-choice.
(setq initial-buffer-choice #'my/initial-buffer)

(defun my/persp-ensure-main (&rest _)
  "Use a regular main workspace instead of the unfiltered nil perspective."
  (when persp-mode
    (persp-add-new "main")
    (persp-hide persp-nil-name)
    (when (equal persp-last-persp-name persp-nil-name)
      (setq persp-last-persp-name "main"))))

(add-hook 'persp-mode-hook #'my/persp-ensure-main)
(add-hook 'persp-after-load-state-functions #'my/persp-ensure-main)

(defun my/persp-save-before-client-teardown ()
  "Save layouts before the server tears down a terminal client."
  (when persp-mode
    (remove-hook 'delete-frame-functions #'persp-delete-frame)
    (add-hook 'delete-frame-functions #'persp-delete-frame -50)))

(add-hook 'persp-mode-hook #'my/persp-save-before-client-teardown)

(defun my/persp-save-last-workspace (_file hash _respect-persp-file)
  "Record the last active workspace in HASH's saved parameters."
  (when (eq hash *persp-hash*)
    (dolist (persp (persp-persps hash))
      (persp-set-parameter 'my/last-workspace
                          (equal (persp-name persp) persp-last-persp-name)
                          persp))))

(defun my/persp-restore-last-workspace (_file hash names)
  "Resume the last workspace after loading NAMES into HASH."
  (when (and (eq hash *persp-hash*) (persp-frame-good-p))
    (when-let* ((name (cl-find-if
                      (lambda (name)
                        (persp-parameter 'my/last-workspace
                                         (persp-get-by-name name hash)))
                      names)))
      (persp-frame-switch name))))

(add-hook 'persp-before-save-state-to-file-functions
          #'my/persp-save-last-workspace)
;; Restore after persp-mode has converted the saved window configurations.
(add-hook 'persp-after-load-state-functions
          #'my/persp-restore-last-workspace 90)

(defun my/persp-list-buffers ()
  "List buffers belonging to the current workspace."
  (interactive)
  (display-buffer
   (list-buffers-noselect nil #'persp-buffer-list-restricted)))

(provide 'my-workspaces)
;;; my-workspaces.el ends here

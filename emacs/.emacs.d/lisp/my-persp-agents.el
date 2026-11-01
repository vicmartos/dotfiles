;;; my-persp-agents.el --- Switch between Ghostel agents -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'subr-x)
(require 'persp-mode)

(defvar my/persp-map)
(defvar ghostel-program-status)
(defvar ghostel-title)
(declare-function ghostel-buffer-list "ghostel")
(declare-function ghostel-foreground-pid "ghostel")

(defgroup my/agents nil "Ghostel agent selection." :group 'convenience)
(defcustom my/agent-identities
  '(("codex" . "Codex") ("agent" . "Cursor")
    ("cursor-agent" . "Cursor") ("cursor" . "Cursor")
    ("opencode" . "OpenCode"))
  "Reported app and executable/script basenames recognized as agents.
Extend this mapping for additional CLIs.  Generic interpreter names do
not identify an agent."
  :type '(alist :key-type string :value-type string)
  :group 'my/agents)

(defconst my/agent--states '(blocked error done working idle))

(defface my/agent-working
  '((((class color) (background light)) :foreground "RoyalBlue3" :weight bold)
    (t :foreground "DeepSkyBlue2" :weight bold))
  "Face for working agents in the picker." :group 'my/agents)

(defface my/agent-idle
  '((((class color) (background light)) :foreground "gray45")
    (t :foreground "gray65"))
  "Face for idle agents in the picker." :group 'my/agents)

(defface my/agent-blocked
  '((((class color) (background light)) :foreground "DarkGoldenrod3" :weight bold)
    (t :foreground "gold" :weight bold))
  "Face for blocked agents in the picker." :group 'my/agents)

(defface my/agent-error
  '((((class color) (background light)) :foreground "firebrick3" :weight bold)
    (t :foreground "IndianRed1" :weight bold))
  "Face for agents reporting errors in the picker." :group 'my/agents)

(defface my/agent-done
  '((((class color) (background light)) :foreground "ForestGreen" :weight bold)
    (t :foreground "SeaGreen3" :weight bold))
  "Face for completed agents in the picker." :group 'my/agents)

(defun my/agent--identity (name)
  "Recognize application or executable NAME."
  (when (stringp name)
    (let* ((base (downcase (file-name-nondirectory name)))
           (stem (replace-regexp-in-string "\\.\\(?:js\\|mjs\\|cjs\\|py\\)\\'" "" base)))
      (or (cdr (assoc base my/agent-identities))
          (cdr (assoc stem my/agent-identities))))))

(defun my/agent--argv-identity (argv)
  "Identify the executable or interpreter script in ARGV.
Never search arbitrary command arguments for agent names."
  (or (my/agent--identity (car argv))
      (when (member (file-name-nondirectory (or (car argv) ""))
                    '("node" "nodejs" "python" "python3" "bun" "deno"))
        (let ((script (cadr argv)))
          (when (and script (not (string-prefix-p "-" script)))
            (my/agent--identity script))))))

(defun my/agent--process-identity ()
  "Identify the current local Ghostel foreground process.
Read Linux argv without shell parsing; fall back to the OS process name."
  (unless (file-remote-p default-directory)
    (when-let* ((pid (ghostel-foreground-pid)))
      (or (ignore-errors
            (with-temp-buffer
              (insert-file-contents-literally (format "/proc/%d/cmdline" pid))
              (my/agent--argv-identity (split-string (buffer-string) "\0" t))))
          (my/agent--identity (alist-get 'comm (process-attributes pid)))))))

(defun my/agent--records ()
  "Return current terminal status records, if available."
  (and (boundp 'ghostel-program-status) ghostel-program-status))

(defun my/agent--detect (buffer)
  "Return BUFFER's agent identity, independently of its name."
  (with-current-buffer buffer
    (or (cl-loop for (_id . record) in (my/agent--records)
                 thereis (my/agent--identity (plist-get record :app)))
        (my/agent--process-identity))))

(defun my/agent--record ()
  "Return the most urgent status record of the current terminal."
  (cl-loop for state in my/agent--states
           thereis (cl-loop for (_id . record) in (my/agent--records)
                            when (eq state (plist-get record :state))
                            return record)))

(defun my/agent--perspectives (buffer)
  "Return names of regular perspectives containing BUFFER."
  (sort (cl-loop for perspective in (persp-persps)
                 unless (persp-nil-p perspective)
                 when (persp-contain-buffer-p buffer perspective)
                 collect (persp-name perspective))
        #'string<))

(defun my/agent--status-label (record)
  "Format RECORD's status and message for the picker."
  (if (null record) (propertize "status unavailable" 'face 'shadow)
    (string-join
     (delq nil (list (let ((state (plist-get record :state)))
                       (propertize (symbol-name state) 'face
                                   (pcase state
                                     ('working 'my/agent-working)
                                     ('idle 'my/agent-idle)
                                     ('blocked 'my/agent-blocked)
                                     ('error 'my/agent-error)
                                     ('done 'my/agent-done)
                                     (_ 'shadow))))
                     (when-let* ((kind (plist-get record :kind)))
                       (symbol-name kind))
                     (when-let* ((progress (plist-get record :progress)))
                       (format "%d%%" progress))
                     (plist-get record :msg)))
     " ")))

(defun my/agent--entries ()
  "Collect and rank one picker entry per recognized Ghostel terminal."
  (let (entries)
    (dolist (buffer (ghostel-buffer-list))
      (when-let* ((agent (my/agent--detect buffer)))
        (with-current-buffer buffer
          (let* ((record (my/agent--record))
                 (state (plist-get record :state))
                 (title (or (and (boundp 'ghostel-title) ghostel-title)
                            (plist-get record :title)))
                 (perspectives (my/agent--perspectives buffer))
                 (label (string-join
                         (delq nil
                               (list agent
                                     (my/agent--status-label record)
                                     (when (and (stringp title)
                                                (not (string-blank-p title)))
                                       title)
                                     (abbreviate-file-name default-directory)
                                     (if perspectives (string-join perspectives ", ") "no perspective")
                                     (buffer-name)))
                         " | ")))
            (push (list (replace-regexp-in-string "[\n\r\t]" " " label)
                        buffer (or (cl-position state my/agent--states) 5)) entries)))))
    (sort entries (lambda (a b)
                    (if (= (nth 2 a) (nth 2 b))
                        (string< (buffer-name (cadr a)) (buffer-name (cadr b)))
                      (< (nth 2 a) (nth 2 b)))))))

(defun my/agent--visit (buffer)
  "Switch to BUFFER's perspective and select its terminal window."
  (unless (buffer-live-p buffer)
    (user-error "Agent buffer has closed; reopen the picker"))
  (when (and persp-mode (persp-frame-good-p))
    (let* ((names (my/agent--perspectives buffer))
           (name (if (cdr names)
                     (completing-read "Agent perspective: " names nil t nil nil
                                      (when (member (persp-name (persp-get-current)) names)
                                        (persp-name (persp-get-current))))
                   (car names))))
      (unless (buffer-live-p buffer)
        (user-error "Agent buffer has closed; reopen the picker"))
      (when name
        (unless (member name (my/agent--perspectives buffer))
          (user-error "Agent perspective changed; reopen the picker"))
        (persp-switch name))
      (unless name (persp-add-buffer buffer))))
  (if-let* ((window (get-buffer-window buffer (selected-frame))))
      (select-window window)
    (switch-to-buffer buffer)))

;;;###autoload
(defun my/agent-switch ()
  "Pick a Ghostel agent across workspaces and focus its terminal.
Candidates are a fresh snapshot on each invocation.  Selecting a shared
buffer prompts for its perspective; quitting never previews or switches."
  (interactive)
  (require 'ghostel)
  (let* ((entries (my/agent--entries))
         (completion-extra-properties
          '(:display-sort-function identity :cycle-sort-function identity)))
    (unless entries (user-error "No Ghostel agents found"))
    (let ((choice (completing-read "Agent: " (mapcar #'car entries) nil t)))
      (my/agent--visit (cadr (assoc choice entries))))))

(with-eval-after-load 'my-perspectives
  (define-key my/persp-map (kbd "a") #'my/agent-switch))

(provide 'my-persp-agents)
;;; my-persp-agents.el ends here

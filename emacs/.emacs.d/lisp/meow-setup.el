;;; meow-setup.el --- Modal editing configuration -*- lexical-binding: t; -*-

;;; Code:

;; Selection-first modal editing: NORMAL state drives with plain letters
;; (hjkl move, w/s/x mark/kill/yank...), INSERT state is vanilla Emacs.
;; All existing C-x/C-c/M- bindings keep working in every state; KEYPAD
;; gives modifier-free access to them (SPC x f = C-x C-f, SPC c = C-c).
;; Repeated edits: select lines, then G (meow-grab) and enter INSERT —
;; edits replay at each Beacon location;
;; 1..9 expand the selection by "thing".
;; SPC ? shows the cheatsheet, M-x meow-tutor is a guided tutorial.
(use-package meow
  :ensure t
  :demand t
  :init
  ;; In terminal Emacs, the default 0.1s delay after ESC is more noticeable:
  ;; a quick ESC followed by a key can be misread as M-<key>, firing
  ;; unintended commands.  Disable the delay entirely.
  (setq meow-esc-delay 0)
  ;; Resolve the active C-c bindings, including major/minor-mode prefixes
  ;; such as Eglot's C-c l, instead of only the global mode-specific-map.
  (setq meow-keypad-leader-dispatch "C-c")
  :config
  ;; Keep Meow's default rules for text and special buffers.  Ghostel derives
  ;; from fundamental-mode, so override its default NORMAL state for typing.
  (setf (alist-get 'ghostel-mode meow-mode-state-list) 'insert)

  (defun meow-setup ()
    "Configure Meow keybindings for the QWERTY layout."
    (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
    (meow-motion-define-key
     ;;'("j" . meow-next) disabled for the moment
     ;;'("k" . meow-prev) disabled for the moment
     '("F" . avy-goto-char-2)
     '("<escape>" . ignore))
    (meow-leader-define-key
     ;; Use SPC (0-9) for digit arguments.
     '("1" . meow-digit-argument)
     '("2" . meow-digit-argument)
     '("3" . meow-digit-argument)
     '("4" . meow-digit-argument)
     '("5" . meow-digit-argument)
     '("6" . meow-digit-argument)
     '("7" . meow-digit-argument)
     '("8" . meow-digit-argument)
     '("9" . meow-digit-argument)
     '("0" . meow-digit-argument)
     '("/" . meow-keypad-describe-key)
     '("?" . meow-cheatsheet))
    (meow-normal-define-key
     '("0" . meow-expand-0)
     '("9" . meow-expand-9)
     '("8" . meow-expand-8)
     '("7" . meow-expand-7)
     '("6" . meow-expand-6)
     '("5" . meow-expand-5)
     '("4" . meow-expand-4)
     '("3" . meow-expand-3)
     '("2" . meow-expand-2)
     '("1" . meow-expand-1)
     '("-" . negative-argument)
     '(";" . meow-reverse)
     '("," . meow-inner-of-thing)
     '("." . meow-bounds-of-thing)
     '("[" . meow-beginning-of-thing)
     '("]" . meow-end-of-thing)
     '("a" . meow-append)
     '("A" . meow-open-below)
     '("b" . meow-back-word)
     '("B" . meow-back-symbol)
     '("c" . meow-change)
     '("d" . meow-delete)
     '("D" . meow-backward-delete)
     '("e" . meow-next-word)
     '("E" . meow-next-symbol)
     '("f" . meow-find)
     '("F" . avy-goto-char-2)
     '("g" . meow-cancel-selection)
     '("G" . meow-grab)
     '("h" . meow-left)
     '("H" . meow-left-expand)
     '("i" . meow-insert)
     '("I" . meow-open-above)
     '("j" . meow-next)
     '("J" . meow-next-expand)
     '("k" . meow-prev)
     '("K" . meow-prev-expand)
     '("l" . meow-right)
     '("L" . meow-right-expand)
     '("m" . meow-join)
     '("n" . meow-search)
     '("o" . meow-block)
     '("O" . meow-to-block)
     '("p" . meow-yank)
     '("q" . meow-quit)
     '("Q" . meow-goto-line)
     '("r" . meow-replace)
     '("R" . meow-swap-grab)
     '("s" . meow-kill)
     '("t" . meow-till)
     '("u" . meow-undo)
     '("U" . meow-undo-in-selection)
     '("v" . meow-visit)
     '("w" . meow-mark-word)
     '("W" . meow-mark-symbol)
     '("x" . meow-line)
     '("X" . meow-goto-line)
     '("y" . meow-save)
     '("Y" . meow-sync-grab)
     '("z" . meow-pop-selection)
     '("'" . repeat)
     '("<escape>" . ignore)))
  (meow-setup)
  (meow-global-mode 1))

(provide 'meow-setup)
;;; meow-setup.el ends here

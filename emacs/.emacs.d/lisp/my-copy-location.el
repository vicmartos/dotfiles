;;; my-copy-location.el --- Copy file locations for agents -*- lexical-binding: t; -*-

(require 'eieio)
(require 'seq)
(require 'subr-x)

;; Let the byte compiler check Magit's section slots.
(eval-when-compile (require 'magit-base))

(declare-function magit-section-at "magit-section" (&optional position))
(declare-function magit-section-lineage "magit-section" (section &optional raw))
(declare-function magit-section-value-if "magit-section" (condition &optional section))
(declare-function magit-file-section-p "magit-base" (object))
(declare-function magit-hunk-section-p "magit-base" (object))
(declare-function magit-toplevel "magit-git" (&optional directory))
(declare-function magit-diff-type "magit-diff" (&optional section))
(declare-function magit-diff-hunk-line "magit-diff" (section goto-from))
(declare-function magit-diff-visit--offset "magit-diff" (line file &rest args))

(defun my/copy-location--region-lines ()
  "Return the active Emacs region as an inclusive line range, or nil."
  (when (use-region-p)
    (let ((begin (region-beginning))
          (end (region-end)))
      (cons (line-number-at-pos begin)
            (line-number-at-pos (max begin (1- end)))))))

(defun my/copy-location--format-range (first last)
  "Format the inclusive line range FIRST through LAST."
  (if (= first last)
      (number-to-string first)
    (format "%d-%d" first last)))

(defun my/copy-location--compact-lines (lines)
  "Format sorted or unsorted LINES as compact line ranges."
  (let ((numbers (sort (delete-dups (copy-sequence lines)) #'<))
        ranges)
    (while numbers
      (let* ((first (pop numbers))
             (last first))
        (while (and numbers (= (car numbers) (1+ last)))
          (setq last (pop numbers)))
        (push (my/copy-location--format-range first last) ranges)))
    (string-join (nreverse ranges) ",")))

(defun my/copy-location--usable-path (path)
  "Return normalized absolute PATH, or signal a user error."
  (unless (and (stringp path)
               (not (string-empty-p path))
               (not (file-remote-p path))
               (not (string-match-p "[[:cntrl:]]" path)))
    (user-error "This buffer has no usable local file path"))
  (expand-file-name path))

(defun my/copy-location--working-lines (path)
  "Read PATH once and return its lines as a vector, or nil if unreadable."
  (and (file-readable-p path)
       (with-temp-buffer
         (insert-file-contents path)
         (if (zerop (buffer-size))
             []
           (vconcat (string-lines (buffer-string)))))))

(defun my/copy-location--magit (first last)
  "Return a location reference for Magit lines FIRST through LAST."
  (require 'magit-diff)
  (save-excursion
    (goto-char (point-min))
    (forward-line (1- first))
    (let* ((section (magit-section-at))
           (lineage (and section (magit-section-lineage section t)))
           (file-section (seq-find #'magit-file-section-p lineage))
           (hunk (seq-find #'magit-hunk-section-p lineage)))
      (unless file-section
        (user-error "Point is not on a Magit file or diff"))
      (let* ((file (magit-section-value-if 'file file-section))
             (path (my/copy-location--usable-path
                    (expand-file-name file (magit-toplevel)))))
        (if (null hunk)
            (progn
              (unless (= first last)
                (user-error "Select one Magit file row, or lines within one diff hunk"))
              path)
          (when (oref hunk combined)
            (user-error "Combined merge diffs are not supported"))
          (let ((working-lines (my/copy-location--working-lines path))
                (staged (eq (magit-diff-type hunk) 'staged))
                live-lines deleted-lines unmapped-lines parts)
            (dotimes (_ (1+ (- last first)))
              (unless (and (>= (point) (oref hunk content))
                           (< (point) (oref hunk end)))
                (user-error "Select diff body lines from one file and one hunk"))
              (let ((prefix (char-after))
                    (text (buffer-substring-no-properties
                           (1+ (point)) (line-end-position))))
                (unless (memq prefix '(?\s ?+ ?-))
                  (user-error "Select only diff body lines from one hunk"))
                (if (eq prefix ?-)
                    (push text deleted-lines)
                  (let ((line (magit-diff-hunk-line hunk nil)))
                    (when staged
                      (setq line
                            (condition-case nil
                                (magit-diff-visit--offset line file)
                              (error nil))))
                    (if (and (integerp line)
                             (<= 1 line (length working-lines))
                             (equal text (aref working-lines (1- line))))
                        (push line live-lines)
                      (push text unmapped-lines)))))
              (forward-line))
            (when live-lines
              (push (format "%s:%s" path
                            (my/copy-location--compact-lines live-lines))
                    parts))
            (when deleted-lines
              (push (concat path " - deleted -\n"
                            (string-join (nreverse deleted-lines) "\n"))
                    parts))
            (when unmapped-lines
              (push (concat path " - selected diff lines -\n"
                            (string-join (nreverse unmapped-lines) "\n"))
                    parts))
            (string-join (nreverse parts) "\n")))))))

(defun my/copy-location-reference ()
  "Copy the file location or Magit status diff reference to the clipboard.
Use the active region's lines, or the current line when no region is active."
  (interactive)
  (save-restriction
    (widen)
    (let* ((selection (my/copy-location--region-lines))
           (first (or (car-safe selection) (line-number-at-pos)))
           (last (or (cdr-safe selection) first))
           (reference
            (cond
             ((derived-mode-p 'magit-status-mode)
              (my/copy-location--magit first last))
             (buffer-file-name
              (format "%s:%s"
                      (my/copy-location--usable-path buffer-file-name)
                      (my/copy-location--format-range first last)))
             (t
              (user-error "This buffer has no usable file path")))))
      (kill-new reference)
      (message "Copied file location to clipboard"))))

(global-set-key (kbd "C-c y") #'my/copy-location-reference)

(provide 'my-copy-location)
;;; my-copy-location.el ends here

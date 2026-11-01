;;; my-persp-agents-test.el --- Agent picker tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'my-persp-agents)
(defvar ghostel-program-status nil)

(ert-deftest my/agent-command-identities ()
  (dolist (argv '(("/usr/bin/codex") ("node" "/app/codex.js")))
    (should (equal "Codex" (my/agent--argv-identity argv))))
  (should (equal "Cursor" (my/agent--argv-identity '("/opt/agent"))))
  (dolist (argv '(("echo" "codex") ("node" "unrelated.js" "codex")
                  ("node" "-e" "codex") ("bash" "-c" "codex") ("python3")))
    (should-not (my/agent--argv-identity argv))))

(ert-deftest my/agent-status-and-name-independence ()
  (with-temp-buffer
    (rename-buffer "unrelated terminal" t)
    (setq-local ghostel-program-status '(("" :app "codex" :state working)
                                        ("child" :state blocked :kind permission)))
    (should (equal "Codex" (my/agent--detect (current-buffer))))
    (should (eq 'blocked (plist-get (my/agent--record) :state)))
    (should (equal "blocked permission" (my/agent--status-label (my/agent--record))))
    (setq ghostel-program-status nil)
    (rename-buffer "*AI Agent codex*" t)
    (cl-letf (((symbol-function 'my/agent--process-identity) (lambda () nil)))
      (should-not (my/agent--detect (current-buffer)))))
  (should (equal "status unavailable" (my/agent--status-label nil)))
  (should (equal "working 0%" (my/agent--status-label '(:state working :progress 0)))))

(ert-deftest my/agent-remote-does-not-probe-local-processes ()
  (let ((default-directory "/ssh:host:/work/"))
    (cl-letf (((symbol-function 'ghostel-foreground-pid)
               (lambda () (ert-fail "Local probe on remote terminal"))))
      (should-not (my/agent--process-identity)))))

(ert-deftest my/agent-local-argv-without-emacs-subprocess ()
  (cl-letf (((symbol-function 'ghostel-foreground-pid) (lambda () (emacs-pid)))
            ((symbol-function 'my/agent--argv-identity)
             (lambda (argv) (should (stringp (car argv))) "Codex")))
    (should (equal "Codex" (my/agent--process-identity)))))

(ert-deftest my/agent-ranking-and-duplicate-sessions ()
  (let ((a (generate-new-buffer "agent-a")) (b (generate-new-buffer "agent-b")))
    (unwind-protect
        (progn
          (with-current-buffer a
            (setq-local ghostel-program-status '(("" :app "codex" :state working))))
          (with-current-buffer b
            (setq-local ghostel-program-status '(("" :app "codex" :state done))))
          (cl-letf (((symbol-function 'ghostel-buffer-list) (lambda () (list a b)))
                    ((symbol-function 'my/agent--perspectives) (lambda (_) '("work"))))
            (let ((entries (my/agent--entries)))
              (should (= 2 (length entries)))
              (should (eq b (cadar entries)))
              (should (string-match-p "Codex.*done.*work.*agent-b" (caar entries))))))
      (kill-buffer a) (kill-buffer b))))

(ert-deftest my/agent-membership-excludes-nil ()
  (cl-letf (((symbol-function 'persp-persps) (lambda () '(all first second)))
            ((symbol-function 'persp-nil-p) (lambda (p) (eq p 'all)))
            ((symbol-function 'persp-contain-buffer-p) (lambda (_b p) (eq p 'second)))
            ((symbol-function 'persp-name) (lambda (p) (symbol-name p))))
    (should (equal '("second") (my/agent--perspectives (current-buffer))))))

(ert-deftest my/agent-picker-shows-terminal-title-with-status-message ()
  (with-temp-buffer
    (setq-local ghostel-program-status
                '(("" :app "codex" :state working :title "Root task")
                  ("child" :state blocked :msg "Approve command")))
    (setq-local ghostel-title "Fix\nagent\ttitles")
    (let ((buffer (current-buffer)))
      (cl-letf (((symbol-function 'ghostel-buffer-list) (lambda () (list buffer)))
                ((symbol-function 'my/agent--perspectives) (lambda (_) '("work"))))
        (should (string-prefix-p
                 "Codex | blocked Approve command | Fix agent titles | "
                 (caar (my/agent--entries))))
        ;; Read the title afresh each time the picker is opened.
        (setq ghostel-title "Updated task")
        (should (string-prefix-p "Codex | blocked Approve command | Updated task | "
                                 (caar (my/agent--entries))))))))

(ert-deftest my/agent-picker-title-fallback-and-missing-title ()
  (with-temp-buffer
    (setq-local ghostel-title nil)
    (setq-local ghostel-program-status
                '(("" :app "codex" :state working :title "Fix picker")))
    (let ((buffer (current-buffer)))
      (cl-letf (((symbol-function 'ghostel-buffer-list) (lambda () (list buffer)))
                ((symbol-function 'my/agent--perspectives) (lambda (_) nil)))
        (should (string-prefix-p "Codex | working | Fix picker | "
                                 (caar (my/agent--entries))))
        (setq ghostel-program-status '(("" :app "codex" :state idle)))
        (dolist (title '(nil "" " \t\n"))
          (setq ghostel-title title)
          (should (string-prefix-p "Codex | idle | "
                                   (caar (my/agent--entries)))))))))

(ert-deftest my/agent-navigation-memberships ()
  (dolist (names '(nil ("work") ("work" "other")))
    (let ((persp-mode t) switched added prompted)
      (cl-letf (((symbol-function 'persp-frame-good-p) (lambda () t))
                ((symbol-function 'my/agent--perspectives) (lambda (_) names))
                ((symbol-function 'persp-get-current) (lambda () 'current))
                ((symbol-function 'persp-name) (lambda (_) "work"))
                ((symbol-function 'persp-switch) (lambda (name) (setq switched name)))
                ((symbol-function 'persp-add-buffer) (lambda (_) (setq added t)))
                ((symbol-function 'completing-read)
                 (lambda (&rest _) (setq prompted t) "other")))
        (my/agent--visit (current-buffer))
        (should (equal switched (cond ((cdr names) "other") (names "work"))))
        (should (eq (not names) (not (null added))))
        (should (eq (not (null (cdr names))) (not (null prompted))))))))

(ert-deftest my/agent-navigation-cancel-does-not-switch ()
  (let ((persp-mode t))
    (cl-letf (((symbol-function 'persp-frame-good-p) (lambda () t))
              ((symbol-function 'my/agent--perspectives) (lambda (_) '("a" "b")))
              ((symbol-function 'persp-get-current) (lambda () nil))
              ((symbol-function 'persp-name) (lambda (_) "a"))
              ((symbol-function 'completing-read) (lambda (&rest _) (signal 'quit nil)))
              ((symbol-function 'persp-switch) (lambda (_) (ert-fail "Switched on cancellation"))))
      (should (eq 'cancelled (condition-case nil (my/agent--visit (current-buffer))
                              (quit 'cancelled)))))))

(ert-deftest my/agent-navigation-terminal-and-dead-buffer ()
  (let ((persp-mode t))
    (cl-letf (((symbol-function 'persp-frame-good-p) (lambda () nil))
              ((symbol-function 'my/agent--perspectives) (lambda (_) (ert-fail "TTY membership lookup"))))
      (my/agent--visit (current-buffer))))
  (let ((buffer (generate-new-buffer "dead agent")))
    (kill-buffer buffer)
    (should-error (my/agent--visit buffer) :type 'user-error)))

(ert-deftest my/agent-navigation-focuses-existing-window ()
  (save-window-excursion
    (let ((buffer (generate-new-buffer "visible agent")) (persp-mode nil))
      (unwind-protect
          (let ((window (split-window-right)))
            (set-window-buffer window buffer)
            (my/agent--visit buffer)
            (should (eq window (selected-window)))
            (should (= 2 (length (window-list)))))
        (kill-buffer buffer)))))

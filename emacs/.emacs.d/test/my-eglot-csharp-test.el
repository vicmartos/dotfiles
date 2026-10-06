;;; my-eglot-csharp-test.el --- Roslyn compatibility tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'my-eglot-csharp)

(defmacro my-eglot-test-with-server (class &rest body)
  "Evaluate BODY with a disposable connection of CLASS bound to server."
  (declare (indent 1))
  `(let* ((process (make-process :name "eglot-test" :command '("cat")
                                 :buffer nil :noquery t))
          (server (make-instance ,class :name "eglot-test" :process process)))
     (setf (eglot--project server) '(transient . "/tmp/"))
     (unwind-protect
         (progn ,@body)
       (when (object-of-class-p server 'my-eglot-roslyn)
         (let ((timer (my-eglot-roslyn-refresh-timer server)))
           (when (timerp timer) (cancel-timer timer))))
       (delete-process process))))

(ert-deftest my-eglot-roslyn-capabilities-are-scoped ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let* ((caps (eglot-client-capabilities server))
           (diagnostic (plist-get (plist-get caps :textDocument) :diagnostic)))
      (should (eq (plist-get diagnostic :dynamicRegistration) :json-false))
      (should (eq (plist-get (plist-get (plist-get caps :workspace) :diagnostics)
                            :refreshSupport)
                  t))))
  (my-eglot-test-with-server 'eglot-lsp-server
    (should-not (plist-get (plist-get (eglot-client-capabilities server) :workspace)
                           :diagnostics))))

(ert-deftest my-eglot-roslyn-refresh-is-deferred-and-coalesced ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (should-not (eglot-handle-request server 'workspace/diagnostic/refresh))
    (should (equal (json-serialize
                    (list :result (eglot-handle-request server 'workspace/diagnostic/refresh))
                    :null-object nil :false-object :json-false)
                   "{\"result\":null}"))
    (let ((timer (my-eglot-roslyn-refresh-timer server)))
      (should (timerp timer))
      (eglot-handle-notification server 'workspace/projectInitializationComplete)
      (should (eq timer (my-eglot-roslyn-refresh-timer server))))))

(ert-deftest my-eglot-roslyn-refresh-only-checks-own-managed-buffers ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let ((owned (generate-new-buffer " *eglot-owned*"))
          (foreign (generate-new-buffer " *eglot-foreign*"))
          (inactive (generate-new-buffer " *eglot-inactive*"))
          checked)
      (unwind-protect
          (progn
            (cl-letf (((symbol-function 'eglot-managed-p)
                       (lambda () (not (eq (current-buffer) inactive))))
                      ((symbol-function 'eglot-current-server)
                       (lambda () (when (eq (current-buffer) owned) server)))
                      ((symbol-function 'flymake-start)
                       (lambda (&rest _) (push (current-buffer) checked))))
              (dolist (buf (list owned foreign inactive))
                (with-current-buffer buf (setq-local flymake-mode t)))
              (my-eglot-roslyn-refresh-diagnostics server)
              (let ((timer (my-eglot-roslyn-refresh-timer server)))
                (cancel-timer timer)
                (apply (timer--function timer) (timer--args timer)))
              (should (equal checked (list owned)))
              (should-not (my-eglot-roslyn-refresh-timer server))))
        (mapc #'kill-buffer (list owned foreign inactive))))))

(ert-deftest my-eglot-roslyn-refresh-ignores-a-stopped-server ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let (checked)
      (cl-letf (((symbol-function 'jsonrpc-running-p) (lambda (_) nil))
                ((symbol-function 'flymake-start)
                 (lambda (&rest _) (setq checked t))))
        (my-eglot-roslyn-refresh-diagnostics server)
        (let ((timer (my-eglot-roslyn-refresh-timer server)))
          (cancel-timer timer)
          (apply (timer--function timer) (timer--args timer)))
        (should-not checked)
        (should-not (my-eglot-roslyn-refresh-timer server))))))

(ert-deftest my-eglot-csharp-metadata-is-read-only-without-starting-eglot ()
  (let (started)
    (cl-letf (((symbol-function 'eglot-ensure) (lambda () (setq started t))))
      (with-temp-buffer
        (setq buffer-file-name "/tmp/MetadataAsSource/session/External.cs")
        (my/eglot-csharp-setup)
        (should buffer-read-only)
        (should-not started))
      (with-temp-buffer
        (setq buffer-file-name "/project/MetadataAsSourceHelpers/Project.cs")
        (my/eglot-csharp-setup)
        (should started)
        (should-not buffer-read-only)))))

(ert-deftest my-eglot-roslyn-toast-uses-standard-message-handler ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let (shown)
      (cl-letf (((symbol-function 'message)
                 (lambda (format-string &rest args)
                   (setq shown (apply #'format format-string args)))))
        (eglot-handle-notification server 'window/_roslyn_showToast
                                   :message "Project could not load" :messageType 1)
        (should (string-match-p "Project could not load" shown))))))

(ert-deftest my-eglot-roslyn-loads-a-unique-solution ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let (sent)
      (cl-letf (((symbol-function 'project-files)
                 (lambda (_) '("/tmp/Example.slnx" "/tmp/App/App.csproj")))
                ((symbol-function 'jsonrpc-notify)
                 (lambda (_server method params) (setq sent (list method params)))))
        (my-eglot-roslyn-open-projects server)
        (should (equal sent '(:solution/open (:solution "file:///tmp/Example.slnx"))))))))

(ert-deftest my-eglot-roslyn-loads-projects-without-choosing-an-ambiguous-solution ()
  (my-eglot-test-with-server 'my-eglot-roslyn
    (let (sent)
      (cl-letf (((symbol-function 'project-files)
                 (lambda (_) '("/tmp/One.sln" "/tmp/Two.sln"
                               "/tmp/C# sample/App.csproj" "/tmp/Test/Test.csproj")))
                ((symbol-function 'jsonrpc-notify)
                 (lambda (_server method params) (setq sent (list method params)))))
        (my-eglot-roslyn-open-projects server)
        (should (equal sent
                       '(:project/open
                         (:projects ["file:///tmp/C%23%20sample/App.csproj"
                                     "file:///tmp/Test/Test.csproj"]))))))))

(ert-deftest my-eglot-roslyn-discovery-does-not-touch-other-servers ()
  (my-eglot-test-with-server 'eglot-lsp-server
    (cl-letf (((symbol-function 'project-files)
               (lambda (_) (ert-fail "Unrelated server caused project discovery"))))
      (my-eglot-roslyn-open-projects server))))

;;; my-eglot-csharp-test.el ends here

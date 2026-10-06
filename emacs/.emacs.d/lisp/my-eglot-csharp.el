;;; my-eglot-csharp.el --- C# with Eglot and Roslyn -*- lexical-binding: t; -*-

;;; Commentary:
;; Requires Eglot 1.20+ (Emacs 31.1 includes 1.24.31) for pull diagnostics.
;; Install the Microsoft server before starting the Emacs daemon:
;;   dotnet tool install --global roslyn-language-server --prerelease
;; Keep diagnostic dynamic registration disabled: current Roslyn versions
;; then advertise diagnosticProvider during initialization.

;;; Code:

(require 'eglot)

(defclass my-eglot-roslyn (eglot-lsp-server)
  ((diagnostic-refresh-timer :initform nil
                             :accessor my-eglot-roslyn-refresh-timer))
  "Roslyn connection with project-loading and diagnostic refresh support.")

(cl-defmethod eglot-client-capabilities :around ((_server my-eglot-roslyn))
  "Advertise implemented diagnostic refresh support for Roslyn."
  (let* ((caps (cl-call-next-method))
         (workspace (plist-get caps :workspace)))
    (setf (plist-get workspace :diagnostics) '(:refreshSupport t)
          (plist-get caps :workspace) workspace)
    caps))

(defun my-eglot-roslyn-refresh-diagnostics (server)
  "Schedule a diagnostic refresh for buffers managed by SERVER.
Coalesce requests and return immediately, so the JSON-RPC request can be
acknowledged before sending any diagnostic requests back to Roslyn."
  (unless (timerp (my-eglot-roslyn-refresh-timer server))
    (setf (my-eglot-roslyn-refresh-timer server)
          (run-at-time
           0.1 nil
           (lambda ()
             (setf (my-eglot-roslyn-refresh-timer server) nil)
             (when (jsonrpc-running-p server)
               (dolist (buffer (buffer-list))
                 (with-current-buffer buffer
                   (when (and (eglot-managed-p)
                              (eq (eglot-current-server) server)
                              flymake-mode)
                     (flymake-start)))))))))
  nil)

(cl-defmethod eglot-handle-request
  ((server my-eglot-roslyn) (_method (eql workspace/diagnostic/refresh))
   &rest _params)
  "Acknowledge SERVER's refresh request, then recheck its open buffers."
  (my-eglot-roslyn-refresh-diagnostics server))

(cl-defmethod eglot-handle-notification
  ((server my-eglot-roslyn)
   (_method (eql workspace/projectInitializationComplete)) &rest _params)
  "Recheck diagnostics once SERVER has finished loading projects."
  (message "Roslyn: project initialization complete")
  (my-eglot-roslyn-refresh-diagnostics server))

(cl-defmethod eglot-handle-notification
  ((server my-eglot-roslyn) (_method (eql window/_roslyn_showToast))
   &key message messageType &allow-other-keys)
  "Display Roslyn project-loading errors through the standard handler."
  (eglot-handle-notification server 'window/showMessage
                             :message message :type (or messageType 3)))

(defun my-eglot-roslyn-open-projects (server)
  "Explicitly load SERVER's solution or projects after connecting.
Roslyn's automatic discovery can leave files in a miscellaneous project.
Use the sole solution in the Emacs project, or load its C# projects when
there is no unique solution.  Respect project.el's ignored files."
  (when (object-of-class-p server 'my-eglot-roslyn)
    (condition-case err
        (let* ((files (project-files (eglot--project server)))
               (solutions (cl-remove-if-not
                           (lambda (file)
                             (member (file-name-extension file) '("sln" "slnx")))
                           files))
               (projects (cl-remove-if-not
                          (lambda (file)
                            (equal (file-name-extension file) "csproj"))
                          files)))
          (cond
           ((= (length solutions) 1)
            (jsonrpc-notify server :solution/open
                            (list :solution (eglot-path-to-uri (car solutions)))))
           (projects
            (jsonrpc-notify server :project/open
                            (list :projects (vconcat (mapcar #'eglot-path-to-uri
                                                            projects)))))
           (t (message "Roslyn: no solution or C# project found in %s"
                       (project-root (eglot--project server))))))
      (error (message "Roslyn: could not discover projects: %s"
                      (error-message-string err))))))

(add-hook 'eglot-connect-hook #'my-eglot-roslyn-open-projects)

(defun my/eglot-csharp-contact (&rest _ignored)
  "Return the stdio contact for the installed Microsoft Roslyn server."
  (list 'my-eglot-roslyn
        "roslyn-language-server" "--stdio" "--logLevel" "Warning"
        "--clientProcessId" (number-to-string (emacs-pid))
        "--autoLoadProjects"))

(defun my/eglot-csharp-setup ()
  "Start Eglot for project files; make Roslyn metadata sources read-only."
  (if (and buffer-file-name
           (string-match-p "\\(?:^\\|/\\)MetadataAsSource/" buffer-file-name))
      (read-only-mode 1)
    (eglot-ensure)))

(add-to-list 'eglot-server-programs
             '((csharp-mode csharp-ts-mode) . my/eglot-csharp-contact))
(add-hook 'csharp-mode-hook #'my/eglot-csharp-setup)
(add-hook 'csharp-ts-mode-hook #'my/eglot-csharp-setup)

(provide 'my-eglot-csharp)
;;; my-eglot-csharp.el ends here

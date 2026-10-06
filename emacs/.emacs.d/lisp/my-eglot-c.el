;;; my-eglot-c.el --- C LSP configuration (Eglot + clangd) -*- lexical-binding: t; -*-

;; clangd needs a compile_commands.json (or a .clangd YAML) in the
;; project root to resolve includes correctly.
;;
;; For GStreamer projects built with Meson the typical workflow is:
;;
;;   meson setup builddir
;;   meson compile -C builddir            # builds the project
;;   ln -sf builddir/compile_commands.json .   # or let clangd find it
;;
;; Alternatively "bear -- meson compile -C builddir" will capture
;; compiler flags that Meson's own JSON may miss (e.g. generated
;; sources).
;;
;; You can also place a .clangd file in the project root:
;;
;;   CompileFlags:
;;     Add:
;;       - "-I/usr/include/gstreamer-1.0"
;;       - "-I/usr/include/glib-2.0"
;;       - "-I/usr/lib/x86_64-linux-gnu/glib-2.0/include"
;;
;; Run "pkg-config --cflags gstreamer-1.0" to get the right paths
;; for your system.

;;; Code

(require 'eglot)

(add-to-list 'eglot-server-programs
             '((c-mode c-ts-mode c++-mode c++-ts-mode objc-mode)
               . ("clangd" "--clang-tidy" "--header-insertion=never"
                  "--completion-style=detailed")))

(add-hook 'c-mode-hook #'eglot-ensure)
(add-hook 'c-ts-mode-hook #'eglot-ensure)

(provide 'my-eglot-c)
;;; my-eglot-c.el ends here

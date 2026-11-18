;;; lsp.el --- Eglot language server client  -*- lexical-binding: t; -*-
;;;
;;; Eglot (built in) already knows the usual server for every language:
;;; rust-analyzer, gopls, clangd, jdtls, typescript-language-server,
;;; yaml-language-server, bash-language-server ... Install a server and it
;;; is used; nothing has to be registered here. Only the exceptions are:
;;; `suhas/python-lsp-command' and `suhas/lsp-server-overrides' (settings.el).
;;; SPC c h lists which servers are installed.

(use-package eglot
  :ensure nil
  :custom
  (eglot-confirm-server-edits suhas/lsp-confirm-edits)
  (eglot-ignored-server-capabilities '(:documentHighlightProvider))
  ;; Shut a server down when its last buffer is closed.
  (eglot-autoshutdown t)
  ;; Never freeze the editor while a server starts (jdtls takes seconds).
  (eglot-sync-connect nil)
  ;; No log of every JSON message.
  (eglot-events-buffer-config '(:size 0 :format full))
  :config
  ;; TypeScript/JavaScript: prefer tsgo (Microsoft's native server) when it
  ;; is installed, else typescript-language-server.
  (add-to-list 'eglot-server-programs
               `(((js-mode :language-id "javascript")
                  (js-ts-mode :language-id "javascript")
                  (tsx-ts-mode :language-id "typescriptreact")
                  (typescript-ts-mode :language-id "typescript"))
                 . ,(eglot-alternatives
                     '(("tsgo" "--lsp" "--stdio")
                       ("typescript-language-server" "--stdio")))))
  (when suhas/python-lsp-command
    (add-to-list 'eglot-server-programs
                 `((python-mode python-ts-mode) . ,suhas/python-lsp-command)))
  ;; Your own entries (local.el) go in front of everything.
  (dolist (entry (reverse suhas/lsp-server-overrides))
    (add-to-list 'eglot-server-programs entry)))

;;; ============================================================
;;; AUTO-START — only when it is cheap and certain to work
;;; ============================================================

;; `eglot-ensure' in a mode hook complains on every file whose server is
;; not installed, and starts servers on remote hosts. This variant starts
;; one only for local files, only when the server program exists, and says
;; so ONCE per language when it does not.

(defvar suhas/--lsp-reported nil
  "Major modes already reported as having no language server installed.")

(defun suhas/--lsp-start ()
  "Connect this buffer to its language server, if one is installed."
  (remove-hook 'post-command-hook #'suhas/--lsp-start t)
  (when (and buffer-file-name
             (not (bound-and-true-p eglot--managed-mode))
             (require 'eglot nil t))
    (condition-case err
        (let* ((guess (eglot--guess-contact))
               (contact (nth 3 guess))
               (program (car-safe contact)))
          (cond
           ((null contact))             ; Eglot knows no server for this mode
           ((and (stringp program) (not (executable-find program)))
            (error "`%s' is not installed" program))
           (t (apply #'eglot--connect guess))))
      (error
       (unless (memq major-mode suhas/--lsp-reported)
         (push major-mode suhas/--lsp-reported)
         (message "No language server for %s: %s  (SPC c h lists them)"
                  major-mode (error-message-string err)))))))

(defun suhas/lsp-ensure ()
  "Arrange for a language server to start for this buffer.
Deferred to the end of the current command, so per-directory environments
\(direnv) are already in place when the server is looked up."
  (when (and suhas/lsp-auto-start
             buffer-file-name
             (not (file-remote-p buffer-file-name))
             (not (derived-mode-p 'emacs-lisp-mode)))
    (add-hook 'post-command-hook #'suhas/--lsp-start 'append t)))

;; yaml-ts-mode is a text mode, hence the second hook.
(add-hook 'prog-mode-hook #'suhas/lsp-ensure)
(add-hook 'yaml-ts-mode-hook #'suhas/lsp-ensure)

;;; ============================================================
;;; FLYMAKE — diagnostics
;;; ============================================================

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 0.5))

;;; lsp.el ends here

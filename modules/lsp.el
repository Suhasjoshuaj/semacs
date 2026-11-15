;;; lsp.el --- Eglot language server client  ... -*- lexical-binding: t; -*-
;;;
;;; Server commands and policy are knobs in settings.el
;;; (`suhas/python-lsp-command', `suhas/clangd-query-driver',
;;; `suhas/lsp-server-overrides', `suhas/lsp-confirm-edits').

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :custom
  ;; Ask before a server edits files. (This was nil: an LSP rename changed
  ;; every file in the codebase without a word.)
  (eglot-confirm-server-edits suhas/lsp-confirm-edits)
  ;; Keep document highlights disabled, but allow inlay hints.
  (eglot-ignored-server-capabilities
   '(:documentHighlightProvider))
  (eglot-autoshutdown t)
  :config
  ;; Don't keep a log of every JSON message (memory + speed). Eglot 1.17
  ;; (Emacs 30+) replaced the `-size' variable with `-config'.
  (if (boundp 'eglot-events-buffer-config)
      (setq eglot-events-buffer-config '(:size 0 :format full))
    (setq eglot-events-buffer-size 0)))

(defun suhas/clangd-command ()
  "clangd command line; passes --query-driver only when one is configured."
  (append '("clangd" "--background-index")
          (when suhas/clangd-query-driver
            (list (concat "--query-driver=" suhas/clangd-query-driver)))))

;; One entry per language server. Plain major modes only -- no -ts-mode
;; variants for now (tree-sitter is deliberately left out; LSP features
;; -- completion, diagnostics, go-to-def, rename -- all come from eglot,
;; not from tree-sitter).
(with-eval-after-load 'eglot
  (let ((ts-server (eglot-alternatives
                    ;; Prefers tsgo (Microsoft's Go-based server) when on PATH,
                    ;; else typescript-language-server.
                    '(("tsgo" "--lsp" "--stdio")
                      ("typescript-language-server" "--stdio")))))
    (add-to-list 'eglot-server-programs
                 `(python-mode . ,suhas/python-lsp-command))
    (add-to-list 'eglot-server-programs
                 `((js-mode typescript-mode) . ,ts-server))
    ;; TSX goes through web-mode (see langs.el); the language id must say
    ;; "typescriptreact" or tsserver treats JSX as a syntax error.
    (add-to-list 'eglot-server-programs
                 `((web-mode :language-id "typescriptreact") . ,ts-server)))
  (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(go-mode . ("gopls")))
  (add-to-list 'eglot-server-programs
               `((c-mode c++-mode) . ,(suhas/clangd-command)))
  (add-to-list 'eglot-server-programs '(java-mode . ("jdtls")))
  (add-to-list 'eglot-server-programs
               '(yaml-mode . ("yaml-language-server" "--stdio")))
  ;; Your own overrides (local.el) go in front of everything above.
  (dolist (entry suhas/lsp-server-overrides)
    (add-to-list 'eglot-server-programs entry)))

(dolist (hook '(python-mode-hook
                js-mode-hook          ; also covers js-jsx-mode (derived)
                typescript-mode-hook
                rust-mode-hook
                go-mode-hook
                c-mode-hook
                c++-mode-hook
                java-mode-hook
                yaml-mode-hook))
  (add-hook hook #'eglot-ensure))

(defun suhas/web-mode-maybe-eglot ()
  "Start Eglot in web-mode buffers that are TSX files.
web-mode also claims other extensions (.html, .erb...) when installed; only
TSX is meant to talk to the TypeScript server."
  (when (and buffer-file-name
             (string-match-p "\\.tsx\\'" buffer-file-name))
    (eglot-ensure)))
(add-hook 'web-mode-hook #'suhas/web-mode-maybe-eglot)

;; yaml-mode derives from text-mode, not prog-mode, so it misses the
;; prog-mode-hook -> flymake-mode wiring every other language gets below.
;; Without this, eglot would run but nothing would display its diagnostics.
(add-hook 'yaml-mode-hook #'flymake-mode)

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 0.5))

;;; lsp.el ends here

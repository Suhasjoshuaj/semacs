;;; lsp.el --- Eglot language server client

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure)
  :custom
  (eglot-confirm-server-edits nil)
  ;; Keep document highlights disabled, but allow inlay hints.
  (eglot-ignored-server-capabilities
   '(:documentHighlightProvider))
  (eglot-autoshutdown t)
  :config
  (setq eglot-events-buffer-size 0))

;; One entry per language server. Plain major modes only -- no -ts-mode
;; variants. Tree-sitter grammars are currently generated at ABI 15 by
;; default upstream, and Emacs 30.x only supports ABI 13-14, so any
;; -ts-mode here would either fail to activate tree-sitter or need a
;; manually-pinned old grammar revision per language (real, but fiddly
;; and can break again on the next `git pull` of a grammar). None of
;; this affects LSP features below -- completion, diagnostics,
;; go-to-def, rename all come from eglot, not from tree-sitter.
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pyright-langserver" "--stdio")))
  ;; Prefers tsgo (Microsoft's newer Go-based server) if it's on PATH,
  ;; falls back to typescript-language-server otherwise -- you have
  ;; the latter installed, so that's what actually runs for you.
  (add-to-list 'eglot-server-programs
               `((js-mode typescript-mode)
                 . ,(eglot-alternatives
                     '(("tsgo" "--lsp" "--stdio")
                       ("typescript-language-server" "--stdio")))))
  (add-to-list 'eglot-server-programs
               '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode) . ("clangd" "--background-index")))
  (add-to-list 'eglot-server-programs
               '(java-mode . ("jdtls")))
  (add-to-list 'eglot-server-programs
               '(yaml-mode . ("yaml-language-server" "--stdio"))))

(dolist (hook '(python-mode-hook
                js-mode-hook
                typescript-mode-hook
                rust-mode-hook
                c-mode-hook
                c++-mode-hook
                java-mode-hook
                yaml-mode-hook))
  (add-hook hook #'eglot-ensure))

;; yaml-mode derives from text-mode, not prog-mode, so it misses the
;; prog-mode-hook -> flymake-mode wiring every other language gets for
;; free below. Without this, eglot would be running and talking to
;; yaml-language-server just fine, but nothing would ever display its
;; diagnostics -- the mode would look broken when it's actually just
;; invisible.
(add-hook 'yaml-mode-hook #'flymake-mode)

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 0.5))

;;; lsp.el ends here

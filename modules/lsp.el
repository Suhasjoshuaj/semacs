;;; lsp.el --- Eglot language server client

(use-package eglot
  :ensure nil
  :commands eglot eglot-ensure
  :custom
  (eglot-autoshutdown t)
  (eglot-confirm-server-edits nil)
  (eglot-ignored-server-capabilities
   '(:documentHighlightProvider
     :inlayHintProvider))
  :config
  (setq eglot-events-buffer-size 0))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((js-mode typescript-ts-mode tsx-ts-mode jsx-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(rust-ts-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode c-ts-mode c++-ts-mode)
                 . ("clangd" "--background-index")))
  (add-to-list 'eglot-server-programs
               '(java-mode . ("jdtls"))))

(dolist (hook '(python-mode-hook
                js-mode-hook
                typescript-ts-mode-hook
                tsx-ts-mode-hook
                jsx-ts-mode-hook
                rust-ts-mode-hook
                rust-mode-hook
                c-mode-hook
                c++-mode-hook
                c-ts-mode-hook
                c++-ts-mode-hook
                java-mode-hook
                java-ts-mode-hook))
  (add-hook hook #'eglot-ensure))

(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 0.5))

;;; lsp.el ends here

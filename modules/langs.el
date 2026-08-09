;;; langs.el --- Per-language configuration

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :custom
  (python-indent-offset 4))

(use-package js
  :ensure nil
  :mode ("\\.js\\'" . js-mode)
  :custom
  (js-indent-level 2))

;; Plain (non-tree-sitter) TypeScript major mode. Pairs with the
;; typescript-language-server you installed via npm -- eglot already
;; knows to launch it (with --stdio) for both js-mode and this, see
;; lsp.el.
(use-package typescript-mode
  :ensure t
  :mode (("\\.ts\\'"  . typescript-mode)
         ("\\.tsx\\'" . typescript-mode))
  :custom
  (typescript-indent-level 2))

;; Plain (non-tree-sitter) Rust major mode, for rust-analyzer via eglot.
(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode))

;; Plain (non-tree-sitter) YAML major mode. Emacs only ships yaml-ts-mode
;; built in -- this is the third-party package, same category as
;; typescript-mode/rust-mode above, so :ensure t (not nil).
(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

;; c-mode/c++-mode (built into Emacs, no package needed) and java-mode
;; (ditto) are already the modes Emacs picks by default for
;; .c/.cpp/.java files, so they need no :mode declaration here -- just
;; the style tweak below.

(defun suhas/java-style ()
  "4-space indentation, no tabs, trim trailing whitespace on save."
  (c-set-style "java")
  (setq c-basic-offset 4)
  (setq tab-width 4)
  (setq indent-tabs-mode nil)
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(add-hook 'java-mode-hook #'suhas/java-style)

(add-hook 'prog-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)))

;;; langs.el ends here

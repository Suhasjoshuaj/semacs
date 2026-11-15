;;; langs.el --- Per-language configuration  ... -*- lexical-binding: t; -*-

;; Everything here is a plain (non-tree-sitter) major mode. Language servers
;; are wired up in lsp.el; formatters in formatter.el.

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :custom
  (python-indent-offset 4))

(use-package js
  :ensure nil
  :mode ("\\.js\\'" . js-mode)   ; .jsx -> js-jsx-mode is Emacs's own default
  :custom
  (js-indent-level 2))

(use-package typescript-mode
  :ensure t
  :mode ("\\.ts\\'" . typescript-mode)
  :custom
  (typescript-indent-level 2))

;; TSX: typescript-mode has no JSX support, so .tsx buffers use web-mode
;; (it understands JSX and TypeScript types together). Only .tsx is mapped
;; to it here. This is the best available WITHOUT tree-sitter; the proper
;; fix is tsx-ts-mode once tree-sitter is on the table (see README).
(use-package web-mode
  :ensure t
  :mode ("\\.tsx\\'" . web-mode)
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-code-indent-offset 2)
  (web-mode-css-indent-offset 2)
  :config
  (add-to-list 'web-mode-content-types-alist '("jsx" . "\\.tsx\\'")))

(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode))

(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-mode))

(use-package yaml-mode
  :ensure t
  :mode ("\\.ya?ml\\'" . yaml-mode))

(use-package markdown-mode
  :ensure t
  :mode (("\\.md\\'" . markdown-mode)
         ("README\\'" . markdown-mode)))

(use-package dockerfile-mode
  :ensure t
  :mode ("Dockerfile\\(?:\\..*\\)?\\'" . dockerfile-mode))

;; c-mode/c++-mode and java-mode are built in and already the default for
;; .c/.cpp/.java; only the style tweak below is needed.

(defun suhas/java-style ()
  "4-space indentation, no tabs, trim trailing whitespace on save."
  (c-set-style "java")
  (setq c-basic-offset 4)
  (setq tab-width 4)
  (setq indent-tabs-mode nil)
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))

(add-hook 'java-mode-hook #'suhas/java-style)

;; (No global hook forcing `indent-tabs-mode' nil: makefile-mode, a
;; prog-mode child, needs real tabs or `make' fails with "missing
;; separator", and go-mode wants tabs too.)

;;; langs.el ends here

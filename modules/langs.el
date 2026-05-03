;;; langs.el --- Per-language configuration
;;; Language-specific settings, formatters, and minor tweaks.
;;; LSP (eglot) is handled in lsp.el. This file handles everything else.


;;; ============================================================
;;; SECTION 0: FILE TYPE ASSOCIATIONS
;;; ============================================================

;; directly using classic font-locks and majjor modes.
(add-to-list 'auto-mode-alist '("\\.py\\'"   . python-mode))
(add-to-list 'auto-mode-alist '("\\.c\\'"    . c-mode))
(add-to-list 'auto-mode-alist '("\\.h\\'"    . c-mode))
(add-to-list 'auto-mode-alist '("\\.cpp\\'"  . c++-mode))
(add-to-list 'auto-mode-alist '("\\.cc\\'"   . c++-mode))
(add-to-list 'auto-mode-alist '("\\.hpp\\'"  . c++-mode))
(add-to-list 'auto-mode-alist '("\\.java\\'" . java-mode))
(add-to-list 'auto-mode-alist '("\\.js\\'"   . js-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"   . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'"  . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsx\\'"  . js-mode))


;;; ============================================================
;;; SECTION 1: FORMATTING — APHELEIA
;;; ============================================================

;; Apheleia formats code asynchronously — it doesn't block Emacs
;; while running prettier or black. It also preserves cursor position,
;; which format-all (your old package) didn't do reliably.

(use-package apheleia
  :ensure t
  :config
  (apheleia-global-mode 1)
  ;; Formatter assignments per major mode.
  ;; These override apheleia's defaults where needed.
  (setf (alist-get 'python-mode apheleia-mode-alist) 'black)
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'black)
  (setf (alist-get 'js-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'js-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'prettier)
  (setf (alist-get 'java-mode apheleia-mode-alist) 'google-java-format)
  (setf (alist-get 'c-mode apheleia-mode-alist) 'clang-format)
  (setf (alist-get 'c++-mode apheleia-mode-alist) 'clang-format)
  (setf (alist-get 'c-ts-mode apheleia-mode-alist) 'clang-format)
  (setf (alist-get 'c++-ts-mode apheleia-mode-alist) 'clang-format))


;;; ============================================================
;;; SECTION 2: PYTHON
;;; ============================================================

(use-package python
  :ensure nil                         ; Built-in
  :custom
  (python-indent-offset 4)
  (python-shell-interpreter "python3"))

;; Virtual environment support.
;; When you open a project with a .venv or venv folder,
;; pyvenv activates it automatically.
(use-package pyvenv
  :ensure t
  :hook (python-mode . pyvenv-mode)
  :config
  (pyvenv-tracking-mode 1))           ; Auto-activate venv per project

;;; ============================================================
;;; SECTION 3: JAVASCRIPT / TYPESCRIPT
;;; ============================================================

;; js-mode is built-in. We tweak indent and associate file types.
(use-package js
  :ensure nil
  :custom
  (js-indent-level 2))                ; JS convention is 2 spaces

;; TypeScript uses treesitter mode (typescript-ts-mode) which
;; is activated by treesit-auto in lsp.el. No extra package needed.

;; .jsx and .tsx file associations
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;;; ============================================================
;;; SECTION 4: C / C++
;;; ============================================================

(use-package cc-mode
  :ensure nil                         ; Built-in
  :custom
  (c-basic-offset 4)
  (c-default-style
   '((java-mode . "java")
     (other . "linux"))))             ; Linux kernel style for C/C++

;;; ============================================================
;;; SECTION 5: JAVA
;;; ============================================================

;; java-mode is built into cc-mode.
;; jdtls (Eclipse JDT Language Server) handles everything via eglot.
;; Heavy but necessary — Java's LSP is complex.

;; Auto-indent Java files to 4 spaces
(add-hook 'java-mode-hook
          (lambda ()
            (setq c-basic-offset 4
                  tab-width 4
                  indent-tabs-mode nil)))

;;; ============================================================
;;; SECTION 6: MARKUP LANGUAGES
;;; ============================================================

;; Markdown
(use-package markdown-mode
  :ensure t
  :mode (("\\.md\\'"       . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode))  ; GitHub Flavored Markdown for READMEs
  :custom
  (markdown-command "pandoc")            ; Use pandoc for preview/export
  (markdown-fontify-code-blocks-natively t)) ; Syntax highlight code blocks

;; YAML — config files, GitHub Actions, Docker Compose
(use-package yaml-mode
  :ensure t
  :mode (("\\.yml\\'"  . yaml-mode)
         ("\\.yaml\\'" . yaml-mode)))

;; TOML — Rust configs, Python pyproject.toml
(use-package toml-mode
  :ensure t
  :mode "\\.toml\\'")

;;; ============================================================
;;; SECTION 7: ELECTRIC PAIR — AUTO BRACKETS
;;; ============================================================

;; Auto-close brackets, quotes, parens in all prog modes.
;; electric-pair-mode is built-in.
(add-hook 'prog-mode-hook #'electric-pair-mode)
(add-hook 'org-mode-hook  #'electric-pair-mode)

;; Don't auto-pair < in org-mode (conflicts with org syntax)
(add-hook 'org-mode-hook
          (lambda ()
            (setq-local electric-pair-inhibit-predicate
                        (lambda (c)
                          (if (char-equal c ?<)
                              t
                            (electric-pair-default-inhibit c))))))

;;; ============================================================
;;; SECTION 8: RAINBOW DELIMITERS
;;; ============================================================

;; Colors matching brackets in different colors.
;; Saves your eyes when reading nested code.
(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

;;; langs.el ends here

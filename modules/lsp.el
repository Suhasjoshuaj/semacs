;;; lsp.el --- Eglot (built-in LSP client) + language servers
;;; Eglot ships with Emacs 29+. No install needed.
;;; It connects your editor to language servers that provide:
;;; completions, diagnostics, go-to-definition, hover docs, rename.

;;; ============================================================
;;; SECTION 1: EGLOT CORE
;;; ============================================================

(use-package eglot
  :ensure nil                         ; Built-in, no install
  :commands eglot eglot-ensure
  :custom
  (eglot-autoshutdown t)              ; Kill server when last buffer closes
  (eglot-confirm-server-edits nil)    ; Don't ask before applying server edits
  (eglot-extend-to-xref t)           ; Use eglot for xref (go-to-definition)
  (eglot-ignored-server-capabilities ; Disable features that add noise
   '(:documentHighlightProvider      ; Highlights all occurrences — distracting
     :inlayHintProvider))            ; Inline type hints — clutters code

  :config
  ;; Performance: don't log every LSP event.
  ;; LSP is extremely chatty. Logging it all tanks performance.
  (setq eglot-events-buffer-size 0)

  ;; Use corfu for LSP completions (set in completion.el).
  ;; This tells eglot to use completion-at-point which corfu picks up.
  (setq completion-category-defaults nil))

;;; ============================================================
;;; SECTION 2: LANGUAGE SERVER ASSIGNMENTS
;;; ============================================================

;; This table maps major modes to their language servers.
;; The server must be installed on your system (bootstrap.sh does this).
;; Eglot reads this table when you open a file.


(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((js-mode typescript-ts-mode tsx-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(java-mode . ("jdtls")))
  (add-to-list 'eglot-server-programs
               '((c-mode c++-mode) . ("clangd"))))

;;; ============================================================
;;; SECTION 3: AUTO-START EGLOT PER LANGUAGE
;;; ============================================================

;; eglot-ensure starts the language server when you open a file.
;; We attach it to prog-mode hooks so it covers all languages.

(dolist (hook '(python-mode-hook
                js-mode-hook
                java-mode-hook
                c-mode-hook
                c++-mode-hook))
  (add-hook hook #'eglot-ensure))

;;; ============================================================
;;; SECTION 4: DIAGNOSTICS — FLYMAKE
;;; ============================================================

;; Eglot uses flymake (built-in) for showing errors and warnings.
;; Red/yellow underlines in your code come from here.
;; Errors appear in the minibuffer when your cursor is on them.

(use-package flymake
  :ensure nil                         ; Built-in
  :hook (prog-mode . flymake-mode)
  :custom
  (flymake-fringe-indicator-position 'right-fringe)
  (flymake-no-changes-timeout 0.5))   ; Check 500ms after you stop typing

;; Navigate between errors with ] e and [ e

;;; ============================================================
;;; SECTION 5: TREESITTER
;;; ============================================================

;; Grammars are pre-built and installed manually via bootstrap.sh
;; See: https://github.com/casouri/tree-sitter-module/releases
(setq treesit-font-lock-level 4)

;;; lsp.el ends here

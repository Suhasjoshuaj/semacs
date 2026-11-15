;;; devtools.el --- Everyday professional tooling  ... -*- lexical-binding: t; -*-
;;;
;;; What a team codebase expects of your editor, beyond editing text:
;;;   editorconfig   obey the project's .editorconfig (indent, line endings)
;;;   envrc          per-project environment from direnv (.envrc): venvs, node
;;;                  versions, secrets that must not be in your shell profile
;;;   spellcheck     commit messages and prose (needs aspell/hunspell)
;;;   dape           debugger (Debug Adapter Protocol)

;;; ------------------------------------------------------------
;;; EditorConfig -- built into Emacs 30+, a package before that
;;; ------------------------------------------------------------

(use-package editorconfig
  :ensure nil
  :if (>= emacs-major-version 30)
  :config (editorconfig-mode 1))

(use-package editorconfig
  :ensure t
  :if (< emacs-major-version 30)
  :config (editorconfig-mode 1))

;;; ------------------------------------------------------------
;;; envrc -- direnv per project (only when direnv is installed)
;;; ------------------------------------------------------------

;; Pyright finds a project's virtualenv, `node' resolves to the project's
;; version, and so on, because each buffer gets the environment of its own
;; directory. Enabled late (after-init) as envrc recommends, so that it wraps
;; the other minor modes.
(use-package envrc
  :if (executable-find "direnv")
  :ensure t
  :hook (after-init . envrc-global-mode))

;;; ------------------------------------------------------------
;;; Spellcheck -- prose only, never code
;;; ------------------------------------------------------------

(when (seq-some #'executable-find '("aspell" "hunspell" "ispell"))
  (dolist (hook '(git-commit-setup-hook markdown-mode-hook org-mode-hook))
    (add-hook hook #'flyspell-mode)))

;;; ------------------------------------------------------------
;;; Debugger
;;; ------------------------------------------------------------

;; Needs a debug adapter per language (debugpy, codelldb, delve, ...); see
;; the dape README. Keys: SPC d ...
(use-package dape
  :ensure t
  :defer t
  :commands (dape dape-breakpoint-toggle dape-continue dape-next
             dape-step-in dape-step-out dape-restart dape-quit))

(with-eval-after-load 'evil
  (suhas/leader
    "d d" #'dape
    "d b" #'dape-breakpoint-toggle
    "d c" #'dape-continue
    "d n" #'dape-next
    "d i" #'dape-step-in
    "d o" #'dape-step-out
    "d r" #'dape-restart
    "d q" #'dape-quit))

;;; devtools.el ends here

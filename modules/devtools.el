;;; devtools.el --- Everyday professional tooling  -*- lexical-binding: t; -*-
;;;
;;;   editorconfig   obey the project's .editorconfig (built in)
;;;   envrc          per-project environment from direnv (.envrc)
;;;   spellcheck     commit messages and prose (needs aspell/hunspell)
;;;   dape           debugger (Debug Adapter Protocol), SPC d ...

;;; ------------------------------------------------------------
;;; EditorConfig
;;; ------------------------------------------------------------

(editorconfig-mode 1)

;;; ------------------------------------------------------------
;;; envrc -- direnv per project (only when direnv is installed)
;;; ------------------------------------------------------------

;; Each buffer gets the environment of its own directory: the language
;; server finds the project's virtualenv, `node' is the project's version.
(when (executable-find "direnv")
  (use-package envrc
    :hook (after-init . envrc-global-mode)))

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
;; the dape README.
(use-package dape
  :commands (dape dape-breakpoint-toggle dape-continue dape-next
             dape-step-in dape-step-out dape-restart dape-quit))

(suhas/leader
 "d"   "debug"
 "d d" #'dape
 "d b" #'dape-breakpoint-toggle
 "d c" #'dape-continue
 "d n" #'dape-next
 "d i" #'dape-step-in
 "d o" #'dape-step-out
 "d r" #'dape-restart
 "d q" #'dape-quit)

;;; devtools.el ends here

;;; init.el --- Entr point. Loads modules in order.
;;; This file contains NO configuration.
;;; It is a table of contents. All config lives in modules/.

;;; ============================================================
;;; PERFORMANCE: Start lean, pay GC cost only when needed
;;; ============================================================

;; Temporarily suppress file-name-handler during startup.
;; Emacs checks every file operation against this list.
;; Suppressing it during load speeds up init noticeably.
(defvar suhas--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist suhas--file-name-handler-alist)))

;;; ============================================================
;;; MODULE LOADER
;;; ============================================================

(defun suhas/load-module (name)
  "Load a module from the modules/ directory by NAME."
  (load (expand-file-name
         (concat "modules/" name)
         user-emacs-directory)
        nil    ; no error if missing — just skip silently
        t))    ; no message printed on load

;;; ============================================================
;;; LOAD ORDER — matters, don't reorder casually
;;; ============================================================

(suhas/load-module "core")         ; Package manager + sane defaults FIRST
(suhas/load-module "ui")           ; Visual layer
(suhas/load-module "evil")         ; Vim layer (needs ui for escape)
(suhas/load-module "completion")   ; Vertico + corfu (needs evil for maps)
(suhas/load-module "dired")        ; File manager
(suhas/load-module "git")          ; Magit + git-gutter
(suhas/load-module "terminal")     ; eat terminal
(suhas/load-module "lsp")          ; Eglot + treesitter
(suhas/load-module "langs")        ; Per-language config (needs lsp)
(suhas/load-module "org")          ; Org mode (needs evil)
(suhas/load-module "workspaces")   ; tab-bar + project.el

;;; ============================================================
;;; GLOBAL UTILITY FUNCTIONS
;;; ============================================================

(defun suhas/open-config ()
  "Jump to init.el."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun suhas/reload-config ()
  "Reload init.el without restarting Emacs."
  (interactive)
  (load (expand-file-name "init.el" user-emacs-directory))
  (message "Config reloaded."))

;;; ============================================================
;;; CUSTOM FILE — keep auto-generated settings out of init.el
;;; ============================================================

;; When you use M-x customize, Emacs writes settings back to a file.
;; We redirect that to custom.el so init.el stays clean.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here

;;; init.el --- Entry point. Loads modules in dependency order.
;;; NO configuration lives here. This file is a table of contents.
;;; All actual configuration lives in separate modules.

(setq use-package-verbose t)

;; Show startup time and package count
(defun efs/display-startup-time ()
  (let ((package-count (cond
                        ((featurep 'straight) (length straight--profile-cache))
                        ((boundp 'package-activated-list) (length package-activated-list))
                        (t 0))))
    (message "Emacs loaded %d packages in %s with %d garbage collections."
             package-count
             (format "%.2f seconds" (float-time (time-subtract after-init-time before-init-time)))
             gcs-done)))
(add-hook 'emacs-startup-hook #'efs/display-startup-time)

;;; ============================================================
;;; GC RESET — Bring garbage collection back to normal
;;; ============================================================

;; early-init.el set gc-cons-threshold to a huge value to speed up startup.
;; Now that the frame exists and packages are loaded, we reset it to a
;; reasonable value. 8MB is aggressive enough to not cause stuttering
;; but not so aggressive that it pauses during editing.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 8 1024 1024))))

;;; ============================================================
;;; LSP PROCESS OUTPUT — Increase buffer for large JSON blobs
;;; ============================================================

;; Language servers send massive JSON responses (completions, diagnostics, etc).
;; The default 4KB read buffer causes constant chunking and slowdown.
;; 1MB handles even hefty LSP responses without breaking a sweat.
(setq read-process-output-max (* 1024 1024))

;;; ============================================================
;;; MODULE LOADER — Simple function to load modules
;;; ============================================================

;; We organize config into separate files for clarity.
;; This function loads them from the modules/ subdirectory.
(defun suhas/load-module (name)
  "Load a module from modules/NAME.el"
  (load (expand-file-name (concat "modules/" name ".el") user-emacs-directory)
        nil t))

;;; ============================================================
;;; LOAD ORDER — Matters! Don't reorder casually.
;;; ============================================================

;; 1. CORE — Package manager + sane defaults. Must come first.
(suhas/load-module "core")

;; 2. UI — Themes, fonts, modeline. Loaded early so visuals are ready.
(suhas/load-module "ui")

;; 3. COMPLETION — Vertico, Marginalia, Consult. Minimal but fast.
(suhas/load-module "completion")

;; 4. EVIL — Vim layer. Loaded after UI (needs escape behavior defined).
(suhas/load-module "evil")

;; 5. TERMINAL — eat terminal emulator. Depends on evil for keybindings.
(suhas/load-module "terminal")

;; 6. LSP — Eglot language server client. Auto-installs servers.
(suhas/load-module "lsp")

;; 7. LANGS — Per-language config (file associations, compile flags, etc).
(suhas/load-module "langs")

;; 8. BUFFER-NAV — Smart buffer rotation (C-; and C-,).
(suhas/load-module "buffer-nav")

;; 9. WINDOW-MGMT — Tab-bar workspaces and window management.
(suhas/load-module "window-mgmt")

;; 10. COMPILE — Compile command bindings and setup.
(suhas/load-module "compile")


(suhas/load-module "formatter")
(suhas/load-module "magit")
(suhas/load-module "org")
 
;;; ============================================================
;;; UTILITY FUNCTIONS
;;; ============================================================

;; Jump to init.el for quick config editing.
(defun suhas/open-config ()
  "Open init.el in current window."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;; Reload init.el without restarting Emacs.
;; Useful for testing changes, but doesn't reload modules.
(defun suhas/reload-config ()
  "Reload init.el."
  (interactive)
  (load (expand-file-name "init.el" user-emacs-directory))
  (message "Config reloaded."))

;;; ============================================================
;;; CUSTOM FILE — Isolate auto-generated settings
;;; ============================================================

;; When you use M-x customize, Emacs writes settings to custom.el.
;; We redirect it here so init.el stays clean and hand-written.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here

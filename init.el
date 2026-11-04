;;; init.el --- Entry point. Loads modules in dependency order.  -*- lexical-binding: t; -*-
;;; NO configuration lives here. This file is a table of contents.
;;; All actual configuration lives in separate modules.

;; Per-package load timing goes to *Messages*. Turn this off once your
;; startup is tuned (or run `M-x use-package-report' after setting
;; `use-package-compute-statistics' to t for a table of load times).
(setq use-package-verbose t)
;;(setq debug-on-error t)

;; Package signature checking (a security feature) stays ON for signed
;; archives. `allow-unsigned' only tolerates archives that publish no
;; signature (MELPA). The old `nil' disabled verification for GNU/NonGNU
;; ELPA too. If a FRESH machine ever fails with "Failed to verify
;; signature", run:  (setq package-check-signature nil)  once, then
;; M-x package-install RET gnu-elpa-keyring-update, and remove the line.
(setq package-check-signature 'allow-unsigned)

;; Show startup time and package count
(defun suhas/display-startup-time ()
  (message "Emacs loaded %d packages in %.2f seconds with %d garbage collections."
           (length package-activated-list)
           (float-time (time-subtract after-init-time before-init-time))
           gcs-done))
(add-hook 'emacs-startup-hook #'suhas/display-startup-time)

;;; ============================================================
;;; GC RESET — Bring garbage collection back to normal
;;; ============================================================

;; early-init.el set gc-cons-threshold to a huge value to speed up startup.
;; Now that the frame exists and packages are loaded, we reset it to a
;; reasonable value. 8MB is aggressive enough to not cause stuttering
;; but not so aggressive that it pauses during editing.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 8 1024 1024)
                  gc-cons-percentage 0.1)))

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
  "Load modules/NAME.el. An error in one module is REPORTED, not fatal.
Before this, one typo in (say) terminal.el aborted init.el right there
and silently left lsp, langs, magit, org... unloaded."
  (condition-case err
      (load (expand-file-name (concat "modules/" name ".el") user-emacs-directory)
            nil t)
    (error
     (display-warning 'semacs
                      (format "Module `%s' failed to load: %s"
                              name (error-message-string err))
                      :error))))

;;; ============================================================
;;; LOAD ORDER — Matters! Don't reorder casually.
;;; ============================================================

;; 1. CORE — Package manager + sane defaults. Must come first.
(suhas/load-module "core")

;; 2. UI — Themes, fonts, modeline. Loaded early so visuals are ready.
(suhas/load-module "ui")

;; 3. COMPLETION — Vertico, Marginalia, Consult. Minimal but fast.
(suhas/load-module "completion")

;; 3b. SEARCH — Projects, find-file-anywhere, grep, xref, recent files.
;;     Needs consult (completion) and project.el (built in).
(suhas/load-module "search")

;; 4. EVIL — Vim layer. Loaded after UI (needs escape behavior defined).
(suhas/load-module "evil")

;; 5. TERMINAL — ghostel terminal emulator (Windows AND Linux).
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
;; SPC c e: fuzzy-pick ANY file of this config (init.el, modules/*.el,
;; README...) instead of always landing on init.el.
(defun suhas/open-config ()
  "Fuzzy-find a file inside the Emacs config directory."
  (interactive)
  (let ((project-current-directory-override
         (expand-file-name user-emacs-directory)))
    (call-interactively #'project-find-file)))

;; Reload the config without restarting Emacs. init.el re-loads every
;; module, but hooks added with anonymous lambdas get added AGAIN, so
;; after many reloads a restart is the only truly clean slate.
(defun suhas/reload-config ()
  "Reload init.el (and therefore every module)."
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

;; Fresh machine (no custom.el yet) or a saved theme that no longer
;; exists: fall back to a built-in theme instead of the default white.
(unless custom-enabled-themes
  (load-theme 'modus-vivendi t))

;;; init.el ends here

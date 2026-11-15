;;; init.el --- Entry point. Loads modules in dependency order.  -*- lexical-binding: t; -*-
;;; NO configuration lives here. This file is a table of contents.
;;;
;;;   early-init.el   before the frame exists (GC, chrome)
;;;   modules/settings.el   defaults for every knob
;;;   local.el              YOUR overrides (untracked; see local.example.el)
;;;   modules/core.el       package manager + sane defaults
;;;   modules/*.el          one concern each, in the order of `suhas/modules'

;; Per-package load timing goes to *Messages*. Turn this off once your
;; startup is tuned, or use `M-x use-package-report'.
(setq use-package-verbose t)
;;(setq debug-on-error t)

;; Where Customize and package.el write their settings. This MUST be set
;; before the modules run: package.el records `package-selected-packages'
;; right after every install, and with `custom-file' unset it appends them
;; to THIS file. The file is loaded at the very end (see CUSTOM FILE below).
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;;; ============================================================
;;; MODULE LOADER
;;; ============================================================

(defun suhas/load-module (name)
  "Load modules/NAME.el. A missing file or an error is REPORTED, not fatal.
The module's name is remembered in `suhas/failed-modules' for
`suhas/doctor'."
  (let ((file (expand-file-name (concat "modules/" name ".el") user-emacs-directory)))
    (if (not (file-exists-p file))
        (progn
          (add-to-list 'suhas/failed-modules name t)
          (display-warning 'semacs
                           (format "Module `%s' not found: %s does not exist. \
Is the whole modules/ folder from the zip present?" name file)
                           :error))
      (condition-case err
          (load file nil t)
        (error
         (add-to-list 'suhas/failed-modules name t)
         (display-warning 'semacs
                          (format "Module `%s' failed to load: %s"
                                  name (error-message-string err))
                          :error))))))

(defun suhas/load-local ()
  "Load local.el (your machine-specific overrides) if it exists."
  (let ((file (expand-file-name "local.el" user-emacs-directory)))
    (when (file-exists-p file)
      (condition-case err
          (load file nil t)
        (error
         (display-warning 'semacs
                          (format "local.el failed: %s" (error-message-string err))
                          :error))))))

;;; ============================================================
;;; SETTINGS, THEN LOCAL OVERRIDES
;;; ============================================================

(setq suhas/failed-modules nil)
(suhas/load-module "settings")
;; Everything below reads variables that settings.el defines. Without it
;; the config cannot work, so stop with ONE clear message instead of a
;; cascade of "void variable" errors.
(unless (boundp 'suhas/modules)
  (error "semacs: modules/settings.el is missing or failed to load (looked in %s)"
         (expand-file-name "modules/" user-emacs-directory)))
(suhas/load-local)

;; Package signature checking (reasoning: see `suhas/package-check-signature').
(setq package-check-signature suhas/package-check-signature)

;;; ============================================================
;;; STARTUP DIAGNOSTICS AND GC
;;; ============================================================

(defun suhas/display-startup-time ()
  "Report startup time and package count in *Messages*."
  (message "Emacs loaded %d packages in %.2f seconds with %d garbage collections."
           (length package-activated-list)
           (float-time (time-subtract after-init-time before-init-time))
           gcs-done))
(add-hook 'emacs-startup-hook #'suhas/display-startup-time)

;; early-init.el set the GC threshold huge to speed up startup. Now that
;; the frame exists and packages are loaded, bring it back to something
;; reasonable: 8MB is big enough not to stutter, small enough not to pause.
(defun suhas/gc-reset ()
  "Restore normal garbage-collection settings after startup."
  (setq gc-cons-threshold (* 8 1024 1024)
        gc-cons-percentage 0.1))
(add-hook 'emacs-startup-hook #'suhas/gc-reset)

;; Language servers send big JSON blobs; the 4KB default read buffer makes
;; completion and diagnostics chunk constantly.
(setq read-process-output-max (* 1024 1024))

;;; ============================================================
;;; LOAD ORDER — Matters! Don't reorder casually.
;;; ============================================================

;; CORE always loads first and cannot be switched off.
(suhas/load-module "core")

;; Everything else: the list lives in settings.el (override in local.el).
(dolist (module suhas/modules)
  (suhas/load-module module))

;;; ============================================================
;;; CUSTOM FILE — Isolate auto-generated settings
;;; ============================================================

;; M-x customize (and the theme menu) write to custom.el, not to this file.
(when (file-exists-p custom-file)
  (load custom-file))

;; Fresh machine (no custom.el yet) or a saved theme that no longer
;; exists: fall back to a built-in theme instead of the default white.
(unless custom-enabled-themes
  (load-theme suhas/default-theme t))

(when suhas/failed-modules
  (display-warning 'semacs
                   (format "Modules that failed to load: %s. Run M-x suhas/doctor."
                           (mapconcat #'identity suhas/failed-modules ", "))
                   :warning))

;;; init.el ends here

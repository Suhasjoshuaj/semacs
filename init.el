;;; init.el --- Entry point. Loads modules in dependency order.  -*- lexical-binding: t; -*-
;;; NO configuration lives here. This file is a table of contents.
;;;
;;;   early-init.el         before the frame exists (GC, package quickstart, chrome)
;;;   modules/settings.el   defaults for every knob
;;;   modules/windows.el    Windows defaults (loaded on Windows only)
;;;   local.el              YOUR overrides (untracked; see local.example.el)
;;;   modules/core.el       package manager, defaults, leader map, helpers
;;;   modules/*.el          one concern each, in the order of `suhas/modules'

(when (version< emacs-version "31.1")
  (error "semacs needs Emacs 31.1 or newer (this is %s)" emacs-version))

;; Customize and package.el write here, never into this file. ui.el loads
;; it (it holds the saved theme, which must come after the theme options).
(setq custom-file (expand-file-name "custom.el" user-emacs-directory)
      ;; The saved theme is re-enabled without a "really load?" prompt.
      custom-safe-themes t)

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
                           (format "Module `%s' not found: %s does not exist." name file)
                           :error))
      (condition-case err
          (load file nil t)
        (error
         (add-to-list 'suhas/failed-modules name t)
         (display-warning 'semacs
                          (format "Module `%s' failed to load: %s"
                                  name (error-message-string err))
                          :error))))))

(defun suhas/load-optional (file)
  "Load FILE (relative to the config directory) if it exists; report errors."
  (let ((file (expand-file-name file user-emacs-directory)))
    (when (file-exists-p file)
      (condition-case err
          (load file nil t)
        (error
         (display-warning 'semacs
                          (format "%s failed: %s" (file-name-nondirectory file)
                                  (error-message-string err))
                          :error))))))

;;; ============================================================
;;; SETTINGS, PLATFORM DEFAULTS, THEN LOCAL OVERRIDES
;;; ============================================================

(setq suhas/failed-modules nil)
(suhas/load-module "settings")
(unless (boundp 'suhas/modules)
  (error "semacs: modules/settings.el is missing or failed to load (looked in %s)"
         (expand-file-name "modules/" user-emacs-directory)))

;; The ONLY Windows hook-up. To drop Windows: delete this line and
;; modules/windows.el.
(when suhas/windows-p (suhas/load-module "windows"))

(suhas/load-optional "local.el")

;;; ============================================================
;;; STARTUP DIAGNOSTICS AND GC
;;; ============================================================

(defvar suhas--gc-timer nil
  "Idle timer that collects garbage while you are not typing.")

(defun suhas/gc-restore ()
  "Leave startup GC settings: collect rarely, and preferably while idle."
  (setq gc-cons-threshold (* 64 1024 1024)
        gc-cons-percentage 0.1)
  (when (timerp suhas--gc-timer) (cancel-timer suhas--gc-timer))
  (setq suhas--gc-timer (run-with-idle-timer 15 t #'garbage-collect)))
;; Depth -90 (see early-init.el): nothing later on the hook can skip it.
(add-hook 'emacs-startup-hook #'suhas/gc-restore -90)

(defun suhas/display-startup-time ()
  "Report startup time in *Messages*."
  (message "semacs: ready in %.2fs (%d packages, %d GCs)"
           (float-time (time-subtract after-init-time before-init-time))
           (length package-activated-list)
           gcs-done))
(add-hook 'emacs-startup-hook #'suhas/display-startup-time)

;;; ============================================================
;;; LOAD ORDER
;;; ============================================================

;; CORE always loads first and cannot be switched off.
(suhas/load-module "core")

;; Everything else: the list lives in settings.el (override in local.el).
(dolist (module suhas/modules)
  (suhas/load-module module))

(when suhas/failed-modules
  (display-warning 'semacs
                   (format "Modules that failed to load: %s. Run M-x suhas/doctor."
                           (mapconcat #'identity suhas/failed-modules ", "))
                   :warning))

;;; init.el ends here

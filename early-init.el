;;; early-init.el --- Startup performance and GUI chrome removal
;;; This runs BEFORE the main init.el, before the frame even exists.
;;; Use this only for performance tweaks and disabling visual chrome.

;;; ============================================================
;;; GC TUNING — Defer garbage collection during startup
;;; ============================================================

;; Emacs runs garbage collection frequently, which can stall startup.
;; We raise the threshold temporarily, then reset it later in core.el.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;;; ============================================================
;;; DISABLE GUI ELEMENTS — Before the frame renders
;;; ============================================================

;; These must run before the frame is created to avoid visual flash.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

;; Disable startup screen
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name)

;;; ============================================================
;;; NATIVE COMPILATION — Don't block on it during startup
;;; ============================================================

;; Emacs 28+ compiles elisp to native bytecode (faster execution).
;; But the first run blocks startup while it compiles everything.
;; We defer it to the background after startup finishes.
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors nil
        native-compile-target-directory (expand-file-name "eln-cache/" user-emacs-directory)))

;;; ============================================================
;;; FILE-NAME-HANDLER — Suppress during startup
;;; ============================================================

;; Emacs checks EVERY file operation against file-name-handler-alist.
;; This is slow. We save the original list and restore it after startup.
(defvar suhas--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist suhas--file-name-handler-alist)))

;;; early-init.el ends here

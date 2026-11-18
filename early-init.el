;;; early-init.el --- Before the first frame exists  -*- lexical-binding: t; -*-
;;; Only startup performance and frame chrome belong here.

;;; ============================================================
;;; GC — no collections while loading
;;; ============================================================

;; init.el restores both values (`suhas/gc-restore').
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;;; ============================================================
;;; PACKAGE.EL — one precomputed autoload file
;;; ============================================================

;; Emacs activates packages right after this file. With quickstart that is
;; ONE file (package-quickstart.el) instead of one autoload file per
;; package. package.el rewrites it after every install/delete; if it ever
;; goes stale: M-x package-quickstart-refresh.
(setq package-quickstart t)

;;; ============================================================
;;; EVIL — must be set before ANYTHING loads evil
;;; ============================================================

;; evil is byte-compiled (and so loaded) inside package-install on a first
;; start, earlier than modules/evil.el runs.
(setq evil-want-keybinding nil
      evil-want-integration t)

;;; ============================================================
;;; FRAME — no chrome, no resize, no white flash
;;; ============================================================

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

;; Dark until the theme loads a few milliseconds later; ui.el removes
;; these two again so later frames follow the theme.
(push '(background-color . "#0d0e1c") default-frame-alist)
(push '(foreground-color . "#ffffff") default-frame-alist)

;; Setting the font or hiding bars must not resize the frame.
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

(setq inhibit-startup-screen t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      ;; *scratch* in lisp-interaction-mode would pull in the whole
      ;; prog-mode stack (flymake, diff-hl, ...) before the first keypress.
      initial-major-mode 'fundamental-mode)

;;; ============================================================
;;; NATIVE COMPILATION — be quiet
;;; ============================================================

(setq native-comp-async-report-warnings-errors 'silent)

;;; ============================================================
;;; FILE-NAME-HANDLER — skipped while loading
;;; ============================================================

;; Every `load' is matched against `file-name-handler-alist'. Empty it for
;; the duration of init, then merge back (keeping anything a package added).
(defvar suhas--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(defun suhas--restore-file-name-handlers ()
  "Put `file-name-handler-alist' back after startup."
  (setq file-name-handler-alist
        (delete-dups (append file-name-handler-alist
                             suhas--file-name-handler-alist))))
;; Depth -90: runs before anything else on the hook, so an error in a
;; later function can never leave TRAMP and compressed files broken.
(add-hook 'emacs-startup-hook #'suhas--restore-file-name-handlers -90)

(setq warning-suppress-types '((lexical-binding)
                               (files missing-lexbind-cookie)))

;;; early-init.el ends here

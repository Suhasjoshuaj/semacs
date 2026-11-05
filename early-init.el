;;; early-init.el --- Startup performance and GUI chrome removal  -*- lexical-binding: t; -*-
;;; This runs BEFORE the main init.el, before the frame even exists.
;;; Use this only for performance tweaks and disabling visual chrome.

;;; ============================================================
;;; GC TUNING — Defer garbage collection during startup
;;; ============================================================

;; Raise the GC limits while loading. init.el puts BOTH back afterwards.
;; (Previously only gc-cons-threshold was restored: gc-cons-percentage
;; stayed at 0.6 forever, which lets the heap balloon before a GC runs
;; and makes each GC a longer visible stall.)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Never load a stale .elc over a newer .el.
(setq load-prefer-newer t)

;;; ============================================================
;;; PACKAGE.EL — activate once, not twice
;;; ============================================================

;; Emacs would call (package-activate-all) after this file, and core.el
;; then calls (package-initialize) again: the whole elpa/ directory was
;; scanned twice on every start. core.el does it explicitly, so turn the
;; automatic one off.
(setq package-enable-at-startup nil)

;;; ============================================================
;;; EVIL — must be set before ANYTHING loads evil
;;; ============================================================

;; evil-collection warns if `evil-want-keybinding' is nil but evil was
;; already loaded with it on. That happened during a first install: evil
;; gets byte-compiled (and so loaded) inside package-install, earlier than
;; the `:init' in modules/evil.el runs. Setting both here, before any
;; package work, makes it impossible. (modules/evil.el sets them again,
;; which is harmless.)
(setq evil-want-keybinding nil
      evil-want-integration t)

;;; ============================================================
;;; DISABLE GUI ELEMENTS — Before the frame renders
;;; ============================================================

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(horizontal-scroll-bars) default-frame-alist)

(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name)

;;; ============================================================
;;; NATIVE COMPILATION — be quiet
;;; ============================================================

;; Native compilation is ALREADY asynchronous; it never blocks startup.
;; All we want is to not be interrupted by its warnings about other
;; people's packages. (The eln-cache already lives in
;; user-emacs-directory by default, so no redirect is needed.)
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors 'silent))

;;; ============================================================
;;; FILE-NAME-HANDLER — Suppress during startup
;;; ============================================================

;; Every file operation is checked against file-name-handler-alist, which
;; is slow while loading dozens of files. Empty it, then restore it.
(defvar suhas--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda ()
            ;; MERGE rather than overwrite, so a handler some package
            ;; registered during init is not thrown away.
            (setq file-name-handler-alist
                  (delete-dups (append file-name-handler-alist
                                       suhas--file-name-handler-alist)))))

;; Quiet the missing-lexical-binding-cookie warning (one list; the old
;; file had two setq's and the second silently overwrote the first).
(setq warning-suppress-types '((lexical-binding)
                               (files missing-lexbind-cookie)))

;;; early-init.el ends here

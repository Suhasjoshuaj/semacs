;;; core.el --- Package manager and sane defaults
;;; This loads FIRST. Everything else depends on this.

;;; ---------------------------------------------------------------------------
;;; Default Directory
;;; ---------------------------------------------------------------------------

;; Start Emacs in the user's home directory instead of the installation directory.
(when (string-prefix-p
       (expand-file-name invocation-directory)
       default-directory)
  (setq default-directory
        (expand-file-name "~")))

(add-hook
 'emacs-startup-hook
 (lambda ()
   ;; Change the process working directory once.
   (cd (expand-file-name "~"))))
;;; ============================================================
;;; PACKAGE MANAGER — Use built-in package.el + use-package
;;; ============================================================

;; Emacs has a built-in package manager. No external dependency needed.
;; We tell it where to find packages (MELPA for bleeding-edge, GNU for stable).
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
(package-initialize)
 

;; use-package is a macro that makes package declarations clean and readable.
;; It's part of Emacs 29+, but we ensure it's installed for older versions.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Enable use-package globally. This makes every (use-package ...) work.
(require 'use-package)
(setq use-package-always-ensure t)  ; Auto-install packages if missing

;; Windows pinger
(defconst suhas/windows-p (eq system-type 'windows-nt)
  "Non-nil when running native Windows Emacs (not WSL).")

;;; ============================================================
;;; PERFORMANCE TUNING
;;; ============================================================

;; exec-path-from-shell: Copy PATH from your shell to Emacs.
;; Without this, language servers (clangd, rust-analyzer, etc) aren't found.
(if suhas/windows-p
    (setq shell-file-name "C:/Program Files/Git/bin/bash.exe"
          shell-command-switch "-c")
  (use-package exec-path-from-shell
    :init
    (exec-path-from-shell-initialize)))

;;; ============================================================
;;; ENCODING — UTF-8 everywhere
;;; ============================================================

;; Make sure Emacs speaks UTF-8 in all contexts.
;; This is non-negotiable in 2025.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;;; ============================================================
;;; FILE ORGANIZATION — No scattered backup files
;;; ============================================================

;; By default, Emacs scatters backup files, auto-saves, and lock files
;; throughout your project directories. This centralizes them in .config/emacs/.

;; Backups (~ files)
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory))))

;; Auto-saves (when you haven't explicitly saved)
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))

;; Lock files (prevent editing the same file twice)
(setq lock-file-name-transforms
      `((".*" ,(expand-file-name "locks/" user-emacs-directory) t)))

;; Create those directories if they don't exist
(dolist (dir '("backups" "auto-saves" "locks"))
  (make-directory (expand-file-name dir user-emacs-directory) t))

;;; ============================================================
;;; AUTO-REVERT — Reload files changed on disk
;;; ============================================================

;; If you (or git) modifies a file while Emacs has it open,
;; automatically reload it without asking. Very convenient.
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)  ; Don't spam the message buffer

;; Follow symlinks without asking. Needed for git repos and monorepos.
(setq vc-follow-symlinks t)

;;; ============================================================
;;; INTERACTION — Short answers and helpful defaults
;;; ============================================================

;; Type "y" or "n" instead of "yes" or "no". Faster.
(setq use-short-answers t)

;; Highlight matching parens instantly, no delay.
;; Your eye immediately sees { ... } pairs.
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Don't ring the bell. Ever. Visual feedback is fine.
(setq ring-bell-function 'ignore)

;;; ============================================================
;;; EDITING — Sane defaults
;;; ============================================================

;; Tabs should be spaces. 4-space indentation everywhere.
;; This is a convention, adjust to your project's style.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Single space after a period. (Typewriters needed two; we don't.)
(setq sentence-end-double-space nil)

;; Larger undo history. You will thank this when you need to undo 20 steps back.
(setq undo-limit (* 10 1024 1024)           ; 10MB
      undo-strong-limit (* 15 1024 1024))   ; 15MB

;; CLipboard sense
(setq select-enable-clipboard t)
(setq select-enable-primary t)

;;; ============================================================
;;; SCROLLING — Smooth and predictable
;;; ============================================================

;; Don't scroll the window wildly when you move the cursor.
;; Keep 5 lines of context above/below the cursor at all times.
(setq scroll-margin 5
      scroll-conservatively 10000  ; Prefer moving point over scrolling window
      scroll-step 1)

;; Emacs 29+: Smooth pixel-level scrolling instead of line-at-a-time jumps.
(pixel-scroll-precision-mode 1)

;;; ============================================================
;;; HELP AND NAVIGATION
;;; ============================================================

;; When Emacs tries to guess "which function am I in?",
;; be explicit about it instead of guessing from indentation.
(setq which-func-unknown "")

;; Kill the entire buffer, not just the window.
;; Prevents orphaned buffers.
(setq kill-buffer-delete-windows t)

;;; ============================================================
;;; SHARED HELPERS — used by terminal.el, buffer-nav.el, window-mgmt.el
;;; ============================================================
;; These live here (loaded first) rather than in whichever module
;; "owns" the concept, so no later module has to forward-reference a
;; function from a module that hasn't loaded yet. terminal.el in
;; particular loads before both buffer-nav.el and window-mgmt.el.

(defun suhas/persp-buffer-p (buf)
  "Non-nil if BUF belongs to the current perspective.
Degrades to always-t when `persp-mode' isn't on, so callers don't need
to special-case a perspective-less setup."
  (if (bound-and-true-p persp-mode)
      (persp-is-current-buffer buf)
    t))

(defun suhas/mru-step (pool direction &optional skip-p)
  "Step to the next/previous buffer in POOL relative to `current-buffer'.

Looks at buffer-list order (most-recently-used first), so repeated
calls in the same DIRECTION ('next or 'prev) walk POOL like Alt-Tab
rather than looping between the same two buffers: each call finds
where `current-buffer' now sits and steps one further.

SKIP-P, if given, is called with each candidate buffer and should
return non-nil to skip it. Falls back to `current-buffer' if nothing
in POOL qualifies."
  (let ((pos (seq-position pool (current-buffer))))
    (if (not pos)
        (or (seq-find (lambda (b) (not (and skip-p (funcall skip-p b)))) pool)
            (current-buffer))
      (let* ((remaining (if (eq direction 'next)
                             (nthcdr (1+ pos) pool)
                           (reverse (take pos pool))))
             (wrapped (if (eq direction 'next)
                          (take (1+ pos) pool)
                        (reverse (nthcdr pos pool))))
             (search-list (append remaining wrapped)))
        (or (seq-find (lambda (b) (not (and skip-p (funcall skip-p b)))) search-list)
            (current-buffer))))))

;;; core.el ends here

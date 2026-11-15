;;; core.el --- Package manager and sane defaults  ... -*- lexical-binding: t; -*-
;;; This loads FIRST (after settings.el and local.el). Everything depends on it.

;;; ---------------------------------------------------------------------------
;;; Default Directory
;;; ---------------------------------------------------------------------------

;; Start Emacs in the user's home directory instead of the installation directory.
(when (string-prefix-p
       (expand-file-name invocation-directory)
       default-directory)
  (setq default-directory
        (expand-file-name "~")))

;; Only the *scratch* buffer gets ~ as its directory. (Changing the current
;; buffer's directory at startup would break project.el for a file passed on
;; the command line: `emacs ~/code/proj/main.c'.)
(defun suhas/scratch-to-home ()
  "Give *scratch* the home directory as `default-directory'."
  (when-let* ((scratch (get-buffer "*scratch*")))
    (with-current-buffer scratch
      (setq default-directory (file-name-as-directory (expand-file-name "~"))))))
(add-hook 'emacs-startup-hook #'suhas/scratch-to-home)

;;; ============================================================
;;; PACKAGE MANAGER — Use built-in package.el + use-package
;;; ============================================================

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/"))
;; MELPA versions are date-stamped snapshots, so they ALWAYS outrank the
;; released versions on GNU/NonGNU ELPA and everything (vertico, consult,
;; corfu...) silently tracked bleeding-edge master. Prefer the stable
;; archives; MELPA is still used for packages only it has (ghostel, ...).
(setq package-archive-priorities
      '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10)))
(package-initialize)

;; Windows: Emacs usually does not have Git's `cmd' directory on exec-path,
;; and package.el needs `git' to install version-pinned packages (ghostel).
;; This runs before any package is installed.
(when (and suhas/windows-p suhas/git-for-windows-root)
  (let ((git-cmd (expand-file-name "cmd" suhas/git-for-windows-root)))
    (when (file-directory-p git-cmd)
      (add-to-list 'exec-path git-cmd)
      (setenv "PATH" (concat (subst-char-in-string ?/ ?\\ git-cmd)
                             ";" (or (getenv "PATH") ""))))))

;; use-package is built in since Emacs 29; this only matters on older ones.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)  ; Auto-install packages if missing

;;; ============================================================
;;; ENVIRONMENT — PATH, proxies, etc. from your login shell
;;; ============================================================

;; Without this, a GUI Emacs launched from a desktop icon has a bare PATH:
;; language servers (clangd, pyright...) and `git' hooks are not found, and
;; behind a corporate proxy nothing can download. A terminal-launched Emacs
;; already inherits all of it, so it is skipped there (saves a login-shell
;; spawn, usually the biggest chunk of init time).
(cond
 (suhas/windows-p
  (let ((bash (and suhas/windows-use-git-bash suhas/git-for-windows-root
                   (expand-file-name "bin/bash.exe" suhas/git-for-windows-root))))
    (when (and bash (file-exists-p bash))
      (setq shell-file-name bash
            shell-command-switch "-c"))))
 ((or initial-window-system (daemonp))
  (use-package exec-path-from-shell
    :init
    (setq exec-path-from-shell-variables suhas/shell-env-variables)
    (exec-path-from-shell-initialize))))

;;; ============================================================
;;; ENCODING — UTF-8 everywhere
;;; ============================================================

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

;;; ============================================================
;;; FILE ORGANIZATION — No scattered backup files
;;; ============================================================

;; By default Emacs scatters backups, auto-saves and lock files through your
;; project directories (where they end up in `git status'). Centralise them.
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(setq lock-file-name-transforms
      `((".*" ,(expand-file-name "locks/" user-emacs-directory) t)))
(dolist (dir '("backups" "auto-saves" "locks"))
  (make-directory (expand-file-name dir user-emacs-directory) t))

;; Back up by copying, so symlinks and hard links in a repo are never
;; replaced by a renamed backup file.
(setq backup-by-copying t)

;;; ============================================================
;;; AUTO-REVERT — Reload files changed on disk
;;; ============================================================

;; If git, a formatter or an AI agent (Claude Code!) modifies a file that is
;; open in Emacs, reload it automatically (unless you have unsaved edits).
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)
(setq vc-follow-symlinks t)

;;; ============================================================
;;; INTERACTION
;;; ============================================================

(setq use-short-answers t)
(setq show-paren-delay 0)
(show-paren-mode 1)
(setq ring-bell-function 'ignore)

;;; ============================================================
;;; EDITING
;;; ============================================================

;; Spaces, 4 wide. A project's .editorconfig (see devtools.el) overrides
;; this per project; major modes like go-mode and makefile-mode keep their
;; own rules.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; POSIX wants a final newline; git shows "\ No newline at end of file"
;; diffs without one.
(setq require-final-newline t)

(setq sentence-end-double-space nil)

(setq undo-limit (* 10 1024 1024)
      undo-strong-limit (* 15 1024 1024))

(setq select-enable-clipboard t)
(setq select-enable-primary t)

(electric-pair-mode 1)

(setq which-func-unknown "")

;; (Scroll behaviour lives in ui.el.)

;;; ============================================================
;;; SHARED HELPERS — used by terminal.el, buffer-nav.el, window-mgmt.el ...
;;; ============================================================
;; These live here (loaded first) so no later module has to forward-reference
;; a function from a module that hasn't loaded yet.

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
calls in the same DIRECTION (\='next or \='prev) walk POOL like Alt-Tab
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

(defun suhas/project-dir ()
  "Root of the current project, or `default-directory' outside one."
  (if-let* ((pr (project-current)))
      (project-root pr)
    default-directory))

;;; ============================================================
;;; CONFIG MANAGEMENT — open and reload this config
;;; ============================================================

(defun suhas/open-config ()
  "Fuzzy-find a file inside the Emacs config directory (SPC c e)."
  (interactive)
  (let ((dir (expand-file-name user-emacs-directory)))
    (if (project-current nil dir)
        (let ((project-current-directory-override dir))
          (call-interactively #'project-find-file))
      ;; Not a git repo / no .project marker: plain file picker.
      (let ((default-directory dir))
        (call-interactively #'find-file)))))

(defun suhas/open-local ()
  "Open local.el (your machine-specific settings), creating it from the template."
  (interactive)
  (let ((local (expand-file-name "local.el" user-emacs-directory))
        (example (expand-file-name "local.example.el" user-emacs-directory)))
    (when (and (not (file-exists-p local)) (file-exists-p example))
      (copy-file example local))
    (find-file local)))

(defun suhas/reload-config ()
  "Reload init.el (and therefore settings, local.el and every module).
Hooks and advice in this config are all named functions, so reloading does
not stack duplicates; a restart is still the only truly clean slate."
  (interactive)
  (load (expand-file-name "init.el" user-emacs-directory))
  (message "Config reloaded."))

;;; core.el ends here

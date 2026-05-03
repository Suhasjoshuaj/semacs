;;; core.el --- Performance, package management, sane defaults
;;; This is the first thing Emacs loads. Keep it lean.

;;; ============================================================
;;; SECTION 1: STARTUP PERFORMANCE
;;; ============================================================

;; During startup, raise GC threshold to 50MB so Emacs doesn't
;; pause to garbage collect while loading packages.
;; We reset it after startup via a hook.
(setq gc-cons-threshold (* 50 1000 1000))

;; LSP servers (eglot) send large JSON blobs.
;; Default read size is 4KB which causes constant chunking.
;; 1MB handles even heavy LSP payloads cleanly.
(setq read-process-output-max (* 1024 1024))

;; After startup is fully done, bring GC back to a sane value.
;; 8MB is a good balance — aggressive enough to not lag, not so
;; aggressive that it pauses mid-edit.
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 8 1000 1000))))

;;; ============================================================
;;; SECTION 2: ELPACA — ASYNC PACKAGE MANAGER
;;; ============================================================

;; Bootstrap elpaca if it isn't installed yet.
;; This block is safe to run every startup — it's a no-op if
;; elpaca is already present. On a fresh machine (after cloning
;; your config), this will fetch and install elpaca automatically.

;; Elpaca Installer -*- lexical-binding: t; -*-
;; Copy below this line into your init.el
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Make elpaca work with use-package syntax.
;; This lets you write (use-package foo) and elpaca handles the install.
(elpaca elpaca-use-package
  (elpaca-use-package-mode))

;;; ============================================================
;;; SECTION 3: SANE DEFAULTS
;;; ============================================================

;; get absolute paths
(use-package exec-path-from-shell
  :ensure t
  :config
  (exec-path-from-shell-initialize))

;; UTF-8 everywhere. Non-negotiable in 2025.
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

;; Stop Emacs from littering your project directories with backup
;; and lock files. Centralize them instead.
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory))))
(setq auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t)))
(setq lock-file-name-transforms
      `((".*" ,(expand-file-name "locks/" user-emacs-directory) t)))

;; Create those directories if they don't exist yet.
(dolist (dir '("backups" "auto-saves" "locks"))
  (make-directory (expand-file-name dir user-emacs-directory) t))

;; When a file changes on disk (git checkout, external edit),
;; automatically reload it in Emacs without asking.
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil) ; Don't announce every revert

;; Follow symlinks into version-controlled repos without asking.
(setq vc-follow-symlinks t)

;; Short answers. Type y/n instead of yes/no.
(setq use-short-answers t)

;; When you open a file and it has a matching paren/bracket,
;; highlight the pair immediately (no delay).
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Tabs are spaces. 4 spaces wide. Consistent across all modes.
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; Single space after period. Emacs was written when typewriters
;; used two spaces. We don't.
(setq sentence-end-double-space nil)

;; Keep the cursor away from the very edge of the screen.
;; Scrolling stays smooth because Emacs looks ahead.
(setq scroll-margin 5
      scroll-conservatively 10000
      scroll-step 1)

;; Don't ring the bell. Ever.
(setq ring-bell-function 'ignore)

;; Larger undo history. You will thank this setting someday.
(setq undo-limit (* 10 1024 1024))       ; 10MB
(setq undo-strong-limit (* 15 1024 1024)) ; 15MB

;; When Emacs asks "which function am I in?", tell it to look
;; at the actual function definition, not just guess from indent.
(setq which-func-unknown "")

;;; core.el ends here

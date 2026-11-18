;;; core.el --- Package manager, defaults, leader map, shared helpers  -*- lexical-binding: t; -*-
;;; Loads FIRST (after settings.el and local.el). Everything depends on it.

;; Platform module (modules/windows.el) setup, now that local.el was read.
(run-hooks 'suhas/platform-setup-hook)

;;; ============================================================
;;; PACKAGE MANAGER — built-in package.el + use-package
;;; ============================================================

;; package.el itself is NOT loaded on a normal start (it is big): the
;; quickstart file has already put every installed package on the load
;; path. It is only pulled in when something has to be installed.
(setq package-archives suhas/package-archives
      ;; MELPA versions are date-stamped snapshots and would always outrank
      ;; the released versions on GNU/NonGNU ELPA. Prefer releases.
      package-archive-priorities '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10))
      package-check-signature suhas/package-check-signature)

;; Emacs activates packages itself before init.el (see early-init.el).
;; This only matters when the config is loaded by hand (emacs -q -l init.el).
(unless (bound-and-true-p package--activated)
  (package-activate-all))

(setq use-package-always-ensure t   ; install what is missing
      use-package-always-defer t)   ; load nothing until it is needed

(defvar suhas--package-install-failed nil
  "Non-nil once a package failed to install in this session.")

(defun suhas/--package-available-p (package)
  "Non-nil if PACKAGE is in the archive listings, fetching them if needed.
The fetch is abandoned after 30 seconds, so a dead network or a
blocking proxy cannot hang the start."
  (require 'package)
  (unless package--initialized (package-initialize t))
  (unless (assq package package-archive-contents)
    (message "semacs: fetching package lists...")
    (with-timeout (30 nil)
      (ignore-errors (package-refresh-contents))))
  (assq package package-archive-contents))

(defun suhas/ensure-package (name args state &optional _no-refresh)
  "Install package NAME if it is missing; the `use-package-ensure-function'.
An activated package costs one `memq' (package.el is not even loaded).
After ONE failure the remaining installs of this session are skipped:
without that, an unreachable archive is retried for every missing package."
  (dolist (ensure args)
    (let ((package (if (eq ensure t) name ensure)))
      (when (consp package) (setq package (car package)))
      (when (and package (symbolp package)
                 (not (memq package package-activated-list))
                 (not suhas--package-install-failed))
        (when (suhas/--package-available-p package)
          (use-package-ensure-elpa name (list ensure) state t))
        (unless (package-installed-p package)
          (setq suhas--package-install-failed t)
          (display-warning
           'semacs
           (format "Could not install `%s' (no network, or a proxy in the way?). \
Skipping the remaining package installs; restart Emacs once the archives are reachable." package)
           :warning))))))
(setq use-package-ensure-function #'suhas/ensure-package)

;;; ============================================================
;;; FIRST INPUT — things nobody needs before the first keypress
;;; ============================================================

(defvar suhas/first-input-hook nil
  "Functions run ONCE: before your first command, or after half a second of
idle time, whichever comes first. Completion UI, which-key and friends are
switched on here instead of during startup.")

(defun suhas/--run-first-input ()
  "Run `suhas/first-input-hook' once; one failing function never blocks the rest."
  (remove-hook 'pre-command-hook #'suhas/--run-first-input)
  (let ((functions suhas/first-input-hook))
    (setq suhas/first-input-hook nil)
    (dolist (fn (reverse functions))
      (with-demoted-errors "semacs first-input: %S"
        (funcall fn)))))
(add-hook 'pre-command-hook #'suhas/--run-first-input)
(run-with-idle-timer 0.5 nil #'suhas/--run-first-input)

;;; ============================================================
;;; ENVIRONMENT — PATH, proxies etc. from your login shell, cached
;;; ============================================================

;; A GUI Emacs started from a desktop icon has a bare PATH: language
;; servers, git hooks and agents are not found. Asking a login shell costs
;; 0.2-1s on EVERY start, so the answer is cached in env-cache.el and only
;; asked again when a shell startup file is newer than the cache.

(use-package exec-path-from-shell
  :commands (exec-path-from-shell-copy-envs))

(defconst suhas/env-cache-file
  (expand-file-name "env-cache.el" user-emacs-directory)
  "Cache of the variables in `suhas/shell-env-variables'.")

(defun suhas/--env-apply (pairs)
  "Set each (NAME . VALUE) of PAIRS in Emacs's environment."
  (dolist (pair pairs)
    (let ((name (car pair)) (value (cdr pair)))
      (cond
       ((null value))
       ;; A socket path is per login session: never replace a live one,
       ;; never install a dead one.
       ((equal name "SSH_AUTH_SOCK")
        (when (and (not (getenv name)) (file-exists-p value))
          (setenv name value)))
       (t
        (setenv name value)
        (when (equal name "PATH")
          (setq exec-path (append (parse-colon-path value)
                                  (list exec-directory)))))))))

(defun suhas/--env-cache-read ()
  "Return the cached plist (:variables NAMES :env PAIRS), or nil."
  (when (file-readable-p suhas/env-cache-file)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents suhas/env-cache-file)
        (read (current-buffer))))))

(defun suhas/--env-cache-stale-p (cache)
  "Non-nil if CACHE is missing, for other variables, or older than a shell rc file."
  (let ((cached-at (file-attribute-modification-time
                    (file-attributes suhas/env-cache-file))))
    (or (null cache)
        (not (equal (plist-get cache :variables) suhas/shell-env-variables))
        (seq-some (lambda (rc)
                    (when-let* ((changed (file-attribute-modification-time
                                          (file-attributes
                                           (file-truename (expand-file-name rc "~"))))))
                      (time-less-p cached-at changed)))
                  '(".profile" ".bash_profile" ".bashrc" ".zshenv" ".zprofile"
                    ".zshrc" ".config/fish/config.fish")))))

(defun suhas/env-refresh ()
  "Import `suhas/shell-env-variables' from your login shell and cache them."
  (interactive)
  (let ((pairs (exec-path-from-shell-copy-envs suhas/shell-env-variables)))
    (with-temp-file suhas/env-cache-file
      (insert ";; Written by suhas/env-refresh. Delete to force a re-import.\n")
      (prin1 (list :variables suhas/shell-env-variables :env pairs)
             (current-buffer))
      (insert "\n"))
    (when (called-interactively-p 'interactive)
      (message "Environment imported from your login shell"))))

(when (and suhas/shell-env-variables
           (or initial-window-system (daemonp)))
  (let ((cache (suhas/--env-cache-read)))
    (if (suhas/--env-cache-stale-p cache)
        (with-demoted-errors "semacs env import: %S"
          (suhas/env-refresh))
      (suhas/--env-apply (plist-get cache :env)))))

;;; ============================================================
;;; ENCODING — UTF-8 everywhere
;;; ============================================================

(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;;; ============================================================
;;; FILES — no litter in project directories
;;; ============================================================

(setq backup-directory-alist
      `(("." . ,(expand-file-name "backups/" user-emacs-directory)))
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-saves/" user-emacs-directory) t))
      lock-file-name-transforms
      `((".*" ,(expand-file-name "locks/" user-emacs-directory) t))
      ;; Copy, so symlinks and hard links in a repo are never replaced.
      backup-by-copying t)
(dolist (dir '("backups" "auto-saves" "locks"))
  (make-directory (expand-file-name dir user-emacs-directory) t))

;; This config is your own code: let Flymake check it. (Emacs disables
;; Elisp diagnostics in files it has not been told to trust.)
(add-to-list 'trusted-content
             (file-name-as-directory (abbreviate-file-name user-emacs-directory)))

;; Git is the only version control system looked for. The default list
;; probes eight others on every file open (slow, slower over TRAMP).
(setq vc-handled-backends '(Git)
      vc-follow-symlinks t)

;;; ============================================================
;;; AUTO-REVERT — reload files changed on disk
;;; ============================================================

;; When git, a formatter or a coding agent rewrites a file that is open,
;; the buffer follows (unless it has unsaved edits). File notifications
;; make that immediate; polling stays off where notifications work.
(setq auto-revert-verbose nil
      auto-revert-avoid-polling t)
(add-hook 'suhas/first-input-hook #'global-auto-revert-mode)

;;; ============================================================
;;; HEAVY BUFFERS — stay responsive
;;; ============================================================

;; Language servers and terminals talk in big chunks.
(setq read-process-output-max (* 4 1024 1024)
      process-adaptive-read-buffering nil)

;; Left-to-right text only: skips the bidirectional reordering scan, the
;; single biggest cost of very long lines.
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)
(setq bidi-inhibit-bpa t)

(setq fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t
      jit-lock-defer-time 0
      large-file-warning-threshold (* 50 1024 1024))

;; Minified files and logs with enormous lines: switch off the expensive
;; minor modes there instead of freezing.
(add-hook 'suhas/first-input-hook #'global-so-long-mode)

;;; ============================================================
;;; INTERACTION AND EDITING
;;; ============================================================

(setq use-short-answers t
      use-dialog-box nil
      ring-bell-function #'ignore
      show-paren-delay 0
      sentence-end-double-space nil
      ;; POSIX wants a final newline; git flags its absence in every diff.
      require-final-newline t
      undo-limit (* 10 1024 1024)
      undo-strong-limit (* 15 1024 1024)
      select-enable-clipboard t
      select-enable-primary t
      which-func-unknown "")

;; Pop-up buffers (help, grep results, a file opened from the terminal
;; panel) go to ANOTHER existing window instead of splitting again. A split
;; only happens when the frame has no other usable window.
(defun suhas/display-in-other-window (buffer alist)
  "`display-buffer' action: show BUFFER in the least recently used other window."
  (when-let* ((win (get-lru-window nil nil t)))
    (window--display-buffer buffer win 'reuse alist)))

(setq display-buffer-base-action
      '((display-buffer-reuse-window suhas/display-in-other-window)))

;; Spaces, 4 wide. A project's .editorconfig overrides this per project;
;; go-ts-mode and makefile-mode keep their own (tab) rules.
(setq-default indent-tabs-mode nil
              tab-width 4)

(electric-pair-mode 1)
(repeat-mode 1)

;; M-x compile: follow the output, jump to the first error, render colours.
(setq compilation-ask-about-save nil
      compilation-auto-jump-to-first-error t)
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

;; which-key (built in): shows what can follow SPC or any prefix.
(setq which-key-idle-delay 0.5)
(add-hook 'suhas/first-input-hook #'which-key-mode)

;;; ============================================================
;;; LEADER — one keymap, reachable everywhere
;;; ============================================================

;; `suhas/leader-map' holds every SPC binding. It is a plain keymap, so it
;; works with or without Evil:
;;   SPC       in Evil's normal / visual / motion state      (evil.el)
;;   SPC       in dired and magit buffers                    (evil.el)
;;   C-c SPC   everywhere: insert state, terminals, Vim mode off

(defvar-keymap suhas/leader-map
  :doc "Every leader (SPC) binding of this config.")

(defun suhas/leader (&rest bindings)
  "Bind KEY DEFINITION pairs in `suhas/leader-map'.
KEY is a string such as \"f f\". DEFINITION is a command, or a STRING that
names the prefix KEY for which-key: (suhas/leader \"f\" \"files\")."
  (while bindings
    (let ((key (pop bindings))
          (def (pop bindings)))
      (if (stringp def)
          (let ((existing (keymap-lookup suhas/leader-map key)))
            (keymap-set suhas/leader-map key
                        (cons def (if (keymapp existing) existing
                                    (make-sparse-keymap)))))
        (keymap-set suhas/leader-map key def)))))

(keymap-global-set "C-c SPC" suhas/leader-map)

;;; ============================================================
;;; SHARED HELPERS — used by terminal.el, buffer-nav.el, completion.el ...
;;; ============================================================

(defun suhas/persp-buffer-p (buf)
  "Non-nil if BUF belongs to the current perspective.
Always t when `persp-mode' is off, so callers need no special case."
  (if (bound-and-true-p persp-mode)
      (persp-is-current-buffer buf)
    t))

(defun suhas/terminal-buffer-p (buf)
  "Non-nil if BUF is a live terminal (ghostel) buffer."
  (and (buffer-live-p buf)
       (provided-mode-derived-p (buffer-local-value 'major-mode buf)
                                'ghostel-mode)))

(defun suhas/project-dir ()
  "Root of the current project, or `default-directory' outside one."
  (if-let* ((pr (project-current)))
      (project-root pr)
    default-directory))

(defun suhas/kill-buffer-here ()
  "Kill this buffer (SPC k). In magit buffers, also restore the window
layout from before magit opened."
  (interactive)
  (if (derived-mode-p 'magit-mode)
      (magit-mode-bury-buffer t)
    (kill-current-buffer)))

(defun suhas/location ()
  "`path:line' of point relative to the project root (`path:first-last'
with an active region)."
  (unless buffer-file-name
    (user-error "This buffer is not visiting a file"))
  (let ((path (file-relative-name buffer-file-name (suhas/project-dir))))
    (if (use-region-p)
        (format "%s:%d-%d" path
                (line-number-at-pos (region-beginning) t)
                (line-number-at-pos (max (region-beginning) (1- (region-end))) t))
      (format "%s:%d" path (line-number-at-pos nil t)))))

(defun suhas/copy-location ()
  "Copy `path:line' of point to the kill ring (SPC f y).
For a review comment, a commit message or a coding agent's prompt."
  (interactive)
  (let ((ref (suhas/location)))
    (kill-new ref)
    (message "Copied %s" ref)))

;;; ============================================================
;;; CONFIG MANAGEMENT — open and reload this config
;;; ============================================================

(defvar project-current-directory-override)

(defun suhas/open-config ()
  "Fuzzy-find a file inside the Emacs config directory (SPC c e)."
  (interactive)
  (let ((dir (expand-file-name user-emacs-directory)))
    (if (project-current nil dir)
        (let ((project-current-directory-override dir))
          (call-interactively #'project-find-file))
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

(defun suhas/open-keys ()
  "Open the key cheat sheet, KEYS.org (SPC c k)."
  (interactive)
  (find-file (expand-file-name "KEYS.org" user-emacs-directory)))

(defun suhas/reload-config ()
  "Reload init.el (settings, local.el and every module).
Hooks and advice are named functions, so reloading does not stack
duplicates; a restart is still the only truly clean slate."
  (interactive)
  (load (expand-file-name "init.el" user-emacs-directory))
  (message "Config reloaded."))

(suhas/leader
 "c"   "config"
 "c k" #'suhas/open-keys
 "c e" #'suhas/open-config
 "c o" #'suhas/open-local
 "c r" #'suhas/reload-config
 "k"   #'suhas/kill-buffer-here)

;;; core.el ends here

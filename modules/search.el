;;; search.el --- Find files, projects, text and definitions  -*- lexical-binding: t; -*-
;;;
;;; THE MENTAL MODEL (read this once, it replaces three overlapping systems)
;;;
;;;   project.el owns  "WHICH project am I in, and which FILE inside it"
;;;       SPC p p   switch project (new repos are discovered automatically)
;;;       SPC p f   fuzzy-find a file in the current project
;;;
;;;   consult owns     "search ACROSS many files / INSIDE files"
;;;       SPC s f   find a file by NAME in ALL your repos   (fd)
;;;       SPC s g   grep inside the current project         (ripgrep)
;;;       SPC s G   grep inside ALL your repos              (ripgrep)
;;;       SPC s s   search the current buffer               (consult-line)
;;;       SPC s i   jump to a symbol in this file           (imenu)
;;;
;;;   recent files:   SPC SPC (also lists recent files) or SPC f r
;;;   definitions:    gd or M-. (jump)   M-, (jump back)   M-? (references)
;;;
;;; A "project" = any folder containing .git OR an empty file named
;;; .project (SPC p n creates it; use it for folders that are not git
;;; repos, e.g. a flat ~/cpp practice folder).

;;; ============================================================
;;; WHERE YOUR REPOS LIVE  -- edit this list
;;; ============================================================

(defvar suhas/repo-root-candidates
  '("~/code" "~/projects" "~/dev" "~/src" "~/repos" "~/work"
    "~/cpp" "~/org" "~/.emacs.d")
  "Folders that CONTAIN your repos (each child folder is a project), or
that are themselves a project. Folders that don't exist are ignored, so
this list can safely name places that exist on only one of your machines.
Used by: SPC p p (project discovery), SPC s f, SPC s g/G, magit repo list.")

(defun suhas/repo-roots ()
  "Existing directories from `suhas/repo-root-candidates' (re-checked each call)."
  (seq-filter #'file-directory-p
              (mapcar #'expand-file-name suhas/repo-root-candidates)))

;;; ============================================================
;;; PROJECT.EL
;;; ============================================================

(use-package project
  :ensure nil
  :custom
  (project-list-file (expand-file-name "projects" user-emacs-directory))
  ;; A folder with this file is a project even without git (project.el
  ;; picks the NEAREST marker or .git above the file). Deliberately NOT
  ;; package.json / Makefile / ...: in a monorepo (several services each
  ;; with a package.json) those would split one repo into many projects.
  (project-vc-extra-root-markers '(".project"))
  ;; After switching, go straight to the file list. (The default pops up
  ;; a "[f] Find file [g] Find regexp ..." menu you had to answer first.)
  (project-switch-commands #'project-find-file))

(defun suhas/project-rescan ()
  "Register every project found directly inside `suhas/repo-roots'.
project.el only learns about a project when you run a project command in
it, so a freshly cloned or created repo was invisible to the project
list. This is cheap (one directory listing per root), so SPC p p simply
does it on every call."
  (interactive)
  (require 'project)
  (let ((known (project-known-project-roots))
        (added 0))
    (dolist (root (suhas/repo-roots))
      (dolist (dir (cons root (directory-files
                               root t directory-files-no-dot-files-regexp)))
        (when (file-directory-p dir)
          (when-let* ((pr (project-current nil dir))
                      (pr-root (project-root pr)))
            ;; Only the folder itself: a plain subfolder of some repo must
            ;; not register its parent over and over.
            (when (and (file-equal-p pr-root dir)
                       (not (seq-some (lambda (k) (file-equal-p k pr-root))
                                      known)))
              (project-remember-project pr)
              (push pr-root known)
              (cl-incf added))))))
    (when (called-interactively-p 'interactive)
      (message "Project rescan: %d new project(s) found" added))
    added))

(defun suhas/project-switch ()
  "Pick any project (rescanned first), switch perspective, find a file."
  (interactive)
  (suhas/project-rescan)
  (let ((dir (project-prompt-project-dir)))
    ;; One perspective per project keeps buffers separated (perspective.el).
    (when (bound-and-true-p persp-mode)
      (persp-switch (file-name-nondirectory (directory-file-name dir))))
    (let ((default-directory dir))
      (call-interactively #'project-find-file))))

(defun suhas/project-mark (dir)
  "Make DIR a project even though it is not a git repo (creates .project)."
  (interactive (list (read-directory-name "Mark as project: " default-directory nil t)))
  (let ((marker (expand-file-name ".project" dir)))
    (unless (file-exists-p marker)
      (write-region "" nil marker nil 'silent))
    (message "%s is now a project" (abbreviate-file-name dir))))

;;; ============================================================
;;; SEARCH ACROSS ALL YOUR REPOS (consult + fd / ripgrep)
;;; ============================================================

;; consult-fd / consult-ripgrep accept a LIST of directories. We run them
;; from ~ so the paths shown are short ("code/app/src/main.c").
(defun suhas/with-repo-roots (command)
  "Call consult COMMAND with all existing repo roots as search paths."
  (let ((roots (suhas/repo-roots))
        (default-directory (file-name-as-directory (expand-file-name "~"))))
    (unless roots
      (user-error "No repo roots exist; edit `suhas/repo-root-candidates' in search.el"))
    (funcall command roots)))

(defun suhas/find-file-everywhere ()
  "Find a file by NAME in all repos (type 2+ characters; fd regex, AND of words)."
  (interactive)
  (suhas/with-repo-roots #'consult-fd))

(defun suhas/grep-everywhere ()
  "Search file CONTENTS in all repos with ripgrep."
  (interactive)
  (suhas/with-repo-roots #'consult-ripgrep))

(defun suhas/grep-project ()
  "Search file CONTENTS in the current project (all repos if not in one)."
  (interactive)
  (if-let ((pr (project-current)))
      (consult-ripgrep (project-root pr))
    (message "Not in a project -- searching all repos")
    (suhas/grep-everywhere)))

;; Global fallbacks that also work where the SPC leader does not (magit
;; in emacs state, speedbar, ghostel...).
(global-set-key (kbd "C-c f") #'suhas/find-file-everywhere)
(global-set-key (kbd "C-c g") #'suhas/grep-project)

;;; ============================================================
;;; REMEMBERING THINGS (recent files, cursor position, histories)
;;; ============================================================

(use-package recentf
  :ensure nil
  :init
  (recentf-mode 1)
  :custom
  ;; Default is 20: far too few for "reopen something from last week".
  (recentf-max-saved-items 500)
  (recentf-exclude '("/tmp/" "/ssh:" "\\.elc\\'" "\\.git/" "/node_modules/"
                     "/elpa/" "/eln-cache/" "/backups/" "/auto-saves/"))
  :config
  ;; Normally the list is written only on a clean exit; a crash lost it.
  (run-with-idle-timer 300 t
                       (lambda ()
                         (let ((inhibit-message t))
                           (recentf-save-list)))))

;; Reopen a file at the line where you left it.
(use-package saveplace
  :ensure nil
  :init
  (save-place-mode 1))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1)
  :custom
  (history-length 500)
  (savehist-additional-variables '(search-ring regexp-search-ring)))

;; Dired buffers refresh themselves when the directory changed on disk.
(with-eval-after-load 'dired
  (setq dired-auto-revert-buffer #'dired-directory-changed-p)
  ;; `a' (open in THIS buffer instead of a new one) is a "disabled command"
  ;; that asks for confirmation the first time; just allow it.
  (put 'dired-find-alternate-file 'disabled nil))

;;; ============================================================
;;; SPEEDBAR -- built-in file tree
;;; ============================================================

(defun suhas/toggle-speedbar-window-focus ()
  "Open speedbar / jump into it / jump back out (bound to C-x l).
`speedbar-buffer' is the variable that always points at the real buffer."
  (interactive)
  (let ((sb-win (and (boundp 'speedbar-buffer)
                     (buffer-live-p speedbar-buffer)
                     (get-buffer-window speedbar-buffer))))
    (cond
     ((and sb-win (eq (selected-window) sb-win))
      (select-window (get-mru-window nil nil t)))
     (sb-win
      (select-window sb-win))
     (t
      (speedbar 1)
      (select-window (get-buffer-window speedbar-buffer))))))

(defun suhas/speedbar-visit-in-place (orig-fn &rest args)
  "Make speedbar visit files in the last real edit window, not its own pane."
  (let ((target (or (get-mru-window nil nil t) (selected-window)))
        (sb-buf (current-buffer)))
    (select-window target)
    (with-current-buffer sb-buf
      (apply orig-fn args))))

(use-package speedbar
  :ensure nil
  ;; The key MUST be bound here (not inside :config): :config only runs
  ;; once speedbar is loaded, so the old binding did not exist until
  ;; speedbar had already been opened some other way.
  :bind ("C-x l" . suhas/toggle-speedbar-window-focus)
  :commands (speedbar)
  :config
  (setq speedbar-prefer-window t
        speedbar-use-images nil
        ;; Show files speedbar would otherwise hide (yaml, etc.)
        speedbar-show-unknown-files t
        ;; Stop hiding dotfiles/dot-directories
        speedbar-directory-unshown-regexp "\\`\\'")

  ;; mouse-1 was translated to mouse-2 (follow-link), which fell through
  ;; to Evil's global mouse-2 = paste-primary-selection binding.
  (add-hook 'speedbar-mode-hook
            (lambda () (setq-local mouse-1-click-follows-link nil)))

  ;; Open files in the real edit window instead of speedbar's own pane.
  (advice-add 'speedbar-edit-line :around #'suhas/speedbar-visit-in-place))

;;; search.el ends here

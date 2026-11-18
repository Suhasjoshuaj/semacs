;;; search.el --- Find files, projects, text and definitions  -*- lexical-binding: t; -*-
;;;
;;; THE MENTAL MODEL
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
;;;
(require 'cl-lib)

;;; WHERE your repos live is `suhas/repo-root-candidates' in settings.el
;;; (override it in local.el).

;;; ============================================================
;;; REPO ROOTS
;;; ============================================================

(defun suhas/repo-roots ()
  "Existing directories from `suhas/repo-root-candidates' (re-checked each call)."
  (delete-dups
   (seq-filter #'file-directory-p
               (mapcar #'expand-file-name suhas/repo-root-candidates))))

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
  ;; After switching, go straight to the file list (no command menu).
  (project-switch-commands #'project-find-file))

(defvar suhas/--last-project-scan 0
  "`float-time' of the last repo-root scan (throttles `suhas/project-rescan').")

(defun suhas/--project-root-p (dir)
  "Non-nil if DIR itself is a project root (has .git, a file or a folder, or .project)."
  (or (file-exists-p (expand-file-name ".git" dir))
      (file-exists-p (expand-file-name ".project" dir))))

(defun suhas/--scan-for-projects (dir depth)
  "Project roots at or below DIR, looking at most DEPTH levels down.
A project root is returned as-is and never searched further, so a
monorepo is one project, not one per subfolder."
  (cond
   ((suhas/--project-root-p dir) (list (file-name-as-directory dir)))
   ((<= depth 0) nil)
   (t
    (let (found)
      (dolist (sub (ignore-errors
                     (directory-files dir t directory-files-no-dot-files-regexp)))
        (let ((name (file-name-nondirectory sub)))
          (when (and (file-directory-p sub)
                     (not (string-prefix-p "." name))
                     (not (member name suhas/repo-scan-ignore)))
            (setq found (nconc found (suhas/--scan-for-projects sub (1- depth)))))))
      found))))

(defun suhas/project-rescan (&optional force)
  "Register every project found under `suhas/repo-roots'.
project.el only learns about a project when you run a project command in
it; this makes freshly cloned repos show up without that. The scan
looks `suhas/repo-root-depth' levels down and is throttled to once per
`suhas/project-rescan-interval' seconds unless FORCE (always, interactively).
Returns the number of newly registered projects."
  (interactive (list t))
  (require 'project)
  (let ((added 0))
    (when (or force
              (> (- (float-time) suhas/--last-project-scan)
                 suhas/project-rescan-interval))
      (setq suhas/--last-project-scan (float-time))
      (let ((known (project-known-project-roots)))
        (dolist (root (suhas/repo-roots))
          (dolist (dir (suhas/--scan-for-projects root suhas/repo-root-depth))
            (unless (seq-some (lambda (k) (file-equal-p k dir)) known)
              (when-let* ((pr (project-current nil dir)))
                (project-remember-project pr)
                (push dir known)
                (cl-incf added)))))))
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
      (user-error "No repo roots exist; set `suhas/repo-root-candidates' in local.el"))
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
  (if-let* ((pr (project-current)))
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

(defvar suhas/recentf-timer nil
  "Idle timer that saves the recent-files list (kept so a reload replaces it).")

(defun suhas/recentf-save-quietly ()
  "Save the recent-files list without a message."
  (let ((inhibit-message t))
    (recentf-save-list)))

(use-package recentf
  :ensure nil
  :custom
  ;; Default is 20: far too few for "reopen something from last week".
  (recentf-max-saved-items 500)
  ;; Never stat remote (TRAMP) files while cleaning the list: an unreachable
  ;; host would freeze Emacs. Remote files are not remembered.
  (recentf-auto-cleanup 'never)
  (recentf-exclude '("/tmp/" "\\`/[a-z]+:" "\\.elc\\'" "\\.git/" "/node_modules/"
                     "/elpa/" "/eln-cache/" "/backups/" "/auto-saves/"))
  :config
  ;; Normally the list is written only on a clean exit; a crash lost it.
  (when (timerp suhas/recentf-timer)
    (cancel-timer suhas/recentf-timer))
  (setq suhas/recentf-timer
        (run-with-idle-timer 300 t #'suhas/recentf-save-quietly)))

(use-package savehist
  :ensure nil
  :custom
  (history-length 500)
  (savehist-additional-variables '(search-ring regexp-search-ring)))

(defun suhas/memory-first-input ()
  "Start recent-file and history tracking (first keypress)."
  (let ((inhibit-message t))   ; no "Loading recentf..." in the echo area
    (recentf-mode 1))
  ;; Files opened from the command line were visited before this ran.
  (dolist (buf (buffer-list))
    (when-let* ((file (buffer-file-name buf)))
      (recentf-add-file file)))
  (savehist-mode 1))
(add-hook 'suhas/first-input-hook #'suhas/memory-first-input)

;; Reopen a file at the line where you left it. (On from the start: it
;; has to see the very first file.)
(save-place-mode 1)

;; Dired buffers refresh themselves when the directory changed on disk.
(with-eval-after-load 'dired
  (setq dired-auto-revert-buffer #'dired-directory-changed-p)
  ;; `a' (open in THIS buffer) is a "disabled command"; just allow it.
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

(defun suhas/speedbar-close ()
  "Close the speedbar window."
  (interactive)
  (speedbar-window--close))

(defun suhas/speedbar-mouse-fix ()
  "mouse-1 was translated to mouse-2 (follow-link), which fell through to
Evil's global mouse-2 = paste-primary-selection binding."
  (setq-local mouse-1-click-follows-link nil))

(use-package speedbar
  :ensure nil
  :bind (("C-x l" . suhas/toggle-speedbar-window-focus))
  :commands (speedbar)
  :config
  (setq speedbar-prefer-window t
        speedbar-use-images nil
        ;; Show files speedbar would otherwise hide (yaml, etc.)
        speedbar-show-unknown-files t
        ;; Stop hiding dotfiles/dot-directories
        speedbar-directory-unshown-regexp "\\`\\'")
  (add-hook 'speedbar-mode-hook #'suhas/speedbar-mouse-fix)
  ;; Open files in the real edit window instead of speedbar's own pane.
  (advice-add 'speedbar-edit-line :around #'suhas/speedbar-visit-in-place))

;;; search.el ends here

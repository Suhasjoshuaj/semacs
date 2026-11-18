;;; magit.el --- Git: magit and change marks (diff-hl)  -*- lexical-binding: t; -*-
;;;
;;; Magit buffers run in Emacs state with magit's own keys (see evil.el);
;;; SPC is the normal leader there too. Cheat sheet in README.md.

(use-package magit
  :commands (magit-status magit-log-current magit-blame magit-diff-unstaged
             magit-list-repositories)
  :bind (:map magit-mode-map
          ("k" . nil)
          ("X" . magit-discard))
  :custom
  ;; Status takes the whole frame (it needs the room)...
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  ;; ...and `q' puts your previous window layout (terminal panel
  ;; included) back.
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  :config
  ;; SPC g r and `magit-status' outside a repo offer all your repos.
  (setq magit-repository-directories
        (mapcar (lambda (dir) (cons dir suhas/repo-root-depth)) (suhas/repo-roots))))

;; ESC closes magit's popup menus (c, P, F, b, l, ...) like C-g does.
(with-eval-after-load 'transient
  (define-key transient-map (kbd "<escape>") #'transient-quit-one))

;; ---------------------------------------------------------------------------
;; Commit message buffers (COMMIT_EDITMSG, rebase todo, tag messages...)
;; ---------------------------------------------------------------------------
;; These are "with-editor" buffers: git is WAITING for Emacs, and only
;; `with-editor-finish' (C-c C-c) or `with-editor-cancel' (C-c C-k) tells it
;; to continue. A plain `:w' only writes the file -- git is never told, the
;; commit does not happen. So inside a with-editor buffer Evil's commands are
;; mapped to the right thing:
;;   :wq  :x  ZZ   -> finish (commit)
;;   :q   :q!  ZQ  -> cancel (abort the commit)
;;   :w            -> just save the draft (git keeps waiting; finish later)
;; Everywhere else they behave exactly as before.
(defun suhas/with-editor-finish-advice (orig &rest args)
  "Around advice: finish the edit session in with-editor buffers."
  (if (bound-and-true-p with-editor-mode)
      (with-editor-finish nil)
    (apply orig args)))

(defun suhas/with-editor-cancel-advice (orig &rest args)
  "Around advice: cancel the edit session in with-editor buffers."
  (if (bound-and-true-p with-editor-mode)
      (with-editor-cancel nil)
    (apply orig args)))

(with-eval-after-load 'evil
  (advice-add 'evil-save-and-close          :around #'suhas/with-editor-finish-advice)
  (advice-add 'evil-save-modified-and-close :around #'suhas/with-editor-finish-advice)
  (advice-add 'evil-quit                    :around #'suhas/with-editor-cancel-advice))

;; Change marks in the fringe, and the review loop for edits you did not
;; type yourself (a formatter, a merge, a coding agent):
;;   ]c / [c   next / previous changed hunk
;;   SPC g h   show the hunk's diff inline       SPC g x   revert the hunk
(use-package diff-hl
  :hook ((prog-mode . turn-on-diff-hl-mode)
         (text-mode . turn-on-diff-hl-mode)
         (conf-mode . turn-on-diff-hl-mode))
  :commands (diff-hl-next-hunk diff-hl-previous-hunk diff-hl-show-hunk
             diff-hl-revert-hunk)
  :custom
  (diff-hl-disable-on-remote t)
  :config
  ;; Marks follow unsaved edits too.
  (diff-hl-flydiff-mode 1)
  ;; No fringe in terminal Emacs: use the margin there.
  (unless (display-graphic-p)
    (diff-hl-margin-mode 1))
  ;; Refresh the marks right after staging/committing in magit.
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

(with-eval-after-load 'evil
  (evil-define-key* 'normal 'global
    (kbd "]c") #'diff-hl-next-hunk
    (kbd "[c") #'diff-hl-previous-hunk))

(suhas/leader
 "g"   "git"
 "g s" #'magit-status
 "g l" #'magit-log-current
 "g b" #'magit-blame
 "g r" #'magit-list-repositories
 "g h" #'diff-hl-show-hunk
 "g x" #'diff-hl-revert-hunk)

;;; magit.el ends here

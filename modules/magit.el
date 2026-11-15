;;; magit.el --- Git integration (optional)  ... -*- lexical-binding: t; -*-
;; Magit is on NonGNU ELPA / MELPA. If it can't be installed, simply don't
;; use SPC g s.
;;
;; Keys: magit buffers run in plain EMACS state with magit's native keys
;; (set in evil.el, "SPECIAL BUFFER STATES"); SPC k kills one, SPC SPC is
;; consult-buffer. Cheat sheet in README.md.

(use-package magit
  :ensure t
  :defer t
  :commands (magit-status magit-log-current magit-blame magit-diff-unstaged
             magit-list-repositories)
  :custom
  ;; Status takes the whole frame (it needs the room)...
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
  ;; ...and `q' puts your previous window layout back. Without this,
  ;; fullframe calls `delete-other-windows' and `q' did NOT restore it:
  ;; every SPC g s + q destroyed your terminal split. (This pairing is the
  ;; one recommended in magit's manual.)
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  :config
  ;; SPC g r (magit-list-repositories) and `magit-status' from a buffer
  ;; that is not in a repo (e.g. *scratch*) now offer all your repos.
  (setq magit-repository-directories
        (mapcar (lambda (dir) (cons dir 1)) (suhas/repo-roots))))

;; ESC closes magit's popup menus (c, P, F, b, l, ...) like C-g does.
(with-eval-after-load 'transient
  (define-key transient-map (kbd "<escape>") #'transient-quit-one))

;; ---------------------------------------------------------------------------
;; Commit message buffers (COMMIT_EDITMSG, rebase todo, tag messages...)
;; ---------------------------------------------------------------------------
;; These are "with-editor" buffers: git is WAITING for Emacs, and only
;; `with-editor-finish' (C-c C-c) or `with-editor-cancel' (C-c C-k) tells it
;; to continue. A plain `:w' only writes the file -- git is never told, the
;; commit does not happen. Evil's `:wq' / `:x' / `ZZ' / `:q' / `ZQ' closed the
;; buffer WITHOUT informing git, leaving a half-dead session. Inside a
;; with-editor buffer they now do the right thing:
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

(use-package diff-hl
  :ensure t
  :defer t  ; 1. Explicitly tell Emacs not to touch this package at startup
  :hook ((prog-mode . turn-on-diff-hl-mode)
         (vc-dir-mode . turn-on-diff-hl-mode)) ; 2. Modern way to append hooks cleanly
  :config
  ;; 3. This block now safely runs ONLY when diff-hl wakes up for the first time
  (diff-hl-flydiff-mode 1)
  ;; Refresh the fringe marks right after you stage/commit in magit
  ;; (otherwise they stay stale until your next edit).
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)))

;;; magit.el ends here
 

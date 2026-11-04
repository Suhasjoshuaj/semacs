;;; magit.el --- Git integration (optional)  ... -*- lexical-binding: t; -*-
;; Magit is on NonGNU ELPA / MELPA. If it can't be installed, simply don't
;; use SPC g s.
;;
;; Keys: magit buffers use evil-collection-magit (see evil.el), i.e. they
;; start in NORMAL state. Cheat sheet in README.md. C-z = temporary
;; Emacs state inside a magit buffer.

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
 

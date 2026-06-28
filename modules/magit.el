;;; magit.el --- Git integration (optional)
 
;; Note: Magit requires installation from MELPA.
;; If you can't install it, simply don't use SPC g s
;; and ignore the magit binding.
 
(use-package magit
  :ensure t
  :defer t
  :commands magit-status magit-log-current magit-blame magit-diff-unstaged
  :custom
  (magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1))

(use-package diff-hl
  :ensure t
  :defer t  ; 1. Explicitly tell Emacs not to touch this package at startup
  :hook ((prog-mode . turn-on-diff-hl-mode)
         (vc-dir-mode . turn-on-diff-hl-mode)) ; 2. Modern way to append hooks cleanly
  :config
  ;; 3. This block now safely runs ONLY when diff-hl wakes up for the first time
  (diff-hl-flydiff-mode 1))

;;; magit.el ends here
 

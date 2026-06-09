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
  :init
  (add-hook 'prog-mode-hook 'turn-on-diff-hl-mode)
  (add-hook 'vc-dir-mode-hook 'turn-on-diff-hl-mode)
  :config
  ;; Instantly updates the fringe marker as you type
  (diff-hl-flydiff-mode 1))

;;; magit.el ends here
 

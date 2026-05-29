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
 
;;; magit.el ends here
 

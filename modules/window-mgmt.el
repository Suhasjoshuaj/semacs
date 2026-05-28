;;; window-mgmt.el --- Tab-bar workspaces and window management

(use-package tab-bar
  :ensure nil
  :custom
  (tab-bar-show 1)
  (tab-bar-select-tab-modifiers '(control))
  (tab-bar-new-button-show nil)
  (tab-bar-close-button-show nil)
  (tab-bar-format '(tab-bar-format-tabs tab-bar-separator)))

(add-hook 'tab-bar-mode-hook
          (lambda ()
            (set-face-attribute 'tab-bar nil
                                :height 1.0
                                :foreground "#888"
                                :background "#1e1e1e")))

(defun suhas/smart-window-split-below ()
  "Split window horizontally, new window uses ~30% of height."
  (interactive)
  (split-window-below (- (window-height) 15)))

(defun suhas/smart-window-split-right ()
  "Split window vertically, new window uses ~40% of width."
  (interactive)
  (split-window-right (- (window-width) 40)))

(defun suhas/rotate-windows ()
  "Rotate the contents of all windows."
  (interactive)
  (let ((windows (window-list))
        (buffers (mapcar #'window-buffer (window-list))))
    (dotimes (i (length windows))
      (set-window-buffer (nth i windows)
                         (nth (mod (+ i 1) (length windows)) buffers)))))

(global-set-key (kbd "C-x +") #'balance-windows)

(use-package project
  :ensure nil
  :custom
  (project-list-file (expand-file-name "projects" user-emacs-directory)))

;;; window-mgmt.el ends here

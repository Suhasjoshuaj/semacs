;;; terminal.el --- Terminal emulator via eat

(use-package eat
  :ensure t
  :commands eat
  :custom
  (eat-kill-buffer-on-exit t)
  (eat-enable-mouse t)
  :config
  (add-hook 'eat-mode-hook
            (lambda ()
              (display-line-numbers-mode 0)
              (setq-local scroll-margin 0))))

;;; TERMINAL LAUNCHER
(defun suhas/open-terminal ()
  "Open eat terminal in a bottom split. Toggle if already open."
  (interactive)
  (let ((eat-buf (get-buffer "*eat*")))
    (if (and eat-buf (get-buffer-window eat-buf))
        ;; Terminal already visible — jump to it
        (select-window (get-buffer-window eat-buf))
      ;; Open a new split at the bottom
      (progn
        (split-window-below (- (window-height) 15))
        (other-window 1)
        (if eat-buf
            (switch-to-buffer eat-buf)
          (eat))))))

(defun suhas/close-terminal ()
  "Close terminal window, keep the buffer alive."
  (interactive)
  (delete-window))

(defun suhas/open-named-terminal (name)
  "Open a named eat terminal buffer."
  (interactive "sTerminal name: ")
  (let ((buf-name (format "*eat: %s*" name)))
    (split-window-below (- (window-height) 15))
    (other-window 1)
    (if (get-buffer buf-name)
        (switch-to-buffer buf-name)
      (eat nil buf-name))))

;;; terminal.el ends here

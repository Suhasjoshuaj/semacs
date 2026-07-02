;;; terminal.el --- Terminal emulator via eat (Linux) or shell (Windows)

(if suhas/windows-p
    ;; --- WINDOWS: eat needs a pty we don't have. Fall back to `shell`
    ;; over Git Bash, which only needs a pipe, not a pty.
    (progn
      (setq explicit-shell-file-name "C:/Program Files/Git/bin/bash.exe")

      (defun suhas/open-terminal ()
        "Open Git Bash in a bottom split. Toggle if already open."
        (interactive)
        (let ((buf (get-buffer "*shell*")))
          (if (and buf (get-buffer-window buf))
              (select-window (get-buffer-window buf))
            (progn
              (split-window-below (- (window-height) 15))
              (other-window 1)
              (if buf (switch-to-buffer buf) (shell))))))

      (defun suhas/close-terminal ()
        "Close terminal window, keep the buffer alive."
        (interactive)
        (delete-window)))

  ;; --- LINUX: full eat terminal, as before
  (progn
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

    (defun suhas/open-terminal ()
      "Open eat terminal in a bottom split. Toggle if already open."
      (interactive)
      (let ((eat-buf (get-buffer "*eat*")))
        (if (and eat-buf (get-buffer-window eat-buf))
            (select-window (get-buffer-window eat-buf))
          (progn
            (split-window-below (- (window-height) 15))
            (other-window 1)
            (if eat-buf (switch-to-buffer eat-buf) (eat))))))

    (defun suhas/close-terminal ()
      "Close terminal window, keep the buffer alive."
      (interactive)
      (delete-window))))


;;(defun suhas/open-named-terminal (name)
;;  "Open a named eat terminal buffer."
;;  (interactive "sTerminal name: ")
;;  (let ((buf-name (format "*eat: %s*" name)))
;;    (split-window-below (- (window-height) 15))
;;    (other-window 1)
;;    (if (get-buffer buf-name)
;;        (switch-to-buffer buf-name)
;;      (eat nil buf-name))))

;;; terminal.el ends here

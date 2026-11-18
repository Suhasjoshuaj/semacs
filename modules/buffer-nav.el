;;; buffer-nav.el --- Cycle through file buffers, toggle the last two  -*- lexical-binding: t; -*-
;;;
;;;   C-;  next file/dired buffer  C-'  previous file/dired buffer
;;;   C-,  jump between the last two buffers of this window
;;;   (terminal Emacs: C-c n / C-c p / C-c b; leader: SPC b n / p / b)

(defun suhas/--cycle-buffer-p (buf)
  "Non-nil if BUF takes part in C-; / C-' cycling: a file or dired buffer
of this workspace."
  (and (or (buffer-file-name buf)
           (provided-mode-derived-p (buffer-local-value 'major-mode buf)
                                    'dired-mode))
       (suhas/persp-buffer-p buf)))

(defun suhas/--leave-terminal-panel ()
  "From the terminal panel, move to the window you were editing in.
Buffer cycling then changes that window, never the panel."
  (when (suhas/terminal-buffer-p (current-buffer))
    (when-let* ((win (get-mru-window nil nil t)))
      (select-window win))))

(defun suhas/cycle-buffer (step)
  "Switch STEP places along this workspace's buffers.
The order is by name, so it is the same ring in both directions (like
editor tabs) and never bounces between two buffers."
  (suhas/--leave-terminal-panel)
  (let* ((ring (sort (seq-filter #'suhas/--cycle-buffer-p (buffer-list))
                     :key #'buffer-name :lessp #'string<))
         (pos (seq-position ring (current-buffer))))
    (cond ((null ring) (message "No other buffers in this workspace"))
          ((null pos) (switch-to-buffer (car ring)))
          (t (switch-to-buffer (nth (mod (+ pos step) (length ring)) ring))))))

(defun suhas/next-buffer ()
  "Next file or dired buffer of this workspace (C-;)."
  (interactive)
  (suhas/cycle-buffer 1))

(defun suhas/prev-buffer ()
  "Previous file or dired buffer of this workspace (C-')."
  (interactive)
  (suhas/cycle-buffer -1))

(defun suhas/toggle-last-buffer ()
  "Switch to the buffer this window showed before (C-,).
Works after ANY kind of switch (SPC SPC, gd, a project jump), because it
reads the window's own history instead of remembering a buffer itself."
  (interactive)
  (suhas/--leave-terminal-panel)
  (let ((previous (seq-find
                   (lambda (buf)
                     (and (buffer-live-p buf)
                          (not (eq buf (current-buffer)))
                          (not (minibufferp buf))
                          (suhas/persp-buffer-p buf)))
                   (append (mapcar #'car (window-prev-buffers))
                           (buffer-list)))))
    (if previous
        (switch-to-buffer previous)
      (message "No previous buffer"))))

;;; buffer-nav.el ends here

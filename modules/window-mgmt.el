;;; window-mgmt.el --- Workspaces (perspective.el) and window helpers  -*- lexical-binding: t; -*-
;;;
;;; ONE workspace system: perspective.el. Each perspective is a named
;;; workspace with its OWN buffer list and window layout (a project, its
;;; files, its terminals). `SPC p p' makes one per project automatically.
;;;
;;;   SPC v n   switch / create by name           M-1 .. M-9  jump by number
;;;   SPC v l/h next / previous                   SPC v b     buffers of THIS one
;;;   SPC v k   kill                              SPC v r     rename
;;;   SPC v a   pull an existing buffer in

(use-package perspective
  :demand t
  :custom
  (persp-suppress-no-prefix-key-warning t)
  ;; Oldest first, so M-2 keeps meaning "the second one I opened".
  (persp-sort 'oldest)
  :config
  (persp-mode 1))

(defun suhas/persp-switch-nth (n)
  "Switch to the Nth workspace (1-based) in creation order."
  (let ((name (nth (1- n) (persp-names))))
    (if name
        (persp-switch name)
      (message "No workspace %d (there are %d)" n (length (persp-names))))))

(defun suhas/persp-switch-by-key ()
  "Switch to the workspace whose number is the digit just typed (M-1 .. M-9)."
  (interactive)
  (suhas/persp-switch-nth (- (event-basic-type last-command-event) ?0)))

(dotimes (i 9)
  (keymap-global-set (format "M-%d" (1+ i)) #'suhas/persp-switch-by-key))

(defun suhas/rotate-windows ()
  "Rotate the buffers of the editing windows (SPC w r)."
  (interactive)
  (let* ((windows (seq-remove #'window-dedicated-p   ; not the terminal panel
                              (window-list nil 'no-minibuffer)))
         (buffers (mapcar #'window-buffer windows)))
    (dotimes (i (length windows))
      (set-window-buffer (nth i windows)
                         (nth (mod (1+ i) (length windows)) buffers)))))

(keymap-global-set "C-x +" #'balance-windows)
(keymap-global-set "C-x -" #'shrink-window)
(keymap-global-set "C-x |" #'shrink-window-horizontally)

;;; window-mgmt.el ends here

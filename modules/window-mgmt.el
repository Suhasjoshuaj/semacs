;;; window-mgmt.el --- Workspaces (perspective.el) and window management  -*- lexical-binding: t; -*-
;;;
;;; ONE workspace system: perspective.el. Each perspective is a named
;;; workspace with its OWN buffer list (the project you are in, its files,
;;; its terminal), and `SPC p p' makes one per project automatically.
;;;
;;;   SPC v n   new / switch perspective by name     M-1 .. M-9  jump by number
;;;   SPC v l/h next / previous                      SPC v b     buffers of THIS one
;;;   SPC v k   kill perspective                     SPC v r     rename
;;;   SPC v a   pull an existing buffer in
;;;
;;; (The tab-bar workspaces that used to overlap with this were removed:
;;; perspective covers the same use case and also isolates buffers.)

(use-package perspective
  :ensure t
  :custom
  (persp-suppress-no-prefix-key-warning t)
  ;; Number perspectives in creation order, so M-2 keeps meaning "the second
  ;; one I opened" instead of shifting alphabetically as you add more.
  (persp-sort 'created)
  :init
  (persp-mode 1))

(defun suhas/persp-switch-nth (n)
  "Switch to the Nth perspective (1-based) in creation order."
  (let ((name (nth (1- n) (persp-names))))
    (if name
        (persp-switch name)
      (message "No perspective number %d (have %d)" n (length (persp-names))))))

;; Workspace switching with Meta+1..9.
(dotimes (i 9)
  (let ((n (1+ i)))
    (global-set-key (kbd (format "M-%d" n))
                    (lambda ()
                      (interactive)
                      (suhas/persp-switch-nth n)))))

(defun suhas/rotate-windows ()
  "Rotate the contents of all windows (SPC w r)."
  (interactive)
  (let ((windows (window-list))
        (buffers (mapcar #'window-buffer (window-list))))
    (dotimes (i (length windows))
      (set-window-buffer (nth i windows)
                         (nth (mod (+ i 1) (length windows)) buffers)))))

;;; WINDOW SIZING BINDINGS
(global-set-key (kbd "C-x +") #'balance-windows)
(global-set-key (kbd "C-x -") #'shrink-window)
(global-set-key (kbd "C-x |") #'shrink-window-horizontally)

;;; window-mgmt.el ends here

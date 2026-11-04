;;; buffer-nav.el --- Smart buffer rotation and toggle  ... -*- lexical-binding: t; -*-
;;;
;;;   C-;  next code buffer        C-'  previous code buffer
;;;   C-,  jump between the last two buffers

(defvar suhas/last-buffer nil
  "The buffer you just left. Used by `suhas/toggle-last-buffer' (C-,).")

;; Magit/xref buffers are already covered by "^\\*" (their names start with
;; a star). The old unanchored "magit" and "xref" patterns also hid every
;; FILE with that text in its name -- including your own modules/magit.el.
(defvar suhas/buffer-skip-patterns
  '("^\\*"           ; Skip *buffers*
    "^ "             ; Skip space-prefixed
    "^TAGS$")
  "Patterns to skip when cycling buffers.")

(defun suhas/should-skip-buffer-p (buf-name)
  "Return t if buffer should be skipped."
  (seq-some (lambda (pattern) (string-match-p pattern buf-name))
            suhas/buffer-skip-patterns))

(defun suhas/get-next-buffer (direction)
  "Get next/previous code buffer: skips special buffers, and only
considers buffers that belong to the current perspective."
  (suhas/mru-step (seq-filter #'suhas/persp-buffer-p (buffer-list))
                   direction
                   (lambda (buf) (suhas/should-skip-buffer-p (buffer-name buf)))))

(defun suhas/next-buffer ()
  "Cycle to next code buffer (C-;). Tracks last buffer for toggle."
  (interactive)
  (let ((cur (current-buffer)))
    (switch-to-buffer (suhas/get-next-buffer 'next))
    (setq suhas/last-buffer cur)))

(defun suhas/prev-buffer ()
  "Cycle to previous code buffer (C-'). Tracks last buffer for toggle."
  (interactive)
  (let ((cur (current-buffer)))
    (switch-to-buffer (suhas/get-next-buffer 'prev))
    (setq suhas/last-buffer cur)))

(defun suhas/toggle-last-buffer ()
  "Toggle between the current and the previous buffer (C-,).
Falls back to `other-buffer' when the remembered buffer was killed or
belongs to another perspective (switching to a dead buffer is an error)."
  (interactive)
  (let ((cur (current-buffer)))
    (if (and (buffer-live-p suhas/last-buffer)
             (not (eq suhas/last-buffer cur))
             (suhas/persp-buffer-p suhas/last-buffer))
        (progn (switch-to-buffer suhas/last-buffer)
               (setq suhas/last-buffer cur))
      (switch-to-buffer (other-buffer)))))

;;; buffer-nav.el ends here

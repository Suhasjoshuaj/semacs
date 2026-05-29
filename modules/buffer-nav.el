;;; buffer-nav.el --- Smart buffer rotation and toggle

(defvar suhas/buffer-skip-patterns
  '("^\\*"           ; Skip *buffers*
    "^ "             ; Skip space-prefixed
    "^TAGS$"
    "magit"
    "xref")
  "Patterns to skip when cycling buffers.")

(defun suhas/should-skip-buffer-p (buf-name)
  "Return t if buffer should be skipped."
  (catch 'skip
    (dolist (pattern suhas/buffer-skip-patterns)
      (when (string-match-p pattern buf-name)
        (throw 'skip t)))
    nil))

(defun suhas/get-next-buffer (direction)
  "Get next/previous code buffer, skipping special buffers."
  (let* ((all-buffers (buffer-list))
         (current-buf (current-buffer))
         (current-pos (seq-position all-buffers current-buf)))
    (if (not current-pos)
        current-buf
      (let* ((remaining (if (eq direction 'next)
                            (nthcdr (1+ current-pos) all-buffers)
                          (reverse (take current-pos all-buffers))))
             (wrapped (if (eq direction 'next)
                          (take (1+ current-pos) all-buffers)
                        (reverse (nthcdr current-pos all-buffers))))
             (search-list (append remaining wrapped)))
        (or (seq-find (lambda (buf)
                        (not (suhas/should-skip-buffer-p (buffer-name buf))))
                      search-list)
            current-buf)))))

(defun suhas/next-buffer () (interactive)
  "Cycle to next code buffer (C-;). Tracks last buffer for toggle."
  (let ((cur (current-buffer)))
    (switch-to-buffer (suhas/get-next-buffer 'next))
    (setq suhas/last-buffer cur)))

(defun suhas/prev-buffer () (interactive)
  "Cycle to previous code buffer (C-,). Tracks last buffer for toggle."
  (let ((cur (current-buffer)))
    (switch-to-buffer (suhas/get-next-buffer 'prev))
    (setq suhas/last-buffer cur)))

;;; ============================================================
;;; TOGGLE BETWEEN CURRENT AND PREVIOUS (C-')
;;; ============================================================

(defvar suhas/last-buffer nil
  "Track the previous buffer for C-' toggle.
  When you press C-;, it sets this to the buffer you just left.
  When you press C-', it swaps current and previous.")

(defun suhas/toggle-last-buffer () (interactive)
  "Toggle between current and last buffer (C-').
   Tracks what you came from so you always toggle correctly."
  (if suhas/last-buffer
      ;; We have a previous buffer — swap
      (let ((cur (current-buffer)))
        (switch-to-buffer suhas/last-buffer)
        (setq suhas/last-buffer cur))  ; Now cur becomes "last" for next toggle
    ;; No previous tracked — use other-buffer
    (switch-to-buffer (other-buffer))))

;;; buffer-nav.el ends here

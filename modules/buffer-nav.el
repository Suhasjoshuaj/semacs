;;; buffer-nav.el --- Smart buffer rotation (C-; and C-,)
;;; Rotates through code buffers, skipping the noise (*Messages*, *Warnings*, etc).

;;; ============================================================
;;; BUFFER FILTER
;;; ============================================================

;; These buffers are "noise" — not code you're editing.
;; We skip them when cycling with C-; and C-,.
;; Feel free to add more patterns based on your workflow.

(defvar suhas/buffer-skip-patterns
  '("^\\*"          ; Buffers starting with * (*Messages*, *Help*, *Warnings*, etc)
    "^TAGS$"        ; TAGS files (ctags)
    "magit")        ; Magit buffers
  "List of buffer name patterns (regex) to skip during cycling.")

(defun suhas/should-skip-buffer-p (buf-name)
  "Return t if BUF-NAME matches any skip pattern."
  (catch 'skip
    (dolist (pattern suhas/buffer-skip-patterns)
      (when (string-match-p pattern buf-name)
        (throw 'skip t)))
    nil))

(defun suhas/get-next-buffer (direction)
  "Get next/previous code buffer, skipping special buffers.
DIRECTION is 'next or 'prev."
  (let* ((all-buffers (buffer-list))
         (current-buf (current-buffer))
         (current-pos (position current-buf all-buffers))
         (sorted-buffers
          (if (eq direction 'next)
              ;; For next: rotate list so current is first, then take cdr
              (append (nthcdr (1+ current-pos) all-buffers)
                      (take (1+ current-pos) all-buffers))
            ;; For prev: reverse rotate
            (append (reverse (take current-pos all-buffers))
                    (reverse (nthcdr current-pos all-buffers))))))
    ;; Find first buffer that doesn't match skip patterns
    (or (seq-find (lambda (buf)
                    (not (suhas/should-skip-buffer-p (buffer-name buf))))
                  sorted-buffers)
        ;; Fallback: if all buffers are "special", just use the next one
        current-buf)))

(defun suhas/next-buffer ()
  "Switch to next code buffer, skipping *Messages*, *Help*, etc."
  (interactive)
  (switch-to-buffer (suhas/get-next-buffer 'next)))

(defun suhas/prev-buffer ()
  "Switch to previous code buffer, skipping special buffers."
  (interactive)
  (switch-to-buffer (suhas/get-next-buffer 'prev)))

;;; ============================================================
;;; ALTERNATIVE: Include all buffers if you want
;;; ============================================================

;; If you prefer to cycle through EVERYTHING including *Messages*,
;; just comment out the evil.el bindings for C-; and C-, and use these instead:
;;
;; (global-set-key (kbd "C-,") #'previous-buffer)
;; (global-set-key (kbd "C-;") #'next-buffer)
;;
;; These are Emacs built-ins that cycle through all buffers.
;; But usually skipping is better — keeps you focused on code.

;;; buffer-nav.el ends here

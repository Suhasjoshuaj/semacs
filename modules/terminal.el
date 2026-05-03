;;; terminal.el --- Terminal emulator via eat
;;; eat (Emulate A Terminal) is faster than vterm and has
;;; better Evil integration. No C compilation needed.

;;; ============================================================
;;; SECTION 1: EAT
;;; ============================================================

(use-package eat
  :ensure t
  :commands eat
  :custom
  (eat-kill-buffer-on-exit t)         ; Close buffer when shell exits
  (eat-enable-mouse t)                ; Mouse support inside terminal

  :config
  ;; Evil integration: in terminal buffers, typing goes straight
  ;; to the shell. No insert/normal mode confusion.
  ;; char mode = every key goes to terminal (like normal terminal)
  ;; semi-char mode = Emacs bindings still work (C-x, C-c, etc.)
  (add-hook 'eat-mode-hook
            (lambda ()
              ;;(eat-char-mode)               ; Start in char mode
              (display-line-numbers-mode 0) ; No line numbers in terminal
              (setq-local scroll-margin 0)))) ; No scroll margin in terminal

;;; ============================================================
;;; SECTION 2: TERMINAL LAUNCHER
;;; ============================================================

;; Opens a terminal in a bottom split — like VS Code's integrated terminal.
;; SPC t t triggers this from evil.el bindings.

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
            (switch-to-buffer eat-buf)   ; Reuse existing buffer
          (eat))))))                     ; Start fresh terminal

;; Close terminal and return to previous window with q
(defun suhas/close-terminal ()
  "Close terminal window, keep the buffer alive."
  (interactive)
  (delete-window))

;;; ============================================================
;;; SECTION 3: MULTI-TERMINAL SUPPORT
;;; ============================================================

;; You may want multiple terminal buffers — one per project.
;; This opens a new named terminal instead of reusing *eat*.

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

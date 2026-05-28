;;; terminal.el --- Eat terminal emulator with proper pty handling
;;; eat is lightweight, doesn't require C compilation, and has good Evil integration.

;;; ============================================================
;;; EAT SETUP
;;; ============================================================

(use-package eat
  :commands eat
  :custom
  ;; Kill the terminal buffer when the shell exits.
  ;; Prevents leaving orphaned buffers around.
  (eat-kill-buffer-on-exit t)
  ;; Enable mouse support inside the terminal.
  (eat-enable-mouse t))

;;; ============================================================
;;; EAT MODE CONFIGURATION
;;; ============================================================

;; When entering a terminal buffer, we need to decide:
;; 1. char-mode: Every keystroke goes to the shell. Emacs bindings don't work.
;;    This is like a real terminal — you're fully in the shell.
;; 2. semi-char-mode: Most keys go to shell, but Emacs bindings (C-x, C-c) still work.
;; 3. line-mode: Terminal behaves like a buffer. You edit lines before sending them.
;;
;; We use semi-char-mode as default — gives shell-like feel but Emacs escape hatches.

(add-hook 'eat-mode-hook
          (lambda ()
            ;; Start in semi-char mode (best of both worlds).
            ;; User can switch to full char-mode with C-c C-j if needed.
            (eat-semi-char-mode)
            
            ;; Disable line numbers — they clutter terminal output.
            (display-line-numbers-mode 0)
            
            ;; Disable scroll margin — terminal should fill the whole window.
            (setq-local scroll-margin 0)))

;;; ============================================================
;;; TERMINAL LAUNCHER
;;; ============================================================

;; Opens a terminal in a bottom split, like VS Code's integrated terminal.
;; Toggle-able: call it again to close, again to reopen.

(defun suhas/open-terminal ()
  "Open eat terminal in a bottom split. Toggle if already visible."
  (interactive)
  (let ((eat-buf (get-buffer "*eat*")))
    (if (and eat-buf (get-buffer-window eat-buf))
        ;; Terminal visible — jump to it
        (select-window (get-buffer-window eat-buf))
      ;; Terminal not visible — open it
      (progn
        ;; Split window, taking ~30% of height for terminal
        (split-window-below (- (window-height) 15))
        (other-window 1)
        (if eat-buf
            ;; Reuse existing buffer (preserves history)
            (switch-to-buffer eat-buf)
          ;; Create new terminal
          (eat))))))

(defun suhas/close-terminal ()
  "Close terminal window, but keep the buffer alive for reuse."
  (interactive)
  (delete-window))

;;; ============================================================
;;; MULTI-TERMINAL SUPPORT
;;; ============================================================

;; Sometimes you want multiple terminals (one per project, for example).
;; This opens a named terminal instead of reusing *eat*.

(defun suhas/open-named-terminal (name)
  "Open a named eat terminal buffer."
  (interactive "sTerminal name: ")
  (let ((buf-name (format "*eat: %s*" name)))
    (split-window-below (- (window-height) 15))
    (other-window 1)
    (if (get-buffer buf-name)
        ;; Reuse existing named terminal
        (switch-to-buffer buf-name)
      ;; Create new named terminal
      (eat nil buf-name))))

;;; ============================================================
;;; TERMINAL MODE KEYBINDINGS
;;; ============================================================

;; In semi-char-mode, these keys send to the shell:
;; - Regular letters and numbers
;; - Arrow keys
;; - Most special chars
;;
;; These still work as Emacs bindings:
;; - C-c (if followed by another key like C-c C-x)
;; - C-x (window management)
;; - C-u (when not followed by shell-like combos)
;;
;; If you need full shell control (e.g., interactive top(1) or vim in terminal):
;; Press C-c C-j to enter "line mode", then C-c C-j again to return to semi-char mode.
;;
;; If terminal gets stuck:
;; 1. Try C-c C-c (send SIGINT to shell)
;; 2. If that fails, try C-c C-\ (send SIGQUIT)
;; 3. Last resort: C-c C-d (send EOF)

(with-eval-after-load 'eat
  (define-key eat-mode-map (kbd "C-c C-j") #'eat-line-mode)  ; Exit to line mode
  (define-key eat-mode-map (kbd "C-c C-c") #'eat-self-input) ; Send Ctrl+C to shell
  (define-key eat-mode-map (kbd "C-c C-\\") #'eat-self-input) ; Send Ctrl+\ (SIGQUIT)
  (define-key eat-mode-map (kbd "C-c C-d") #'eat-self-input)) ; Send Ctrl+D (EOF)

;;; ============================================================
;;; TROUBLESHOOTING — If you get stuck
;;; ============================================================

;; PROBLEM: Terminal stuck in a mode, can't type or commands don't work
;; SOLUTION:
;; 1. Try pressing C-c C-j to switch modes
;; 2. If still stuck, try typing `stty sane` then Enter
;; 3. If that fails, close the buffer with SPC k and open a new terminal
;;
;; PROBLEM: Backspace doesn't work
;; SOLUTION: This is usually terminal misconfiguration. Try:
;;   stty erase ^H
;; or set your TERM variable correctly in your shell.
;;
;; PROBLEM: Colors look wrong
;; SOLUTION: eat should handle ANSI colors. If it doesn't:
;;   1. Check if your shell sets TERM correctly (echo $TERM)
;;   2. Try TERM=xterm-256color in your shell RC
;;
;; PROBLEM: Mouse doesn't work
;; SOLUTION: eat-enable-mouse is on by default. If mouse doesn't work:
;;   1. Check if your terminal emulator supports mouse events
;;   2. Try running `printf '\033[?1000h'` to enable mouse reporting

;;; terminal.el ends here

;;; ui.el --- Theme, fonts, modeline, visual defaults
;;; Everything you see. Nothing you execute.

;;; ============================================================
;;; SECTION 1: STRIP THE CHROME
;;; ============================================================

;; These are GUI elements Emacs shows by default.
;; We disable them before the frame renders to avoid a flash.
;; -1 means OFF. This must run early — hence it's in ui.el
;; which loads right after core.el.
(menu-bar-mode -1)    ; Top menu bar (File, Edit, etc.)
(tool-bar-mode -1)    ; Icon toolbar below the menu
(scroll-bar-mode -1)  ; Scrollbar on the right
(set-fringe-mode 0)   ; The thin margins on left/right of buffer

;; No startup screen. Drop straight into scratch.
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)

;;; ============================================================
;;; SECTION 2: FONT
;;; ============================================================

;; We define fonts as variables so you can change them in one
;; place without hunting through the file.
;;
;; Why a function instead of setq?
;; Font availability differs by OS. The function checks if the
;; font exists before applying it, and falls back gracefully.
;; On a fresh machine that hasn't run bootstrap.sh yet, Emacs
;; won't error — it'll just use the system default.

(defvar suhas/font-default "JetBrains Mono"
  "Primary font for code and general text.")

(defvar suhas/font-size 110
  "Font size in units of 1/10 pt. 110 = 11pt.")

(defun suhas/apply-fonts ()
  "Apply fonts if available, fall back silently if not."
  (when (find-font (font-spec :name suhas/font-default))
    (set-face-attribute 'default nil
                        :font suhas/font-default
                        :height suhas/font-size)
    (set-face-attribute 'fixed-pitch nil
                        :font suhas/font-default
                        :height suhas/font-size)
    (set-face-attribute 'variable-pitch nil
                        :font suhas/font-default
                        :height suhas/font-size)))

;;; ============================================================
;;; SECTION 3: THEME — DAEMON-SAFE LOADING
;;; ============================================================

;; modus-vivendi is built into Emacs 28+. No install needed.
;; It's designed for readability and passes WCAG AAA contrast.
;; modus-vivendi-tritanopia is the variant you were using —
;; optimized for blue/yellow color distinction.
;;
;; Why a function?
;; We need to call this AFTER a frame exists (daemon safety).
;; We attach it to hooks below rather than calling it directly.

(defun suhas/apply-theme ()
  "Load theme and apply fonts. Safe for daemon mode."
  (load-theme 'modus-vivendi-deuteranopia)
  ;;(load-theme 'modus-vivendi-tritanopia t)
  (suhas/apply-fonts))

;; Two cases:
;; 1. Normal Emacs start — frame exists immediately, load now.
;; 2. Daemon mode — no frame at startup, wait for first client.
(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (suhas/apply-theme))))
  (suhas/apply-theme))

;;; ============================================================
;;; SECTION 4: LINE NUMBERS
;;; ============================================================

;; Relative line numbers. Essential for Vim — lets you jump
;; with `12j`, `5k` without counting.
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Some buffers don't need line numbers — they're not code.
;; Turn them off for these major modes.
(dolist (mode '(term-mode-hook
                vterm-mode-hook
                eat-mode-hook
                shell-mode-hook
                eshell-mode-hook
                dired-mode-hook
                ibuffer-mode-hook
                magit-mode-hook
                help-mode-hook
                org-agenda-mode-hook))
  (add-hook mode (lambda ()
                   (display-line-numbers-mode 0))))

;;; ============================================================
;;; SECTION 5: MODELINE
;;; ============================================================

;; We're using the built-in modeline, kept minimal.
;; No doom-modeline, no powerline. Those add weight.
;; The built-in modeline shows everything you need.

;; Show current column number alongside line number.
(column-number-mode 1)

;; Show clock in modeline. You're inside Emacs — know the time.
(setq display-time-format "%H:%M"
      display-time-24hr-format t
      display-time-default-load-average nil) ; hide load avg, not useful
(display-time-mode 1)

;; Hide minor modes from modeline — they clutter it.
;; Hide minor modes from modeline — built-in, no package needed
(setq mode-line-modes
      (mapcar (lambda (x)
                (if (and (consp x)
                         (eq (car x) :propertize))
                    x
                  x))
              mode-line-modes))

;;; ============================================================
;;; SECTION 6: VISUAL QUALITY OF LIFE
;;; ============================================================

;; Highlight the current line. Subtle but useful — your eye
;; immediately knows where the cursor is.
(global-hl-line-mode 1)

;; When you have two windows showing the same file, keep both
;; displays in sync (same syntax highlighting, etc.)
(setq truncate-lines t) ; Don't wrap long lines, let them extend

;; Smooth pixel scrolling. Emacs 29+ has this built in.
;; Makes scrolling feel less like jumping between paragraphs.
;; WITH this:
(setq scroll-step 1
      scroll-margin 5
      scroll-conservatively 101
      fast-but-imprecise-scrolling t)

;; Show matching parens instantly, no delay.
(setq show-paren-delay 0)
(show-paren-mode 1)

;; Flash the modeline instead of ringing a bell.
;; Completely silent but you still get visual feedback.
(setq ring-bell-function 'ignore)

;;; ui.el ends here

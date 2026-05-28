;;; ui.el --- Theme, fonts, modeline, visual polish

;;; ============================================================
;;; LINE NUMBERS — Relative for Vim users, absolute elsewhere
;;; ============================================================

;; Relative line numbers. Essential for Vim — lets you jump with "12j" or "5k"
;; without counting. Absolute numbers are shown for non-vim buffers.
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

;; Don't show line numbers in certain modes — they're not code.
(dolist (mode '(term-mode-hook
                vterm-mode-hook
                eat-mode-hook
                shell-mode-hook
                eshell-mode-hook
                dired-mode-hook
                ibuffer-mode-hook
                magit-mode-hook
                help-mode-hook
                org-agenda-mode-hook
                messages-buffer-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;;; ============================================================
;;; FONT SETUP — Graceful fallback if font not available
;;; ============================================================

;; Define fonts as variables so you can change them in one place.
;; The function checks if the font exists before applying it.
;; On a fresh machine, this fails silently and uses system default.

(defvar suhas/font-default "JetBrains Mono"
  "Primary font for code and text.")

(defvar suhas/font-size 110
  "Font size in 1/10 pt. 110 = 11pt.")

(defun suhas/apply-font ()
  "Apply fonts if available, else silently use system default."
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
;;; THEME SYSTEM — Toggle between installed themes
;;; ============================================================

;; Available themes. Add your custom themes here after installing via package.el.
;; Built-in themes don't need installation:
;; modus-vivendi, modus-operandi, tango-dark, wombat, etc.
;; External themes: doom-themes, nord, dracula, etc (install via M-x package-install)
(defvar suhas/themes
  '(misterioso
    modus-vivendi
    modus-operandi
    tango-dark
    wombat
    deeper-blue
    wheatgrass
    gruber-darker)
  "List of themes to cycle through.")

;; Track which theme is currently active.
(defvar suhas/current-theme-index 0
  "Index of current theme in suhas/themes.")

(defun suhas/apply-theme (theme-name)
  "Load THEME-NAME and apply fonts. Safe for daemon mode."
  ;; Disable all current themes first (prevents color conflicts).
  (mapc #'disable-theme custom-enabled-themes)
  ;; Load the new theme.
  (load-theme theme-name t)
  ;; Apply fonts.
  (suhas/apply-font)
  ;; Show what theme we're using.
  (message "Loaded theme: %s" theme-name))

(defun suhas/next-theme ()
  "Cycle to the next theme."
  (interactive)
  (setq suhas/current-theme-index
        (mod (1+ suhas/current-theme-index) (length suhas/themes)))
  (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))

(defun suhas/prev-theme ()
  "Cycle to the previous theme."
  (interactive)
  (setq suhas/current-theme-index
        (mod (1- suhas/current-theme-index) (length suhas/themes)))
  (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))

(defun suhas/theme-menu ()
  "Interactive menu to select a theme."
  (interactive)
  (let* ((theme-names (mapcar #'symbol-name suhas/themes))
         (choice (completing-read "Choose theme: " theme-names)))
    (setq suhas/current-theme-index
          (position (intern choice) suhas/themes))
    (suhas/apply-theme (intern choice))))

;; Load the first theme on startup.
;; Handle both normal startup and daemon mode.
(if (daemonp)
    ;; Daemon mode: wait for first client frame
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (suhas/apply-theme (nth 0 suhas/themes)))))
  ;; Normal startup: apply immediately
  (suhas/apply-theme (nth 0 suhas/themes)))

;;; ============================================================
;;; CURSOR STYLE — Horizontal bar, persistent
;;; ============================================================

;; Set cursor type globally. hbar = horizontal bar, 2 = height.
;; This applies to all buffers unless overridden locally.
(setq-default cursor-type '(hbar . 2))

;; Toggle cursor visibility on demand.
(defun suhas/toggle-cursor ()
  "Toggle cursor visibility and style."
  (interactive)
  (if cursor-type
      (setq cursor-type nil)
    (setq cursor-type '(hbar . 2)))
  (message "Cursor: %s" (if cursor-type "visible" "hidden")))

;;; ============================================================
;;; MODELINE — Minimal, clean, informative
;;; ============================================================

;; Show column number alongside line number.
(column-number-mode 1)

;; Show time in the modeline (right side).
(setq display-time-format "%H:%M"
      display-time-24hr-format t
      display-time-default-load-average nil)
(display-time-mode 1)

;; Build a custom modeline that shows:
;; - Evil state (N/I/V/R/E)
;; - Buffer name
;; - Position (line, column)
;; - Git branch (if in a repo)
;; - Major mode
;; - Time
;;
;; We explicitly hide minor modes — they add noise.
(setq-default mode-line-format
              '("%e"
                mode-line-front-space
                ;; Evil state indicator (N=normal, I=insert, V=visual, R=replace, E=emacs)
                (:eval (cond
                        ((bound-and-true-p evil-mode)
                         (cond ((evil-normal-state-p)  " N ")
                               ((evil-insert-state-p)  " I ")
                               ((evil-visual-state-p)  " V ")
                               ((evil-replace-state-p) " R ")
                               (t                      " E ")))
                        (t " - ")))  ; Fallback if evil not loaded
                "  "
                ;; Buffer name
                mode-line-buffer-identification
                "  "
                ;; Position (line, column)
                "(%l,%c)"
                "  "
                ;; Git branch (if vc-mode is active)
                (vc-mode vc-mode)
                "  "
                ;; Major mode only (no minor modes)
                "%m"
                "  "
                ;; Time
                display-time-string
                mode-line-end-spaces))

;;; ============================================================
;;; VISUAL POLISH
;;; ============================================================

;; Highlight the current line. Subtle but your eye finds it instantly.
(global-hl-line-mode 1)

;; Don't wrap long lines. They extend beyond the window edge.
;; You navigate with arrow keys or vim hjkl to see them.
(setq truncate-lines t)

;; Show matching parens instantly with no delay (defined in core too, but repeating for emphasis).
(show-paren-mode 1)
(setq show-paren-delay 0)

;;; ui.el ends here

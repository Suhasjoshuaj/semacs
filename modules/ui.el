;;; ui.el --- Theme, font, modeline, visual polish  -*- lexical-binding: t; -*-
;;;
;;; No UI packages: everything here is built into Emacs. Font, size, theme
;;; list and padding are knobs in settings.el.

;;; ============================================================
;;; LINE NUMBERS
;;; ============================================================

;; Opt IN for editing buffers; special buffers (magit, dired, help,
;; terminals) are simply never listed.
(setq display-line-numbers-type 'relative
      display-line-numbers-width 3
      display-line-numbers-grow-only t)   ; the gutter never jitters
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;;; ============================================================
;;; SCROLLING
;;; ============================================================

(setq scroll-margin 2
      scroll-conservatively 101
      scroll-step 0
      scroll-preserve-screen-position t)

(defun suhas/ui-first-input ()
  "UI extras that can wait for the first keypress."
  (when (display-graphic-p)
    (pixel-scroll-precision-mode 1))
  (display-time-mode 1))
(add-hook 'suhas/first-input-hook #'suhas/ui-first-input)

;;; ============================================================
;;; FONT AND FRAME
;;; ============================================================

(defun suhas/apply-font (&optional frame)
  "Apply `suhas/font-family' to FRAME, but only if it is installed (GUI only)."
  (with-selected-frame (or frame (selected-frame))
    (when (and (display-graphic-p)
               (find-font (font-spec :family suhas/font-family))
               (not (and (equal (face-attribute 'default :family) suhas/font-family)
                         (= (face-attribute 'default :height) suhas/font-size))))
      (set-face-attribute 'default nil
                          :family suhas/font-family
                          :height suhas/font-size)
      (set-face-attribute 'fixed-pitch nil
                          :family suhas/font-family
                          :height suhas/font-size))))

(unless (daemonp)
  (suhas/apply-font))
(add-hook 'after-make-frame-functions #'suhas/apply-font)

;; A little air around the text, and a hairline between side-by-side
;; windows instead of the fringe edge.
(modify-all-frames-parameters
 `((internal-border-width . ,suhas/frame-padding)))
(setq window-divider-default-places 'right-only
      window-divider-default-right-width 1)
(window-divider-mode 1)

;;; ============================================================
;;; THEMES
;;; ============================================================

;; Modus (built in) is the default family. These must be set BEFORE a
;; modus theme loads: italic comments, and no borders or grey gutters.
(setq modus-themes-italic-constructs t
      modus-themes-common-palette-overrides
      '((border-mode-line-active unspecified)
        (border-mode-line-inactive unspecified)
        (fringe unspecified)
        (bg-line-number-active unspecified)
        (bg-line-number-inactive unspecified)))

(defun suhas/theme-before-load (theme &optional _no-confirm no-enable)
  "Disable the current theme(s) so themes never stack.
Only when THEME really exists and is about to be ENABLED: a missing theme
must not remove your current one."
  (when (and (not no-enable) (memq theme (custom-available-themes)))
    (mapc #'disable-theme custom-enabled-themes)))

(defun suhas/theme-after-load (&rest _)
  "Flatten faces that themes love to decorate with boxes and lines."
  (dolist (face '(hl-line vertico-current
                  completions-common-part
                  completions-first-difference
                  header-line))
    (when (facep face)
      (set-face-attribute face nil :underline nil :overline nil :box nil)))
  ;; Modeline: no outline, just a few pixels of padding in its own colour.
  (dolist (face '(mode-line mode-line-active mode-line-inactive))
    (when (facep face)
      (set-face-attribute face nil :underline nil :overline nil
                          :box '(:line-width (1 . 4) :style flat-button))))
  (set-face-attribute 'line-number-current-line nil :weight 'bold))

(advice-add #'load-theme :before #'suhas/theme-before-load)
(advice-add #'load-theme :after #'suhas/theme-after-load)

(defun suhas/available-themes ()
  "`suhas/themes' that exist on THIS machine (third-party ones may not)."
  (let ((available (custom-available-themes)))
    (seq-filter (lambda (th) (memq th available)) suhas/themes)))

(defun suhas/set-theme (theme)
  "Load THEME and remember it for the next start."
  (load-theme theme t)
  (customize-save-variable 'custom-enabled-themes (list theme))
  (message "Theme: %s" theme))

(defun suhas/cycle-theme (direction)
  "Load the theme DIRECTION steps along `suhas/available-themes'."
  (let* ((themes (suhas/available-themes))
         (idx (or (seq-position themes (car custom-enabled-themes)) 0)))
    (suhas/set-theme (nth (mod (+ idx direction) (length themes)) themes))))

(defun suhas/next-theme ()
  "SPC u n -- next theme."
  (interactive)
  (suhas/cycle-theme 1))

(defun suhas/prev-theme ()
  "SPC u p -- previous theme."
  (interactive)
  (suhas/cycle-theme -1))

(defun suhas/theme-menu ()
  "SPC u t -- pick a theme from a list."
  (interactive)
  (suhas/set-theme
   (intern (completing-read "Theme: "
                            (mapcar #'symbol-name (suhas/available-themes))
                            nil t))))

;; custom.el holds the saved theme (and whatever M-x customize wrote).
;; Loaded here, after the theme options and advice above.
(suhas/load-optional "custom.el")

;; Fresh machine, or a saved theme that no longer exists.
(unless custom-enabled-themes
  (load-theme suhas/default-theme t))

;; early-init.el painted the first frame dark to avoid a white flash.
;; Later frames must follow the theme instead.
(dolist (param '(background-color foreground-color))
  (setq default-frame-alist (assq-delete-all param default-frame-alist)))

;;; ============================================================
;;; MODELINE
;;; ============================================================

;; Left: Emacs's status block, Vim state, buffer, position, git branch.
;; Right: workspace / terminal status / load and clock, diagnostics, mode.
;; No minor-mode lighters.
;;
;; The status block is Emacs's own `U:**-':
;;   U         coding system (U = UTF-8, - = plain ASCII/binary, 1 = Latin-1 ...)
;;   : \ /     line endings (Unix LF, DOS CRLF, old Mac CR)
;;   @         this frame belongs to an emacsclient
;;   ** %% -   modified / read-only / unchanged (two characters)
;;   - @       local file / remote file (TRAMP)
;; Hover over any part for a description.

(setq evil-mode-line-format nil)   ; the tag is placed below, not by Evil
(setq-default mode-line-format
              '("%e" mode-line-front-space
                mode-line-mule-info
                mode-line-client
                mode-line-modified
                mode-line-remote
                " "
                (:eval (bound-and-true-p evil-mode-line-tag))
                mode-line-buffer-identification
                (:propertize "  %l:%c" face shadow)
                (vc-mode vc-mode)
                mode-line-format-right-align
                mode-line-misc-info
                (flymake-mode (" " flymake-mode-line-counters))
                "  "
                (:propertize mode-name face bold)
                mode-line-process
                "  "))

;; Clock plus the 1-minute system load average, always shown (Windows
;; Emacs estimates the load from CPU use). Refreshed once a minute.
(setq display-time-format " %H:%M"
      display-time-default-load-average 0
      display-time-load-average-threshold 0
      display-time-mail-string "")

;;; ============================================================
;;; VISUAL POLISH
;;; ============================================================

;; Long lines run off the edge in code; prose wraps at word boundaries.
(setq-default truncate-lines t
              cursor-in-non-selected-windows nil)
(add-hook 'text-mode-hook #'visual-line-mode)

(blink-cursor-mode -1)

(setq x-underline-at-descent-line t
      ;; The matching bracket is off screen: show its line at the top.
      show-paren-context-when-offscreen 'overlay
      ;; Documentation in the echo area stays on one line.
      eldoc-echo-area-use-multiline-p nil)

(defun suhas/toggle-line-wrap ()
  "Toggle line wrapping in the current buffer (SPC l w)."
  (interactive)
  (visual-line-mode 'toggle)
  (message "Line wrap: %s" (if visual-line-mode "ON" "OFF")))

(suhas/leader
 "u"   "theme"
 "u t" #'suhas/theme-menu
 "u n" #'suhas/next-theme
 "u p" #'suhas/prev-theme
 "l"   "lines"
 "l w" #'suhas/toggle-line-wrap)

;;; ui.el ends here

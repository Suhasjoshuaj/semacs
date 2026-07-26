;;; ui.el --- UI, Theme, Fonts, Modeline, Visual Polish -*- lexical-binding: t; -*-

;; This version is optimized for:
;; - Windows + Linux
;; - Minimal startup work
;; - Theme-independent font handling
;; - Readability

(require 'cl-lib)

;;; LINE NUMBERS

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

(defun suhas/disable-line-numbers ()
  (display-line-numbers-mode -1))

(dolist (hook '(term-mode-hook vterm-mode-hook eat-mode-hook shell-mode-hook
                eshell-mode-hook dired-mode-hook ibuffer-mode-hook
                magit-mode-hook help-mode-hook org-agenda-mode-hook
                messages-buffer-mode-hook))
  (add-hook hook #'suhas/disable-line-numbers))

;;; SCROLLING

(setq scroll-margin 2
      scroll-conservatively 101
      scroll-step 0)

(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;;; FONT

(defconst suhas/font-family
  (pcase system-type
    ('windows-nt "Iosevka NF")
    ('gnu/linux "Iosevka Nerd Font")
    (_ "Monospace")))

(defconst suhas/font-size 120)

(defun suhas/apply-font (&optional frame)
  (with-selected-frame (or frame (selected-frame))
    (unless (and (equal (face-attribute 'default :family) suhas/font-family)
                 (= (face-attribute 'default :height) suhas/font-size))
      (set-face-attribute 'default nil
                          :family suhas/font-family
                          :height suhas/font-size)
      (set-face-attribute 'fixed-pitch nil
                          :family suhas/font-family
                          :height suhas/font-size))))

;;; THEME FIXES

(defun suhas/theme-before-load (&rest _)
  (mapc #'disable-theme custom-enabled-themes))

(defun suhas/theme-after-load (&rest _)
  (dolist (face '(hl-line vertico-current
                  completions-common-part
                  completions-first-difference
                  mode-line mode-line-inactive
                  header-line))
    (ignore-errors
      (set-face-attribute face nil
                          :underline nil
                          :overline nil
                          :box nil))))

;;; THEMES

(defconst suhas/themes
  '(misterioso modus-vivendi modus-operandi tango-dark wombat
    deeper-blue wheatgrass gruber-darker modus-vivendi-tinted))

(defconst suhas/theme-count (length suhas/themes))

(advice-add #'load-theme :before #'suhas/theme-before-load)
(advice-add #'load-theme :after #'suhas/theme-after-load)

(unless (daemonp)
  (suhas/apply-font))

(add-hook 'after-make-frame-functions #'suhas/apply-font)

(defun suhas/current-theme ()
  (or (car custom-enabled-themes)
      (car suhas/themes)))

(defun suhas/cycle-theme (direction)
  (let* ((idx (or (cl-position (suhas/current-theme)
                               suhas/themes)
                  0))
         (theme (nth (mod (+ idx direction)
                          suhas/theme-count)
                     suhas/themes)))
    (load-theme theme t)
    (customize-save-variable
     'custom-enabled-themes
     (list theme))
    (message "Loaded %s" theme)))

(defun suhas/next-theme ()
  (interactive)
  (suhas/cycle-theme 1))

(defun suhas/prev-theme ()
  (interactive)
  (suhas/cycle-theme -1))

(defun suhas/theme-menu ()
  (interactive)
  (let* ((choice
          (completing-read
           "Theme: "
           (mapcar #'symbol-name suhas/themes)
           nil t))
         (theme (intern choice)))
    (load-theme theme t)
    (customize-save-variable
     'custom-enabled-themes
     (list theme))))

;;; MODELINE

(setq eol-mnemonic-unix ""
      eol-mnemonic-dos ""
      eol-mnemonic-mac ""
      eol-mnemonic-undecided "")
;; Enable time display
(display-time-mode 1)

;; Show only hours and minutes in 24-hour format
(setq display-time-format "%H:%M")
(setq display-time-default-load-average t) ; Hide load average
(setq display-time-mail-string "")          ; Hide mail indicator


;;(use-package mood-line
;;  :ensure t
;;  :custom
;;
;;  ;; Show the current project name.
;;  (mood-line-show-project-name t)
;;
;;  ;; Show position through the current buffer.
;;  (mood-line-show-percent-position t)
;;
;;  ;; Show encoding information when relevant.
;;  (mood-line-show-encoding-information t)
;;
;;  :config
;;  (mood-line-mode 1)
;;
;;  ;; Display current time in the modeline.
;;  (setq display-time-format "%H:%M")
;;  (setq display-time-default-load-average nil)
;;  (display-time-mode 1))


;;(column-number-mode 1)
;;(size-indication-mode 1)
;;
;;;; Configure clock display safely
;;(setq display-time-format "%H:%M"
;;      display-time-24hr-format t
;;      display-time-default-load-average nil)
;;(display-time-mode 1)
;;
;;;; Define the mode line structure (Cleaned & Segmented)
;;(setq-default mode-line-format
;;  '("%e "
;;    mode-line-modified
;;    " "
;;    mode-line-buffer-identification
;;    " "
;;    mode-line-position
;;    " "
;;    vc-mode
;;    " "
;;    mode-line-modes
;;    
;;    ;; Dynamic status indicators
;;    (:eval (and (bound-and-true-p eglot--managed-mode) " | LSP"))
;;    (:eval (and (bound-and-true-p flymake-mode) " | Flymake"))
;;    
;;    ;; Right-align the clock segment perfectly
;;    (:eval (propertize " " 'display '(space :align-to (- right 9))))
;;    
;;    ;; Segmented Time Display Block
;;    (:eval (and display-time-string 
;;                (propertize (concat " 🕒 " (string-trim display-time-string) " ")
;;                            'face '(:weight bold))))))

;;; VISUAL POLISH

(global-hl-line-mode 0)

(setq truncate-lines t
      show-paren-delay 0
      ring-bell-function #'ignore)

(show-paren-mode 1)
(blink-cursor-mode -1)

;;; LINE WRAPPING (per-buffer toggle)

(defun suhas/toggle-line-wrap ()
  "Toggle visual-line-mode in the current buffer, with feedback."
  (interactive)
  (visual-line-mode 'toggle)
  (message "Line wrap: %s" (if visual-line-mode "ON (wrapped, j/k move by visual line)"
                              "OFF (truncated)")))
(provide 'ui)

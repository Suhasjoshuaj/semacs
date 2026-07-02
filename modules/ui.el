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
    deeper-blue wheatgrass gruber-darker))

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

(column-number-mode 1)
(size-indication-mode 1)

(setq display-time-format "%H:%M"
      display-time-24hr-format t
      display-time-default-load-average nil)

(display-time-mode 1)

(setq-default
 mode-line-format
 '("%e "

   mode-line-modified
   " "
   mode-line-buffer-identification
   " "
   mode-line-position
   " "
   vc-mode
   " "
   mode-line-modes
   " "
   mode-line-misc-info

   (:eval
    (when (bound-and-true-p eglot--managed-mode)
      " | LSP"))

   (:eval
    (when (bound-and-true-p flymake-mode)
      " | Flymake"))

   (:eval
    (propertize
     " "
     'display
     '(space :align-to (- right 8))))

   mode-line-mule-info

   " "

   display-time-string))

;;; VISUAL POLISH

(global-hl-line-mode 1)

(setq truncate-lines t
      show-paren-delay 0
      ring-bell-function #'ignore)

(show-paren-mode 1)
(blink-cursor-mode -1)

(provide 'ui)

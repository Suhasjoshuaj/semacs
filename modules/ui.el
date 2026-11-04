;;; ui.el --- UI, Theme, Fonts, Modeline, Visual Polish -*- lexical-binding: t; -*-

;; This version is optimized for:
;; - Windows + Linux
;; - Minimal startup work
;; - Theme-independent font handling
;; - Readability

(require 'cl-lib)

;;; LINE NUMBERS

;; Opt IN for editing buffers instead of "on everywhere, then a hook list
;; to switch it off". The old blacklist had to name every special mode
;; and had already missed ghostel, xref, grep, Info... Special buffers
;; (magit, dired, help, terminals, compilation) are simply never listed.
(setq display-line-numbers-type 'relative)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

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
  "Apply the Iosevka font, but only if it is installed (and we are in a GUI)."
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

;;; THEME FIXES

(defun suhas/theme-before-load (theme &optional _no-confirm no-enable)
  "Disable the current theme(s) so themes never stack -- but only when THEME
really exists and is about to be ENABLED. Before, a missing theme (e.g. an
uninstalled gruber-darker) removed your theme and then failed to load
anything, leaving the default white; and `use-package' calls
(load-theme 'use-package t t), which also wiped the active theme."
  (when (and (not no-enable) (memq theme (custom-available-themes)))
    (mapc #'disable-theme custom-enabled-themes)))

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
    deeper-blue wheatgrass gruber-darker modus-vivendi-tinted chyla-dark inkpot haki))

(defun suhas/available-themes ()
  "`suhas/themes' that exist on THIS machine (third-party ones may not)."
  (let ((available (custom-available-themes)))
    (seq-filter (lambda (th) (memq th available)) suhas/themes)))

(advice-add #'load-theme :before #'suhas/theme-before-load)
(advice-add #'load-theme :after #'suhas/theme-after-load)

(unless (daemonp)
  (suhas/apply-font))

(add-hook 'after-make-frame-functions #'suhas/apply-font)

(defun suhas/current-theme ()
  (or (car custom-enabled-themes)
      (car suhas/themes)))

(defun suhas/cycle-theme (direction)
  (let* ((themes (suhas/available-themes))
         (idx (or (cl-position (suhas/current-theme) themes) 0))
         (theme (nth (mod (+ idx direction) (length themes)) themes)))
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
           (mapcar #'symbol-name (suhas/available-themes))
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
(setq display-time-default-load-average nil) ; Hide load average
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

;; `setq-default', not `setq': `truncate-lines' becomes buffer-local the
;; moment it is set, so the old (setq truncate-lines t) only ever changed
;; *scratch* and every other buffer silently wrapped. Org already turns on
;; visual-line-mode for itself; do the same for other prose buffers.
;; (show-paren and the bell are configured once, in core.el.)
(setq-default truncate-lines t)
(add-hook 'text-mode-hook #'visual-line-mode)

(blink-cursor-mode -1)

;;; LINE WRAPPING (per-buffer toggle)

(defun suhas/toggle-line-wrap ()
  "Toggle visual-line-mode in the current buffer, with feedback."
  (interactive)
  (visual-line-mode 'toggle)
  (message "Line wrap: %s" (if visual-line-mode "ON (wrapped, j/k move by visual line)"
                              "OFF (truncated)")))
(provide 'ui)

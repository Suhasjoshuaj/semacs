;;; ui.el --- UI, Theme, Fonts, Modeline, Visual Polish -*- lexical-binding: t; -*-

;; Optimized for: Windows + Linux, minimal startup work, theme-independent
;; font handling, readability. Font, size and theme list live in settings.el.

(require 'cl-lib)

;;; LINE NUMBERS

;; Opt IN for editing buffers instead of "on everywhere, then a hook list
;; to switch it off": special buffers (magit, dired, help, terminals,
;; compilation) are simply never listed.
(setq display-line-numbers-type 'relative)
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
  (add-hook hook #'display-line-numbers-mode))

;;; SCROLLING (one source of truth; core.el no longer sets any)

(setq scroll-margin 2
      scroll-conservatively 101
      scroll-step 0)

(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;;; FONT

(defun suhas/apply-font (&optional frame)
  "Apply `suhas/font-family', but only if it is installed (and we are in a GUI)."
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
  "Disable the current theme(s) so themes never stack.
Only when THEME really exists and is about to be ENABLED: a missing theme
must not remove your current one and leave the default white, and `use-package'
calls `load-theme' with NO-ENABLE, which must not wipe the active theme."
  (when (and (not no-enable) (memq theme (custom-available-themes)))
    (mapc #'disable-theme custom-enabled-themes)))

(defun suhas/theme-after-load (&rest _)
  "Flatten faces that themes love to decorate with boxes and lines."
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
  "Load the theme DIRECTION steps along `suhas/available-themes' and save it."
  (let* ((themes (suhas/available-themes))
         (idx (or (cl-position (suhas/current-theme) themes) 0))
         (theme (nth (mod (+ idx direction) (length themes)) themes)))
    (load-theme theme t)
    (customize-save-variable 'custom-enabled-themes (list theme))
    (message "Loaded %s" theme)))

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
  (let* ((choice (completing-read
                  "Theme: "
                  (mapcar #'symbol-name (suhas/available-themes))
                  nil t))
         (theme (intern choice)))
    (load-theme theme t)
    (customize-save-variable 'custom-enabled-themes (list theme))))

;;; MODELINE

(setq eol-mnemonic-unix ""
      eol-mnemonic-dos ""
      eol-mnemonic-mac ""
      eol-mnemonic-undecided "")

(display-time-mode 1)
(setq display-time-format "%H:%M"
      display-time-default-load-average nil
      display-time-mail-string "")

(column-number-mode 1)

;;; VISUAL POLISH

;; `setq-default', not `setq': `truncate-lines' is buffer-local the moment
;; it is set, so a plain `setq' would only affect *scratch*. Org turns on
;; visual-line-mode for itself; do the same for other prose buffers.
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
;;; ui.el ends here

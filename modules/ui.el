;;; ui.el --- Theme, fonts, modeline, visual polish

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)

(dolist (mode '(term-mode-hook vterm-mode-hook eat-mode-hook shell-mode-hook
                eshell-mode-hook dired-mode-hook ibuffer-mode-hook magit-mode-hook
                help-mode-hook org-agenda-mode-hook messages-buffer-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;;; SCROLLING
(setq scroll-margin 2 scroll-conservatively 101 scroll-step 0)
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

;;; FONT
(defvar suhas/font-default "Iosevka Nerd Font")
(defvar suhas/font-size 121)

(defun suhas/apply-font ()
  (when (find-font (font-spec :name suhas/font-default))
    (set-face-attribute 'default nil :font suhas/font-default :height suhas/font-size)
    (set-face-attribute 'fixed-pitch nil :font suhas/font-default :height suhas/font-size)))

;;; ============================================================
;;; THEME — PERSISTS ACROSS SESSIONS
;;; ============================================================

(defvar suhas/themes '(misterioso modus-vivendi modus-operandi tango-dark wombat deeper-blue wheatgrass gruber-darker))
(defvar suhas/current-theme-index 0)
(defvar suhas/theme-file (expand-file-name "current-theme.el" user-emacs-directory))

(defun suhas/apply-theme (theme-name)
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme-name t)
  (suhas/apply-font)
  (message "Loaded theme: %s" theme-name)
  ;; Save theme choice to file so it persists
  (with-temp-file suhas/theme-file
    (insert (format "(setq suhas/current-theme-index %d)" suhas/current-theme-index))))

(defun suhas/next-theme () (interactive)
  (setq suhas/current-theme-index (mod (1+ suhas/current-theme-index) (length suhas/themes)))
  (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))

(defun suhas/prev-theme () (interactive)
  (setq suhas/current-theme-index (mod (1- suhas/current-theme-index) (length suhas/themes)))
  (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))

(defun suhas/theme-menu () (interactive)
  (let* ((theme-names (mapcar #'symbol-name suhas/themes))
         (choice (completing-read "Choose theme: " theme-names))
         (theme-index (seq-position suhas/themes (intern choice))))
    (when theme-index
      (setq suhas/current-theme-index theme-index)
      (suhas/apply-theme (intern choice)))))

;; Load saved theme on startup
(when (file-exists-p suhas/theme-file)
  (load-file suhas/theme-file))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame) (with-selected-frame frame (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))))
  (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))


;;; ============================================================
;;; MODELINE
;;; ============================================================

;;(column-number-mode 1)
;;(setq display-time-format "%H:%M" display-time-24hr-format t display-time-default-load-average nil)
;;(display-time-mode 1)

(defvar suhas/modeline-detailed-p nil)

(defun suhas/toggle-modeline-info () (interactive)
  (setq suhas/modeline-detailed-p (not suhas/modeline-detailed-p))
  (force-mode-line-update t)
  (message "Modeline: %s" (if suhas/modeline-detailed-p "detailed" "simple")))

(setq-default mode-line-format
              '("%e"
                mode-line-front-space
                (:eval (cond ((bound-and-true-p evil-mode)
                              (cond ((evil-normal-state-p)  " N ")
                                    ((evil-insert-state-p)  " I ")
                                    ((evil-visual-state-p)  " V ")
                                    ((evil-replace-state-p) " R ")
                                    (t                      " E ")))
                       (t "⚪ ")))
                mode-line-buffer-identification
                " "
                (:eval (if suhas/modeline-detailed-p
                           (format "(%d:%d) " (line-number-at-pos) (current-column))
                         ""))
                (:eval (if (and suhas/modeline-detailed-p vc-mode)
                           (concat " ⎇ " (substring vc-mode 5) " ")
                         ""))
                (:eval (if suhas/modeline-detailed-p
                           (format "| %s " major-mode)
                         ""))
                (:eval (if (and suhas/modeline-detailed-p
                                (bound-and-true-p minor-mode-list))
                           (let ((modes (delq nil (mapcar #'car minor-mode-alist))))
                             (if modes (concat "| " (mapconcat #'symbol-name modes " ") " ") ""))
                         ""))
                (:eval (if (and suhas/modeline-detailed-p (bound-and-true-p eglot--managed-mode))
                           "| 🔷 LSP "
                         ""))
                (:eval (if suhas/modeline-detailed-p
                           (concat "| " display-time-string)
                         display-time-string))
                mode-line-end-spaces))

;;; VISUAL POLISH
(global-hl-line-mode 1)
(setq truncate-lines t)
(show-paren-mode 1)
(setq show-paren-delay 0)

;;; ui.el ends here

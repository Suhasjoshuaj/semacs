;;; ui.el --- Theme, fonts, modeline, visual polish

(require 'cl-lib)
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
  ;; OPTIMIZED: Removed find-font/font-spec to eliminate OS font cache scanning.
  ;; Added a single face-attribute modification list for faster rendering.
  (custom-set-faces
   `(default ((t (:font ,suhas/font-default :height ,suhas/font-size))))
   `(fixed-pitch ((t (:font ,suhas/font-default :height ,suhas/font-size))))))

;;; ============================================================
;;; THEME — PERSISTS ACROSS SESSIONS
;;; ============================================================

;;(defvar suhas/themes '(misterioso modus-vivendi modus-operandi tango-dark wombat deeper-blue wheatgrass gruber-darker))
;;(defvar suhas/current-theme-index 0)
;;(defvar suhas/theme-file (expand-file-name "current-theme.el" user-emacs-directory))
;;
;;(defun suhas/apply-theme (theme-name)
  ;;(mapc #'disable-theme custom-enabled-themes)
  ;;(load-theme theme-name t)
  ;;(suhas/apply-font)
  ;;(message "Loaded theme: %s" theme-name)
  ;;;; Save theme choice to file so it persists
  ;;(with-temp-file suhas/theme-file
    ;;(insert (format "(setq suhas/current-theme-index %d)" suhas/current-theme-index))))
;;
;;(defun suhas/next-theme () (interactive)
  ;;(setq suhas/current-theme-index (mod (1+ suhas/current-theme-index) (length suhas/themes)))
  ;;(suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))
;;
;;(defun suhas/prev-theme () (interactive)
  ;;(setq suhas/current-theme-index (mod (1- suhas/current-theme-index) (length suhas/themes)))
  ;;(suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))
;;
;;(defun suhas/theme-menu () (interactive)
  ;;(let* ((theme-names (mapcar #'symbol-name suhas/themes))
         ;;(choice (completing-read "Choose theme: " theme-names))
         ;;(theme-index (seq-position suhas/themes (intern choice))))
    ;;(when theme-index
      ;;(setq suhas/current-theme-index theme-index)
      ;;(suhas/apply-theme (intern choice)))))
;;
;;;; Load saved theme on startup
;;(when (file-exists-p suhas/theme-file)
  ;;(load-file suhas/theme-file))
;;
;;(if (daemonp)
    ;;(add-hook 'after-make-frame-functions
              ;;(lambda (frame) (with-selected-frame frame (suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))))
  ;;(suhas/apply-theme (nth suhas/current-theme-index suhas/themes)))

;;; ============================================================
;;; THEME — END
;;; ============================================================


;; OPTIMIZED: font and theme differenciation for fast bootup.
;;; 1. SYSTEM FONTS (Set once globally, never touch during theme changes)
(defvar suhas/font-default "Iosevka Nerd Font")
(defvar suhas/font-size 121)

(custom-set-faces
 `(default ((t (:font ,suhas/font-default :height ,suhas/font-size))))
 `(fixed-pitch ((t (:font ,suhas/font-default :height ,suhas/font-size)))))


;;; 2. THEME CONFIGURATION
(defvar suhas/themes '(misterioso modus-vivendi modus-operandi tango-dark wombat deeper-blue wheatgrass gruber-darker))

;; Automatically disable old themes when a new one is loaded via M-x load-theme
(setq custom-safe-themes t) ; Trust all themes to skip confirmation prompts

(advice-add 'load-theme :before
            (lambda (&rest _) (mapc #'disable-theme custom-enabled-themes)))


;;; 3. THEME CYCLING LOGIC
(defun suhas/get-current-theme ()
  "Get the currently enabled theme symbol, defaulting to the first in the list."
  (or (car custom-enabled-themes) (car suhas/themes)))

(defun suhas/cycle-theme (direction)
  "Helper function to cycle through the suhas/themes list."
  (let* ((current (suhas/get-current-theme))
         (len (length suhas/themes))
         (idx (cl-position current suhas/themes))
         ;; If current theme isn't in our list, start at index 0
         (next-idx (if idx (mod (+ idx direction) len) 0))
         (chosen-theme (nth next-idx suhas/themes)))
    (load-theme chosen-theme t)
    ;; Natively save this selection to your custom file/init file
    (customize-save-variable 'custom-enabled-themes (list chosen-theme))
    (message "Switched to theme: %s" chosen-theme)))

(defun suhas/next-theme () (interactive) (suhas/cycle-theme 1))
(defun suhas/prev-theme () (interactive) (suhas/cycle-theme -1))


;;; 4. THEME MENU
(defun suhas/theme-menu () (interactive)
  "A cleaner menu that limits M-x load-theme options to just your curated list."
  (let* ((choices (mapcar #'symbol-name suhas/themes))
         (picked (completing-read "Choose curated theme: " choices nil t)))
    (load-theme (intern picked) t)
    (customize-save-variable 'custom-enabled-themes (list (intern picked)))))

;;; ============================================================
;;; MODELINE — CLEAN, INFORMATIONAL, BALANCED
;;; ============================================================

(column-number-mode 1)
(size-indication-mode 1)

(setq display-time-format "%H:%M"
      display-time-24hr-format t
      display-time-default-load-average nil)

(display-time-mode 1)

(setq-default
 mode-line-format
 '("%e "

   ;; Evil state
   (:eval
    (pcase (bound-and-true-p evil-state)
      ('normal  " N ")
      ('insert  " I ")
      ('visual  " V ")
      ('replace " R ")
      ('motion  " M ")
      (_         " - ")))

   " "

   ;; Modified / Read-only status
   mode-line-modified

   " "

   ;; Buffer name
   mode-line-buffer-identification

   " "

   ;; Line, column, percentage through file
   mode-line-position

   " "

   ;; Git / VC status
   vc-mode

   " "

   ;; Major mode + minor modes
   mode-line-modes

   " "

   ;; Miscellaneous info
   mode-line-misc-info

   ;; Eglot
   (:eval
    (when (bound-and-true-p eglot--managed-mode)
      " | LSP"))

   ;; Flymake
   (:eval
    (when (bound-and-true-p flymake-mode)
      " | Flymake"))

   ;; Push everything after this to the right
   (:eval
    (propertize
     " "
     'display
     '(space :align-to (- right 7))))

   ;; Encoding / EOL information
   mode-line-mule-info

   " "
   ;; Time
   display-time-string ))

;;; VISUAL POLISH
(global-hl-line-mode 1)
(setq truncate-lines t)
(show-paren-mode 1)
(setq show-paren-delay 0)

;;; ui.el ends here

;;; dired.el --- File manager configuration
;;; Dired is Emacs' built-in file manager.
;;; Goal: make it feel like ranger — two panes, vim keys, fast.

;;; ============================================================
;;; SECTION 1: CORE DIRED SETTINGS
;;; ============================================================

(use-package dired
  :ensure nil                         ; Built-in, no install
  :commands dired
  :custom
  (dired-listing-switches "-agho --group-directories-first")
  ;; -a  show hidden files
  ;; -g  hide owner column
  ;; -h  human readable sizes (1K, 2M)
  ;; -o  hide group column
  ;; --group-directories-first  folders on top

  (dired-dwim-target t)               ; When two dired windows open,
                                      ; default copy/move target is the other one
  (dired-recursive-copies 'always)    ; Copy directories without asking
  (dired-recursive-deletes 'always)   ; Delete directories without asking
  (delete-by-moving-to-trash t)       ; Send to trash instead of permanent delete
  (dired-hide-details-mode t))        ; Hide permissions/dates by default, toggle with (

;; Auto-revert dired when files change on disk.
(add-hook 'dired-mode-hook #'auto-revert-mode)

;;; ============================================================
;;; SECTION 2: DIRED-SUBTREE — INLINE DIRECTORY EXPANSION
;;; ============================================================

;; Instead of opening a new buffer for every subdirectory,
;; dired-subtree expands it inline — like a tree view.
;; TAB on a directory expands/collapses it in place.

(use-package dired-subtree
  :ensure t
  :after dired
  :config
  (define-key dired-mode-map (kbd "TAB") #'dired-subtree-toggle)
  (define-key dired-mode-map (kbd "<backtab>") #'dired-subtree-cycle))

;;; ============================================================
;;; SECTION 3: DIRED-OPEN — OPEN FILES WITH SYSTEM APPS
;;; ============================================================

;; Opens files with the correct system application.
;; PDFs open in your PDF viewer, images in your image viewer, etc.
;; Without this, Emacs tries to open everything as text.

(use-package dired-open
  :ensure t
  :after dired
  :config
  (setq dired-open-extensions
        '(("png"  . "feh")
          ("jpg"  . "feh")
          ("jpeg" . "feh")
          ("gif"  . "feh")
          ("mp4"  . "mpv")
          ("mkv"  . "mpv")
          ("mp3"  . "mpv")
          ("pdf"  . "zathura"))))

;;; ============================================================
;;; SECTION 4: NERD-ICONS-DIRED — FILE ICONS
;;; ============================================================

;; Adds file type icons to dired entries.
;; Requires a Nerd Font installed (bootstrap.sh handles this).
;; Makes scanning a directory visually much faster.

(use-package nerd-icons-dired
  :ensure t
  :after dired
  :hook (dired-mode . nerd-icons-dired-mode))

;;; ============================================================
;;; SECTION 5: KEYBINDINGS
;;; ============================================================

;; All vim navigation keys for dired.
;; These were defined in evil.el (hjkl) but we add
;; more dired-specific bindings here, keeping them together.

(with-eval-after-load 'dired

  ;; Navigation (set in evil.el: j k h l q g g G)

  ;; File operations
  (define-key dired-mode-map (kbd "n") #'dired-create-empty-file)
  (define-key dired-mode-map (kbd "N") #'dired-create-directory)
  (define-key dired-mode-map (kbd "r") #'dired-do-rename)
  (define-key dired-mode-map (kbd "c") #'dired-do-copy)
  (define-key dired-mode-map (kbd "d") #'dired-do-delete)
  (define-key dired-mode-map (kbd "m") #'dired-mark)
  (define-key dired-mode-map (kbd "u") #'dired-unmark)
  (define-key dired-mode-map (kbd "U") #'dired-unmark-all-marks)
  (define-key dired-mode-map (kbd "R") #'dired-do-rename)

  ;; Toggle hidden files with .
  (define-key dired-mode-map (kbd ".") #'dired-hide-dotfiles-mode)

  ;; Open with system app
  (define-key dired-mode-map (kbd "o") #'dired-open-file))

;;; ============================================================
;;; SECTION 6: HIDE DOTFILES BY DEFAULT
;;; ============================================================

;; Dotfiles are hidden by default, toggle with . key.
;; Keeps dired clean when browsing projects.

(use-package dired-hide-dotfiles
  :ensure t
  :hook (dired-mode . dired-hide-dotfiles-mode))

;;; dired.el ends here

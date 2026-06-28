;;; evil.el --- Vim layer, toggleable, with leader key bindings

;;; ============================================================
;;; EMACS/VIM MODE TOGGLE & EVIL SETUP
;;; ============================================================

(defvar suhas/vim-mode-enabled t
  "Whether to use Vim keybindings (evil-mode). Toggle with suhas/toggle-vim-mode.")

(use-package evil
  :defer t  ; 1. Tells use-package NOT to load evil at startup
  :init
  ;; 2. Set necessary configuration variables before loading
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  ;; 3. Any configuration that needs evil loaded goes here
  )

;; 4. Check the variable and enable evil AFTER the frame and UI load completely
(add-hook 'emacs-startup-hook
          (lambda ()
            (when suhas/vim-mode-enabled
              (evil-mode 1))))

;; Your toggle commands remain unchanged and work instantly
(defun suhas/toggle-vim-mode ()
  "Toggle evil mode globally."
  (interactive)
  (setq suhas/vim-mode-enabled (not suhas/vim-mode-enabled))
  (if suhas/vim-mode-enabled
      (progn
        (evil-mode 1)
        (message "🔴 Vim mode ENABLED"))
    (progn
      (evil-mode -1)
      (message "🟢 Emacs mode ENABLED"))))

(defun suhas/evil-local-mode-toggle ()
  "Toggle evil mode for the current buffer only."
  (interactive)
  (evil-local-mode 'toggle)
  (if evil-local-mode
      (message "Buffer: Vim mode")
    (message "Buffer: Emacs mode")))

;;; ============================================================
;;; EVIL CONFIGURATION
;;; ============================================================

;; Configure Evil BEFORE loading it. These variables control its behavior.

;; Don't bind to every key globally. We'll use general.el for leader bindings.
(setq evil-want-keybinding nil)

;; Enable Evil's general integration (for dired, help-mode, etc).
(setq evil-want-integration t)

;; C-u scrolls up (Vim convention), not universal-argument.
(setq evil-want-C-u-scroll t)

;; After undo, redo with C-r (standard Vim).
(setq evil-undo-system 'undo-redo)

;; When you split a window, new window appears below (not above).
(setq evil-split-window-below t)
;; When you vsplit, new window appears to the right (not left).
(setq evil-vsplit-window-right t)

;; Treat wrapped lines as multiple lines (for j/k navigation).
(setq evil-respect-visual-line-mode t)

;;; ============================================================
;;; ESCAPE KEY
;;; ============================================================

;; ESC quits everything (minibuffer, visual mode, etc).
;; This is universal and expected.
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;;; ============================================================
;;; GENERAL.EL — Leader key setup
;;; ============================================================

;; general.el lets us define leader-key bindings in one place.
;; SPC is our leader key (Vim convention).
;; All SPC-prefixed commands are defined here.

(use-package general
  :after evil
  :config

  ;; Define the leader key. Only works in normal/visual state.
  (general-create-definer suhas/leader
    :states '(normal visual)
    :keymaps 'override
    :prefix "SPC")

  ;; ── File operations ────────────────────────────────────────
  (suhas/leader
    "f f" #'find-file
    "f s" #'save-buffer
    "f r" #'consult-recent-file
    "f d" #'dired)

  ;; ── Buffer operations ──────────────────────────────────────
  (suhas/leader
    "SPC" #'consult-buffer      ; SPC SPC = quick buffer switch
    "k"   #'kill-current-buffer ; SPC k = kill buffer
    "b i" #'ibuffer             ; SPC b i = buffer list
    "b l" #'buffer-list)
  

  ;; ── Window operations ──────────────────────────────────────
  (suhas/leader
    "w v" #'evil-window-vsplit
    "w s" #'evil-window-split
    "w k" #'evil-window-up
    "w j" #'evil-window-down
    "w h" #'evil-window-left
    "w l" #'evil-window-right
    "w q" #'evil-window-delete
    "w o" #'delete-other-windows
    "w =" #'balance-windows
    "w r" #'suhas/rotate-windows)

  ;; ── Search operations ──────────────────────────────────────
  (suhas/leader
    "s s" #'consult-line       ; Search in current buffer
    "s g" #'consult-grep       ; Grep project
    "s f" #'consult-find)      ; Find file by name

  ;; ── Config management ──────────────────────────────────────
  (suhas/leader
    "c e" #'suhas/open-config
    "c r" #'suhas/reload-config
    "c v" #'suhas/toggle-vim-mode  ; Toggle vim mode
    "s r" #'consult-ripgrep
    "c m" #'suhas/toggle-modeline-verbose)

  ;; ── Terminal ───────────────────────────────────────────────
  (suhas/leader
    "t t" #'suhas/open-terminal  ; Open terminal (defined in terminal.el)
    "t k" #'suhas/close-terminal)

  ;; ── LSP / Errors ───────────────────────────────────────────
  (suhas/leader
    "e n" #'flymake-goto-next-error
    "e p" #'flymake-goto-prev-error
    "e l" #'flymake-show-buffer-diagnostics
    "e a" #'eglot-code-actions
    "e r" #'eglot-rename
    "e f" #'eglot-format-buffer
    "f o" #'formar-all-buffer)


  ;; ── Compile ────────────────────────────────────────────────
  (suhas/leader
    "m c" #'compile)  ; SPC m c = compile

  ;; ── Theme ──────────────────────────────────────────────────
  (suhas/leader
    "u t" #'suhas/theme-menu)  ; SPC u t = theme menu

  ;; ── Workspace operations ───────────────────────────────────
  (suhas/leader
    "a n" #'tab-bar-new-tab
    "a k" #'tab-bar-close-tab
    "a r" #'tab-bar-rename-tab
    "a l" #'tab-bar-switch-to-next-tab
    "a h" #'tab-bar-switch-to-prev-tab)

  ;; ── Project operations ─────────────────────────────────────
  (suhas/leader
    "p f" #'project-find-file
    "p g" #'project-find-regexp
    "p s" #'project-search
    "p r" #'project-query-replace
    "p b" #'project-switch-to-buffer
    "p d" #'project-dired
    "p k" #'project-kill-buffers)

  ;; ── MAGIT ──────────────────────────────────────────────────
  (suhas/leader "g s" #'magit-status "g l" #'magit-log "g b" #'magit-blame)

  ;; ── ORG ──────────────────────────────────────────────────--
  (suhas/leader "o a" #'org-agenda "o c" #'org-capture "o l" #'org-store-link))


;;; ============================================================
;;; GLOBAL KEYBINDINGS (work in any mode, any state)
;;; ============================================================

;; Rotate through buffers (smart buffer navigation).
;; These are defined globally so they work everywhere.
(global-set-key (kbd "C-;") #'suhas/prev-buffer)   ;; but this rotates through all teh code buffers
(global-set-key (kbd "C-'") #'suhas/next-buffer)   ;; this does the toggle-last-buffer function instead of C-,

;;; BUFFER TOGGLE (C-' for last two)
(global-set-key (kbd "C-,") #'suhas/toggle-last-buffer)

;; Workspace switching with Meta+1..9
(defun suhas/switch-to-tab (n)
  "Switch to workspace tab N."
  (let* ((tabs (tab-bar-tabs))
         (tab (nth (1- n) tabs)))
    (when tab
      (tab-bar-select-tab-by-name (alist-get 'name tab)))))

(global-set-key (kbd "M-1") (lambda () (interactive) (suhas/switch-to-tab 1)))
(global-set-key (kbd "M-2") (lambda () (interactive) (suhas/switch-to-tab 2)))
(global-set-key (kbd "M-3") (lambda () (interactive) (suhas/switch-to-tab 3)))
(global-set-key (kbd "M-4") (lambda () (interactive) (suhas/switch-to-tab 4)))
(global-set-key (kbd "M-5") (lambda () (interactive) (suhas/switch-to-tab 5)))
(global-set-key (kbd "M-6") (lambda () (interactive) (suhas/switch-to-tab 6)))
(global-set-key (kbd "M-7") (lambda () (interactive) (suhas/switch-to-tab 7)))
(global-set-key (kbd "M-8") (lambda () (interactive) (suhas/switch-to-tab 8)))
(global-set-key (kbd "M-9") (lambda () (interactive) (suhas/switch-to-tab 9)))

;;; ============================================================
;;; SPECIAL BUFFER STATES
;;; ============================================================

;; These modes have their own keybindings. We don't force Vim on them.
;; They use Emacs defaults because Vim doesn't make sense there.
(with-eval-after-load 'evil
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'ibuffer-mode 'emacs)
  (evil-set-initial-state 'magit-mode 'emacs)
  (evil-set-initial-state 'magit-status-mode 'emacs)
  (evil-set-initial-state 'magit-log-mode 'emacs)
  (evil-set-initial-state 'eat-mode 'normal)
  (evil-set-initial-state 'help-mode 'emacs)
  (evil-set-initial-state 'info-mode 'emacs))

(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "j") #'dired-next-line)
  (define-key dired-mode-map (kbd "k") #'dired-previous-line)
  (define-key dired-mode-map (kbd "h") #'dired-up-directory)
  (define-key dired-mode-map (kbd "l") #'dired-find-file)
  (define-key dired-mode-map (kbd "v") #'dired-toggle-marks)
  (define-key dired-mode-map (kbd "d") #'dired-flag-file-deletion)
  (define-key dired-mode-map (kbd "x") #'dired-do-flagged-delete))
 
(with-eval-after-load 'ibuffer
  (define-key ibuffer-mode-map (kbd "j") #'ibuffer-forward-line)
  (define-key ibuffer-mode-map (kbd "k") #'ibuffer-backward-line)
  (define-key ibuffer-mode-map (kbd "RET") #'ibuffer-visit-buffer)
  (define-key ibuffer-mode-map (kbd "d") #'ibuffer-mark-for-delete)
  (define-key ibuffer-mode-map (kbd "x") #'ibuffer-do-delete))


;;; ============================================================
;;; VERTICO NAVIGATION ENHANCEMENTS
;;; ============================================================

;; When using vertico (minibuffer completion), add vim-like navigation.
;; C-j/C-k to go down/up through candidates.
(with-eval-after-load 'vertico
  (progn
    (set-face-attribute 'vertico-current nil :underline nil)
    (define-key vertico-map (kbd "C-j") #'vertico-next)
    (define-key vertico-map (kbd "C-k") #'vertico-previous)))

;;; evil.el ends here

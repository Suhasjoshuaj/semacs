;;; evil.el --- Vim layer, surgical and clean

;;; ============================================================
;;; SECTION 1: EVIL CORE
;;; ============================================================

(setq evil-want-keybinding nil)
(setq evil-want-integration t)
(setq evil-want-C-u-scroll t)
(setq evil-undo-system 'undo-redo)
(setq evil-split-window-below t)
(setq evil-vsplit-window-right t)
(setq evil-respect-visual-line-mode t)
;;(global-set-key (kbd "C-x C-b") #'ibuffer)

(use-package evil
  :ensure t
  :demand t
  :config
  (evil-mode 1)

  (defvar suhas/cursor-color "#ff6b6b")

  (setq evil-normal-state-cursor  '(hbar . 4))
  (setq evil-insert-state-cursor  '(hbar . 2))
  (setq evil-visual-state-cursor  '(hbar . 4))
  (setq evil-replace-state-cursor '(hbar . 4))
  (setq evil-emacs-state-cursor   '(hbar . 2))

  (advice-add 'evil-set-cursor :override
              (lambda (&rest _)
                (set-cursor-color suhas/cursor-color)
                (setq cursor-type
                      (cond
                       ((eq evil-state 'insert)  '(hbar . 2))
                       ((eq evil-state 'replace) '(hbar . 4))
                       (t                        '(hbar . 4)))))))

;;; ============================================================
;;; SECTION 2: GENERAL.EL — ALL LEADER BINDINGS IN ONE PLACE
;;; ============================================================

;; general.el is loaded with :demand t so it's available immediately.
;; ALL suhas/leader calls across every module live here.
;; Never call suhas/leader from any other module file.

(use-package general
  :ensure t
  :demand t
  :config

  (general-create-definer suhas/leader
    :states '(normal visual)
    :keymaps 'override
    :prefix "SPC")

  ;; ── Files ──────────────────────────────────────────────────
  (suhas/leader
    "f f" #'find-file
    "f s" #'save-buffer
    "f r" #'recentf-open-files
    "f d" #'dired)

  ;; ── Buffers ────────────────────────────────────────────────
  (suhas/leader
    "SPC" #'consult-buffer      ; SPC SPC — instant fuzzy buffer switch
    "k"   #'kill-current-buffer ; SPC k — kill current
    "["   #'previous-buffer     ; SPC [ — cycle left
    "]"   #'next-buffer)        ; SPC ] — cycle right

  ;; ── Windows ────────────────────────────────────────────────
  (suhas/leader
    "w v" #'evil-window-vsplit
    "w s" #'evil-window-split
    "w k" #'evil-window-up
    "w j" #'evil-window-down
    "w h" #'evil-window-left
    "w l" #'evil-window-right
    "w q" #'evil-window-delete
    "w o" #'delete-other-windows)

  ;; ── Config ─────────────────────────────────────────────────
  (suhas/leader
    "c e" #'suhas/open-config
    "c r" #'suhas/reload-config)

  ;; ── Search ─────────────────────────────────────────────────
  (suhas/leader
    "s s" #'consult-line
    "s g" #'consult-grep
    "s f" #'consult-find)

  ;; ── Terminal ───────────────────────────────────────────────
  (suhas/leader
    "t t" #'suhas/open-terminal
    "t n" #'suhas/open-named-terminal
    "t k" #'suhas/close-terminal)

  ;; ── Git ────────────────────────────────────────────────────
  (suhas/leader
    "g g" #'magit-status
    "g b" #'magit-branch
    "g l" #'magit-log-current
    "g d" #'magit-diff-buffer-file
    "g r" #'magit-rebase
    "g s" #'git-gutter:stage-hunk
    "g n" #'git-gutter:next-hunk
    "g p" #'git-gutter:previous-hunk)

  ;; ── LSP / Errors ───────────────────────────────────────────
  (suhas/leader
    "e n" #'flymake-goto-next-error
    "e p" #'flymake-goto-prev-error
    "e l" #'flymake-show-buffer-diagnostics
    "e s" #'eglot-reconnect
    "e a" #'eglot-code-actions
    "e r" #'eglot-rename
    "e f" #'eglot-format-buffer)

  ;; ── Format ─────────────────────────────────────────────────
  (suhas/leader
    "= =" #'apheleia-format-buffer)

  ;; ── Org ────────────────────────────────────────────────────
  (suhas/leader
    "o c" #'suhas/open-config
    "o n" #'org-capture
    "o a" #'org-agenda
    "o e" #'org-export-dispatch
    "o t" #'org-babel-tangle
    "o x" #'org-babel-execute-src-block
    "o X" #'org-babel-execute-buffer)

  ;; ── Workspaces ─────────────────────────────────────────────
  (suhas/leader
    "a n" #'tab-bar-new-tab
    "a k" #'tab-bar-close-tab
    "a r" #'tab-bar-rename-tab
    "a a" #'tab-bar-switch-to-recent-tab  
    "a l" #'tab-bar-switch-to-next-tab
    "a h" #'tab-bar-switch-to-prev-tab)

  ;; ── Projects ───────────────────────────────────────────────
  (suhas/leader
    "p p" #'suhas/project-open-in-tab
    "p f" #'project-find-file
    "p g" #'project-find-regexp
    "p k" #'project-kill-buffers
    "p b" #'project-switch-to-buffer
    "p d" #'project-dired))

;;; ============================================================
;;; SECTION 3: ESCAPE
;;; ============================================================

(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;;; ============================================================
;;; SECTION 4: SPECIAL BUFFER STATES
;;; ============================================================

(with-eval-after-load 'evil
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'ibuffer-mode 'emacs)
  (evil-set-initial-state 'magit-mode 'emacs)
  (evil-set-initial-state 'magit-status-mode 'emacs)
  (evil-set-initial-state 'magit-log-mode 'emacs)
  (evil-set-initial-state 'magit-diff-mode 'emacs)
  (evil-set-initial-state 'help-mode 'emacs)
  (evil-set-initial-state 'info-mode 'emacs))

;;; ============================================================
;;; SECTION 5: NAVIGATION IN SPECIAL BUFFERS
;;; ============================================================

(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "j")   #'dired-next-line)
  (define-key dired-mode-map (kbd "k")   #'dired-previous-line)
  (define-key dired-mode-map (kbd "h")   #'dired-up-directory)
  (define-key dired-mode-map (kbd "l")   #'dired-find-file)
  (define-key dired-mode-map (kbd "q")   #'quit-window)
  (define-key dired-mode-map (kbd "G")   #'end-of-buffer)
  ;; Remove the g g binding — it conflicts with vertico
  ;; Use < instead for beginning of buffer in dired
  (define-key dired-mode-map (kbd "<")   #'beginning-of-buffer))

(with-eval-after-load 'ibuffer
  (define-key ibuffer-mode-map (kbd "j") #'ibuffer-forward-line)
  (define-key ibuffer-mode-map (kbd "k") #'ibuffer-backward-line)
  (define-key ibuffer-mode-map (kbd "G") #'end-of-buffer)
  (define-key ibuffer-mode-map (kbd "g g") #'beginning-of-buffer))

;;; ============================================================
;;; SECTION 6: VERTICO NAVIGATION
;;; ============================================================

(with-eval-after-load 'vertico
  (define-key vertico-map (kbd "C-j")  #'vertico-next)
  (define-key vertico-map (kbd "C-k")  #'vertico-previous)
  (define-key vertico-map (kbd "RET")  #'vertico-directory-enter)
  (define-key vertico-map (kbd "DEL")  #'vertico-directory-delete-char)
  (define-key vertico-map (kbd "C-DEL") #'vertico-directory-up))

;; Global buffer navigation — works in any state, any mode
(global-set-key (kbd "C-,") #'previous-buffer)
(global-set-key (kbd "C-;") #'next-buffer)
(global-set-key (kbd "C-'") #'mode-line-other-buffer)

;;Workspace switching with M-1..
(defun suhas/switch-to-tab (n)
  "Switch to tab number N by position."
  (let* ((tabs (tab-bar-tabs))
         (tab (nth (1- n) tabs)))
    (when tab
      (tab-bar-select-tab-by-name
       (alist-get 'name tab)))))

(global-set-key (kbd "M-1") (lambda () (interactive) (suhas/switch-to-tab 1)))
(global-set-key (kbd "M-2") (lambda () (interactive) (suhas/switch-to-tab 2)))
(global-set-key (kbd "M-3") (lambda () (interactive) (suhas/switch-to-tab 3)))
(global-set-key (kbd "M-4") (lambda () (interactive) (suhas/switch-to-tab 4)))
(global-set-key (kbd "M-5") (lambda () (interactive) (suhas/switch-to-tab 5)))
(global-set-key (kbd "M-6") (lambda () (interactive) (suhas/switch-to-tab 6)))
(global-set-key (kbd "M-7") (lambda () (interactive) (suhas/switch-to-tab 7)))
(global-set-key (kbd "M-8") (lambda () (interactive) (suhas/switch-to-tab 8)))
(global-set-key (kbd "M-9") (lambda () (interactive) (suhas/switch-to-tab 9)))


;;; evil.el ends here

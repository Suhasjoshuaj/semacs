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
  (evil-mode 1))

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
    "b b" #'switch-to-buffer
    "b k" #'kill-this-buffer
    "b i" #'ibuffer
    "b n" #'next-buffer
    "b p" #'previous-buffer)

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
    "TAB n"   #'tab-bar-new-tab
    "TAB k"   #'tab-bar-close-tab
    "TAB r"   #'tab-bar-rename-tab
    "TAB TAB" #'tab-bar-switch-to-recent-tab
    "TAB l"   #'tab-bar-switch-to-next-tab
    "TAB h"   #'tab-bar-switch-to-prev-tab)

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

;; circular buffer navigation
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "] b") #'next-buffer)
  (define-key evil-normal-state-map (kbd "[ b") #'previous-buffer))

;;; evil.el ends here

;;; evil.el --- Vim layer (toggleable) and the general key bindings  -*- lexical-binding: t; -*-
;;;
;;; The leader keymap itself (`suhas/leader-map', `suhas/leader') lives in
;;; core.el and does not need Evil. This file connects it to SPC and holds
;;; the bindings that do not belong to a single module.

;;; ============================================================
;;; EVIL
;;; ============================================================

;; Evil 1.15 on Emacs 31: `evil-initializing-p' reads the deferred-buffer
;; queue `evil-mode-buffers', which `define-globalized-minor-mode' no
;; longer defines -> "(void-variable evil-mode-buffers)" after every
;; command. `defvar' never overwrites a bound value, so this is harmless
;; once Evil defines it itself.
(defvar evil-mode-buffers nil)

;; Defined before Evil's :config below, which fills its keymap.
(define-minor-mode suhas/leader-mode
  "Global mode whose keymap carries the SPC leader for Evil states."
  :global t
  :group 'convenience
  :keymap (make-sparse-keymap))

(use-package evil
  :commands (evil-mode evil-local-mode)
  :init
  ;; All of these are read while Evil loads.
  (setq evil-want-integration t
        evil-want-keybinding nil        ; evil-collection provides those
        evil-want-C-u-scroll t          ; C-u scrolls up, as in Vim
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-respect-visual-line-mode t) ; j/k follow wrapped lines
  :config
  ;; C-r redoes, with Emacs's built-in undo. Must go through the setter:
  ;; a plain `setq' leaves Evil's redo function unset.
  (evil-set-undo-system 'undo-redo)

  ;; Normal state binds M-. to `evil-repeat-pop-next', hiding xref's
  ;; jump-to-definition (`gd' does the same job), and C-. to
  ;; `evil-repeat-pop', hiding the terminal map (terminal.el).
  (keymap-unset evil-normal-state-map "M-." t)
  (keymap-unset evil-normal-state-map "C-." t)

  ;; dired, Info and magit keep their native keys (Emacs state).
  ;; (`magit-mode' covers every magit buffer; the repo list is separate.)
  (dolist (mode '(dired-mode Info-mode magit-mode magit-repolist-mode))
    (evil-set-initial-state mode 'emacs))

  ;; SPC = leader in normal/visual/motion state. An intercept map, so no
  ;; mode's own SPC binding can shadow it.
  (dolist (state '(normal visual motion))
    (evil-define-key* state suhas/leader-mode-map (kbd "SPC") suhas/leader-map)
    (evil-make-intercept-map
     (evil-get-auxiliary-keymap suhas/leader-mode-map state t t) state))
  (suhas/leader-mode 1)

  (evil-collection-init '(ibuffer compile speedbar xref)))

;; Complete Vim-style bindings for the modes listed in the init call above:
;;   ibuffer   marking/deleting need it to work at all
;;   compile   moving around *compilation*
;;   xref      RET on a result
;;   speedbar  see below
(use-package evil-collection
  :commands (evil-collection-init
             evil-collection-define-key
             evil-collection-set-readonly-bindings))

(defun suhas/maybe-enable-evil ()
  "Turn Evil on at startup unless `suhas/vim-mode-enabled' is nil.
An error here (package missing or broken) is reported, never fatal."
  (when suhas/vim-mode-enabled
    (with-demoted-errors "semacs: could not start Evil: %S"
      (evil-mode 1))))
(add-hook 'emacs-startup-hook #'suhas/maybe-enable-evil)

(defun suhas/toggle-vim-mode ()
  "Toggle Evil globally (SPC c v / C-c v)."
  (interactive)
  (setq suhas/vim-mode-enabled (not suhas/vim-mode-enabled))
  (evil-mode (if suhas/vim-mode-enabled 1 -1))
  (message "%s keys" (if suhas/vim-mode-enabled "Vim" "Emacs")))

(defun suhas/evil-local-mode-toggle ()
  "Toggle Evil for the current buffer only (SPC c l)."
  (interactive)
  (evil-local-mode 'toggle)
  (message "This buffer: %s keys" (if evil-local-mode "Vim" "Emacs")))

;;; ============================================================
;;; PER-MODE TOUCHES
;;; ============================================================

;; help and flymake diagnostics: normal state for movement, plus a working
;; `q' (normal state would otherwise claim it for macro recording).
(with-eval-after-load 'help-mode
  (with-eval-after-load 'evil
    (evil-set-initial-state 'help-mode 'normal)
    (evil-collection-set-readonly-bindings 'help-mode-map)))

(with-eval-after-load 'flymake
  (with-eval-after-load 'evil
    (evil-collection-set-readonly-bindings 'flymake-diagnostics-buffer-mode-map)
    (evil-collection-set-readonly-bindings 'flymake-project-diagnostics-mode-map)))

(with-eval-after-load 'evil-collection-speedbar
  (evil-collection-define-key '(normal motion) 'speedbar-file-key-map
    (kbd "SPC")            #'speedbar-toggle-line-expansion
    "o"                    #'speedbar-toggle-line-expansion
    "n"                    #'speedbar-next
    "p"                    #'speedbar-prev
    "q"                    #'suhas/speedbar-close
    (kbd "<down-mouse-1>") #'mouse-drag-region
    (kbd "<mouse-2>")      #'speedbar-click))

;; Emacs-state buffers have no Evil leader, so SPC opens the same leader
;; map there. A minor mode, because several magit modes bind SPC in their
;; own keymap and minor-mode maps win over every major-mode map.
;; (In magit, scroll the diff with C-v / M-v instead of SPC.)
(define-minor-mode suhas/emacs-leader-mode
  "SPC opens `suhas/leader-map' in this (Emacs-state) buffer."
  :keymap (let ((map (make-sparse-keymap)))
            (keymap-set map "SPC" suhas/leader-map)
            map))

(dolist (hook '(dired-mode-hook magit-mode-hook magit-repolist-mode-hook))
  (add-hook hook #'suhas/emacs-leader-mode))

;;; ============================================================
;;; ESCAPE
;;; ============================================================

;; C-c ESC and C-x ESC: back to Evil's normal state from anywhere, also
;; while typing in a terminal (where plain ESC belongs to the program).
;; These bind the Escape KEY, not the Meta prefix: Alt chords such as
;; C-x M-: keep working. Terminal Emacs tells a lone Esc from Alt by a
;; 10 ms pause (Evil's `evil-esc-delay'), in Vim-state buffers.
(defun suhas/normal-state ()
  "Go to Evil's normal state; without Vim keys, act like ESC."
  (interactive)
  (if (and (bound-and-true-p evil-local-mode)
           (not (evil-emacs-state-p)))
      (evil-force-normal-state)
    (suhas/escape)))

(keymap-global-set "C-c <escape>" #'suhas/normal-state)
(keymap-global-set "C-x <escape>" #'suhas/normal-state)

;; ESC quits the region / minibuffer / running command -- but NOT through
;; `keyboard-escape-quit', whose last resort is `delete-other-windows':
;; one stray ESC outside normal state closed every other window.
(defun suhas/escape ()
  "Quit the region / minibuffer / running command; never touches windows."
  (interactive)
  (cond ((region-active-p) (deactivate-mark))
        ((> (minibuffer-depth) 0) (abort-recursive-edit))
        (t (keyboard-quit))))
(keymap-global-set "<escape>" #'suhas/escape)

;;; ============================================================
;;; LEADER BINDINGS (the ones no single module owns)
;;; ============================================================
;; Module-specific keys sit next to their commands: terminal.el (t),
;; magit.el (g), org.el (o), devtools.el (d), doctor.el (c h ...).

(suhas/leader
 ;; ── Files ──────────────────────────────────────────────────
 "f"   "files"
 "f f" #'find-file
 "f s" #'save-buffer
 "f r" #'consult-recent-file
 "f d" #'dired
 "f y" #'suhas/copy-location        ; path:line -> kill ring

 ;; ── Search (search.el) ─────────────────────────────────────
 "s"   "search"
 "s s" #'consult-line               ; text in this buffer
 "s i" #'consult-imenu              ; function/class in this file
 "s g" #'suhas/grep-project         ; text in the project (rg)
 "s G" #'suhas/grep-everywhere      ; text in ALL repos (rg)
 "s f" #'suhas/find-file-everywhere ; file by NAME in ALL repos (fd)

 ;; ── Buffers ────────────────────────────────────────────────
 "SPC" #'consult-buffer
 "b"   "buffers"
 "b i" #'ibuffer
 "b n" #'suhas/next-buffer          ; C-;
 "b p" #'suhas/prev-buffer          ; C-'
 "b b" #'suhas/toggle-last-buffer   ; C-,

 ;; ── Windows ────────────────────────────────────────────────
 "w"   "windows"
 "w v" #'split-window-right
 "w s" #'split-window-below
 "w h" #'windmove-left
 "w j" #'windmove-down
 "w k" #'windmove-up
 "w l" #'windmove-right
 "w q" #'delete-window
 "w o" #'delete-other-windows
 "w =" #'balance-windows
 "w r" #'suhas/rotate-windows

 ;; ── Workspaces (window-mgmt.el; M-1..M-9 jump by number) ───
 "v"   "workspaces"
 "v n" #'persp-switch               ; switch, or create by typing a new name
 "v k" #'persp-kill
 "v r" #'persp-rename
 "v l" #'persp-next
 "v h" #'persp-prev
 "v b" #'persp-switch-to-buffer*
 "v a" #'persp-add-buffer

 ;; ── Projects ───────────────────────────────────────────────
 "p"   "projects"
 "p p" #'suhas/project-switch
 "p f" #'project-find-file
 "p n" #'suhas/project-mark         ; mark a non-git folder as a project
 "p r" #'project-query-replace-regexp
 "p b" #'project-switch-to-buffer
 "p d" #'project-dired
 "p k" #'project-kill-buffers

 ;; ── Code (lsp.el, formatter.el) ────────────────────────────
 "e"   "code"
 "e n" #'flymake-goto-next-error
 "e p" #'flymake-goto-prev-error
 "e l" #'consult-flymake
 "e a" #'eglot-code-actions
 "e r" #'eglot-rename
 "e f" #'suhas/format-buffer

 ;; ── Vim mode ───────────────────────────────────────────────
 "c v" #'suhas/toggle-vim-mode
 "c l" #'suhas/evil-local-mode-toggle)

;;; ============================================================
;;; GLOBAL KEYS (any mode, any state)
;;; ============================================================

;; Switch window: C-c o is the same as C-x o, everywhere (C-c LETTER is
;; reserved for the user, so no package binds it).
(keymap-global-set "C-c o" #'other-window)

(keymap-global-set "C-;" #'suhas/next-buffer)
(keymap-global-set "C-'" #'suhas/prev-buffer)
(keymap-global-set "C-," #'suhas/toggle-last-buffer)
(keymap-global-set "C-c v" #'suhas/toggle-vim-mode)

 ;; ── cursor movement with M-p,n ────────────────────────────

(defvar suhas/m-np-keep-modes nil
  "Major modes where M-n / M-p keep their own meaning, e.g. '(magit-mode).")

(defun suhas/m-np-override-p ()
  "Non-nil where M-n / M-p should move lines."
  (not (or (minibufferp)
           (bound-and-true-p completion-in-region-mode)   ; corfu popup open
           (derived-mode-p suhas/m-np-keep-modes))))

(bind-key* "M-n" #'next-line (suhas/m-np-override-p))
(bind-key* "M-p" #'previous-line (suhas/m-np-override-p))

;; org and flyspell (commit messages, org, markdown) bind C-; C-' C-, C-.
;; for themselves, which would silently break the keys above in those
;; buffers. Their commands stay reachable: flyspell's correction on M-TAB,
;; org's agenda cycling from the agenda.
(with-eval-after-load 'flyspell
  (dolist (key '("C-;" "C-," "C-."))
    (keymap-unset flyspell-mode-map key t)))
(with-eval-after-load 'org
  (dolist (key '("C-'" "C-,"))
    (keymap-unset org-mode-map key t)))

;; Terminal Emacs cannot tell C-; C-' C-, from the plain keys.
(keymap-global-set "C-c n" #'suhas/next-buffer)
(keymap-global-set "C-c p" #'suhas/prev-buffer)
(keymap-global-set "C-c b" #'suhas/toggle-last-buffer)

;;; evil.el ends here

;;; evil.el --- Vim layer, toggleable, with leader key bindings  -*- lexical-binding: t; -*-

;;; ============================================================
;;; EMACS/VIM MODE TOGGLE & EVIL SETUP
;;; ============================================================

;; `suhas/vim-mode-enabled' (default t) is defined in settings.el.

;; Emacs 31 + Evil 1.15: `define-globalized-minor-mode' no longer defines
;; the deferred-buffer queue `evil-mode-buffers', but Evil's own
;; `evil-initializing-p' (called from `evil-normal-post-command') still
;; reads it -> "(void-variable evil-mode-buffers)" after every command.
;; An empty legacy queue restores the old behaviour. `defvar' never
;; overwrites a value that is already bound, so this is harmless on
;; Emacs 30 and on any Evil that defines the variable itself.
(defvar evil-mode-buffers nil)

(use-package evil
  :defer t  ; 1. Tells use-package NOT to load evil at startup
  :init
  ;; 2. Set necessary configuration variables before loading
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  ;; 3. Any configuration that needs evil loaded goes here
  (customize-set-variable 'evil-undo-system 'undo-redo)
  )

;; 4. Check the variable and enable evil AFTER the frame and UI load completely
(defun suhas/maybe-enable-evil ()
  "Turn Evil on at startup unless `suhas/vim-mode-enabled' is nil."
  (when suhas/vim-mode-enabled
    (evil-mode 1)))
(add-hook 'emacs-startup-hook #'suhas/maybe-enable-evil)

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

;; (evil-want-keybinding / evil-want-integration are set once, in the
;; `use-package evil' :init above -- they were duplicated here.)

;; evil-collection gives whole modes (dired, ibuffer, magit, ...) a
;; complete, maintained set of vim-native bindings instead of leaving
;; evil's normal-state map to shadow their own keys. It needs the two
;; variables above set *before* evil loads, which they already are.
;;
;; Scoped to the modes where you want the full vim-style binding set:
;;   ibuffer         marking/deleting need this to work at all
;;   compile         you use it directly
;;   magit           NOT here: magit buffers run in plain EMACS state with
;;                   magit's own native keys (n/p, s/u, k, c...). See
;;                   "SPECIAL BUFFER STATES" below. To go back to the vim-style
;;                   magit, add `magit' to the list below and delete the
;;                   magit lines in that section.
;;   xref            RET on a result works (evil's RET used to shadow it)
;; Everything else gets a lighter touch below.
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init '(ibuffer compile speedbar xref)))

;; help and flymake diagnostics: you don't use these enough to
;; want their full mnemonic binding set (gj/go/]]/etc.), just vim
;; movement plus a working quit key. `evil-collection-set-readonly-bindings'
;; is the one piece that's not optional -- evil's normal state claims
;; `q' globally for macro recording, which would otherwise silently
;; break "quit this buffer" the moment you switch these to normal
;; state. Nothing else about these modes changes: RET on a link, TAB
;; between buttons, all native functionality, untouched.
(with-eval-after-load 'help-mode
  (with-eval-after-load 'evil
    (with-eval-after-load 'evil-collection
      (evil-set-initial-state 'help-mode 'normal)
      (evil-collection-set-readonly-bindings 'help-mode-map))))

;; (The hand-rolled xref block is gone: evil-collection's xref module, in
;; the init list above, does it properly, and M-. now uses consult-xref
;; anyway -- see completion.el.)

;; flymake-diagnostics-buffer-mode has no explicit evil-set-initial-state
;; call -- it doesn't need one, evil's own default state is already
;; 'normal for any major mode with no override, this just adds the
;; quit-key fix.
(with-eval-after-load 'flymake
  (with-eval-after-load 'evil
    (with-eval-after-load 'evil-collection
      (evil-collection-set-readonly-bindings 'flymake-diagnostics-buffer-mode-map)
      (evil-collection-set-readonly-bindings 'flymake-project-diagnostics-mode-map))))

;; speedbar with evil collisions.
(with-eval-after-load 'speedbar
(with-eval-after-load 'evil-collection-speedbar
  (evil-collection-define-key '(normal motion) 'speedbar-file-key-map
    (kbd "SPC")            #'speedbar-toggle-line-expansion
    "o"                    #'speedbar-toggle-line-expansion
    "n"                    #'speedbar-next
    "p"                    #'speedbar-prev
    "q"                    (lambda () (interactive) (speedbar-window--close))
    (kbd "<down-mouse-1>") #'mouse-drag-region
    (kbd "<mouse-2>")      #'speedbar-click)))

;; C-u scrolls up (Vim convention), not universal-argument.
(setq evil-want-C-u-scroll t)

;; After undo, redo with C-r (standard Vim).
;;(setq evil-undo-system 'undo-redo)

;; When you split a window, new window appears below (not above).
(setq evil-split-window-below t)
;; When you vsplit, new window appears to the right (not left).
(setq evil-vsplit-window-right t)

;; Treat wrapped lines as multiple lines (for j/k navigation).
(setq evil-respect-visual-line-mode t)

;;; ============================================================
;;; ESCAPE KEY
;;; ============================================================

;; ESC quits everything (minibuffer, region, ...) -- but NOT by way of
;; `keyboard-escape-quit'. That command's last resort is
;; `delete-other-windows': in any buffer that is not in evil normal state
;; (dired used to be one, Info/emacs-state buffers, vim-mode off) one
;; stray ESC closed every other window, terminal included.
(defun suhas/escape ()
  "Quit the region / minibuffer / running command; never touches windows."
  (interactive)
  (cond ((region-active-p) (deactivate-mark))
        ((> (minibuffer-depth) 0) (abort-recursive-edit))
        (t (keyboard-quit))))
(global-set-key (kbd "<escape>") #'suhas/escape)

;; evil's normal state binds M-. to `evil-repeat-pop-next', which hid
;; xref's jump-to-definition (the README said M-. worked: only in insert
;; state). Free it so M-. works in every state; `gd' does the same job.
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "M-.") nil))
;;(global-set-key (kbd "M-o") #'other-window)                           -- fix the binding. ( only goes to lower buffer but not rotating like C-x o)

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

  ;; ── Search (details: search.el) ────────────────────────────
  (suhas/leader
    "s s" #'consult-line               ; text in the current buffer
    "s i" #'consult-imenu              ; jump to a function/class in this file
    "s g" #'suhas/grep-project         ; text in the current project (rg)
    "s G" #'suhas/grep-everywhere      ; text in ALL repos (rg)
    "s f" #'suhas/find-file-everywhere); file by NAME in ALL repos (fd)

  ;; ── Buffer operations ──────────────────────────────────────
  (suhas/leader
    "SPC" #'consult-buffer      ; SPC SPC = quick buffer switch
    "k"   #'kill-current-buffer ; SPC k = kill buffer
    "b i" #'ibuffer             ; SPC b i = buffer list
    "b n" #'suhas/next-buffer   ; same as C-;  (also works in terminal Emacs)
    "b p" #'suhas/prev-buffer   ; same as C-'
    "b b" #'suhas/toggle-last-buffer) ; same as C-,
  

  ;; ── Window operations ──────────────────────────────────────
  (suhas/leader
    "w v" #'evil-window-vsplit
    "w s" #'evil-window-split
    "w h" #'evil-window-left
    "w j" #'evil-window-down
    "w k" #'evil-window-up
    "w l" #'evil-window-right
    "w q" #'evil-window-delete
    "w o" #'delete-other-windows
    "w =" #'balance-windows
    "w r" #'suhas/rotate-windows)


  ;; ── Config management ──────────────────────────────────────
  (suhas/leader
    "c e" #'suhas/open-config       ; fuzzy-open any file of this config
    "c o" #'suhas/open-local        ; open local.el (your machine settings)
    "c r" #'suhas/reload-config
    "c v" #'suhas/toggle-vim-mode   ; Toggle vim mode (all buffers)
    "c l" #'suhas/evil-local-mode-toggle ; Toggle vim mode (this buffer only)
    "l w" #'suhas/toggle-line-wrap  ; Toggle line wrapping
    )

  ;; ── Terminal ───────────────────────────────────────────────
  (suhas/leader
    "t t" #'suhas/open-terminal
    "t n" #'suhas/terminal-create-named
    "t s" #'suhas/terminal-switch
    "t l" #'suhas/terminal-next
    "t h" #'suhas/terminal-prev
    "t r" #'suhas/terminal-rename
    "t k" #'suhas/terminal-kill
    "t K" #'suhas/terminal-kill-all
    "t p" #'suhas/terminal-set-position
    "t e" #'suhas/terminal-toggle-escape)
  
  ;; ── LSP / Errors ───────────────────────────────────────────
  (suhas/leader
    "e n" #'flymake-goto-next-error
    "e p" #'flymake-goto-prev-error
    "e l" #'consult-flymake            ; jumpable list with live preview
    "e a" #'eglot-code-actions
    "e r" #'eglot-rename
    "e f" #'eglot-format-buffer
    "e o" #'format-all-buffer) ; non-LSP fallback formatter (black/prettier/clang-format/...)


  ;; ── Compile ────────────────────────────────────────────────
  ;; "m c" starts a build; from then on you never have to switch into
  ;; the *compilation* buffer to work through errors. next-error/
  ;; previous-error track whichever compile/grep buffer ran most
  ;; recently and jump straight to that location in your source file --
  ;; that's the actual Emacs compile workflow, distinct from the gj/gk
  ;; and ]]/[[ bindings evil-collection gives you for moving around
  ;; *inside* the compilation buffer itself (see below).
  (suhas/leader
    "m b" #'suhas/run-current-file ; SPC m b = build/run THIS file (by language)
    "m c" #'compile             ; SPC m c = start a compile
    "m r" #'recompile           ; SPC m r = re-run the last compile command
    "m n" #'next-error          ; SPC m n = jump to next error, from anywhere
    "m p" #'previous-error      ; SPC m p = jump to previous error, from anywhere
    "m g" #'first-error         ; SPC m g = jump back to the first error
    "m k" #'kill-compilation)   ; SPC m k = stop a running build

  ;; ── Theme ──────────────────────────────────────────────────
  (suhas/leader
    "u t" #'suhas/theme-menu   ; SPC u t = theme menu
    "u n" #'suhas/next-theme   ; SPC u n = next theme
    "u p" #'suhas/prev-theme)  ; SPC u p = previous theme

  ;; ── Perspective (THE workspace system; M-1..M-9 jump by number) ─
  (suhas/leader
    "v n" #'persp-switch            ; prompts for a name; creates if it doesn't exist
    "v k" #'persp-kill
    "v r" #'persp-rename
    "v l" #'persp-next
    "v h" #'persp-prev
    "v b" #'persp-switch-to-buffer* ; buffer list scoped to current perspective only
    "v a" #'persp-add-buffer)       ; pull an existing buffer into this perspective

  ;; ── Project operations ─────────────────────────────────────
  ;; (p g / p s -- project-find-regexp / project-search -- are gone:
  ;; "s g" is the same job with ripgrep, a preview, and no *xref* buffer.)
  (suhas/leader
    "p p" #'suhas/project-switch       ; any project (new repos auto-found)
    "p f" #'project-find-file          ; fuzzy file in the current project
    "p n" #'suhas/project-mark         ; mark a non-git folder as a project
    "p r" #'project-query-replace
    "p b" #'project-switch-to-buffer
    "p d" #'project-dired
    "p k" #'project-kill-buffers)
  ;; ── MAGIT ──────────────────────────────────────────────────
  (suhas/leader "g s" #'magit-status "g l" #'magit-log "g b" #'magit-blame
                "g r" #'magit-list-repositories)  ; overview of ALL your repos

  ;; (Org's SPC o ... bindings live in org.el.)
  )



;;; ============================================================
;;; GLOBAL KEYBINDINGS (work in any mode, any state)
;;; ============================================================

;; Rotate through buffers (smart buffer navigation).
;; These are defined globally so they work everywhere.
(global-set-key (kbd "C-'") #'suhas/prev-buffer)   ; previous code buffer
(global-set-key (kbd "C-;") #'suhas/next-buffer)   ; next code buffer
;; (C-c f / C-c g are defined in search.el next to the commands they run.)

;; since i can't use the vim bind in emacs mode
(global-set-key (kbd "C-c v") #'suhas/toggle-vim-mode)

;;; BUFFER TOGGLE (C-, jumps between the last two buffers)
(global-set-key (kbd "C-,") #'suhas/toggle-last-buffer)

;; TTY-safe twins of C-; C-' C-, (terminal Emacs cannot tell those chords
;; apart from plain keys; C-c <letter> always works). Workspace switching
;; with M-1..M-9 is defined in window-mgmt.el, next to perspective.
(global-set-key (kbd "C-c n") #'suhas/next-buffer)
(global-set-key (kbd "C-c p") #'suhas/prev-buffer)
(global-set-key (kbd "C-c b") #'suhas/toggle-last-buffer)

;;; ============================================================
;;; SPECIAL BUFFER STATES
;;; ============================================================

;; xref / ibuffer / compile / speedbar get their vim bindings AND
;; their initial state from evil-collection (list above).
;;
;; dired and Info stay in EMACS state, keeping their native keys:
;;   dired: i insert subdir, a open in this buffer, o sort, ^ up, m/u/d
;;          mark, R rename, + mkdir, C-x C-q editable dired (wdired).
;;   (evil-collection-dired moved these -- insert-subdir to I, wdired to
;;   i -- which broke the keys you were used to.)
;; The mode name is `Info-mode' with a capital I: the old `info-mode' was
;; no mode at all, so that line never did anything.
(with-eval-after-load 'evil
  (evil-set-initial-state 'dired-mode 'emacs)
  (evil-set-initial-state 'Info-mode 'emacs)
  ;; Magit: every magit buffer (status, log, diff, revision, process, refs,
  ;; stash, cherry, log-select...) derives from `magit-mode', so one line
  ;; covers them all. The repo list is a tabulated-list, so it is separate.
  ;; Commit-message buffers (git-commit-mode) are NOT magit-mode: they stay
  ;; in normal state, because there you are just editing text.
  (evil-set-initial-state 'magit-mode 'emacs)
  (evil-set-initial-state 'magit-repolist-mode 'emacs))

;; Emacs state has no SPC leader, so dired and magit share a small one of
;; their own (SPC, then one key). Buffer cycling (C-; C-' C-,) and C-c f /
;; C-c g are global, so they already work in those buffers too.
(defun suhas/kill-buffer-here ()
  "Kill this buffer. In magit buffers, also restore the window layout
from before magit opened (same as `q', but the buffer is killed)."
  (interactive)
  (if (derived-mode-p 'magit-mode)
      (magit-mode-bury-buffer t)
    (kill-current-buffer)))

(define-prefix-command 'suhas/emacs-leader-map)
(define-key suhas/emacs-leader-map (kbd "SPC") #'consult-buffer)
(define-key suhas/emacs-leader-map (kbd "k") #'suhas/kill-buffer-here)
(define-key suhas/emacs-leader-map (kbd "r") #'consult-recent-file)
(define-key suhas/emacs-leader-map (kbd "f") #'suhas/find-file-everywhere)
(define-key suhas/emacs-leader-map (kbd "g") #'suhas/grep-project)
(define-key suhas/emacs-leader-map (kbd "G") #'suhas/grep-everywhere)
(define-key suhas/emacs-leader-map (kbd "p") #'suhas/project-switch)

;; Why a minor mode and not `define-key' on magit-mode-map / dired-mode-map:
;; several magit modes (diff, revision, log, process...) bind SPC in their OWN
;; keymap, and a major-mode map beats its parent's. Minor-mode maps beat every
;; major-mode map, so this one works in all of them with no per-mode list.
(define-minor-mode suhas/emacs-leader-mode
  "SPC opens `suhas/emacs-leader-map' (leader for Emacs-state buffers)."
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "SPC") #'suhas/emacs-leader-map)
            map))

;; In magit, SPC used to scroll the diff down; that is now `C-v' / `M-v'
;; (DEL still scrolls back up). Hooks on `magit-mode-hook' also cover every
;; derived mode (status, log, diff, revision, process, refs, stash...).
(dolist (hook '(dired-mode-hook magit-mode-hook magit-repolist-mode-hook))
  (add-hook hook #'suhas/emacs-leader-mode))

;;; ============================================================
;;; WHICH-KEY — shows what can follow SPC (or any prefix) after a pause
;;; ============================================================

;; Built in since Emacs 30 (installed from GNU ELPA on 29). With ~70
;; leader bindings, this is how you stop having to remember them.
(use-package which-key
  :init
  (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.5))

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

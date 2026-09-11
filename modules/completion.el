;;; completion.el --- Vertico, Marginalia, Consult, Corfu ... -*- lexical-binding: t; -*-
;;; Fast fuzzy completion in minibuffer (Vertico) and in-buffer (Corfu).
;;;
;;; How they work together:
;;; - vertico: Vertical list UI for minibuffer completion (file, buffer, command selection)
;;; - marginalia: Adds annotations (file size, command docstring, etc)
;;; - consult: Enhanced commands (buffer switch with preview, grep with preview, etc)
;;; - orderless: Fuzzy matching — "py find" matches "python-find-file"
;;; - corfu: In-buffer completion popup (code suggestions, LSP completions)
;;;
;;; External binaries required for full functionality:
;;; - fd    -> powers consult-fd (project-wide fuzzy file search)
;;; - ripgrep (rg) -> powers consult-ripgrep (project-wide fuzzy content search)
;;;   Arch:    sudo pacman -S fd ripgrep
;;;   Windows: scoop install fd ripgrep   (or winget install sharkdp.fd BurntSushi.ripgrep.MSVC)

;;; ============================================================
;;; VERTICO — Vertical completion list
;;; ============================================================

;; Replaces Emacs' default horizontal completion menu.
;; Works for any minibuffer task: find-file, switch-buffer, M-x, etc.

(use-package vertico
  :init
  (vertico-mode 1)
  :custom
  (vertico-count 12)        ; Show 12 candidates at a time
  (vertico-resize nil)      ; Shrink list if fewer candidates
  (vertico-cycle t)         ; Wrap around when you reach the end
  (vertico-reverse-mode t))

;; vertico-directory: Makes file navigation smooth with DEL to go back.
(use-package vertico-directory
  :after vertico
  :ensure nil              ; Built-in, no separate install
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL"  . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;;; ============================================================
;;; ORDERLESS — Fuzzy matching engine
;;; ============================================================

;; By default, Emacs requires exact substring matches.
;; Orderless lets you type space-separated words in any order,
;; and orderless-flex lets you type out-of-order fuzzy fragments
;; (e.g. "cvf" matches "completion-vertico-file").

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  ;; IMPORTANT: previously files only used partial-completion, which meant
  ;; fuzzy matching (including flex) was SILENTLY DISABLED for any file-category
  ;; completion — this includes consult-fd/consult-find results, since those
  ;; candidates are tagged with the 'file completion category.
  ;; Fix: let orderless run first for fuzzy matching, keep partial-completion
  ;; as a fallback so path-segment navigation (e.g. "us/lo/bin" -> /usr/local/bin)
  ;; still works inside raw find-file.
  (completion-category-overrides
   '((file (styles orderless partial-completion))))
  (orderless-matching-styles
   '(orderless-literal
     orderless-regexp
     orderless-flex        ; true fuzzy: out-of-order subsequence matching
     orderless-initialism)))

;;; ============================================================
;;; MARGINALIA — Annotations in completion menu
;;; ============================================================

;; Shows helpful context next to each candidate:
;; - M-x: command's docstring
;; - find-file: file size and modification date
;; - switch-buffer: buffer's major mode
;; All without slowing down the UI.

(use-package marginalia
  :init
  (marginalia-mode 1))

;;; ============================================================
;;; RECENTF
;;; ============================================================
(use-package recentf
  :ensure nil
  :init
  (recentf-mode 1)
  :custom
  (recentf-exclude '("/tmp/" "/ssh:" "\\.elc\\'" "\\.git/" "/node_modules/")))

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))
;;; ============================================================
;;; CONSULT — Enhanced search and navigation commands
;;; ============================================================

;; Consult replaces built-in commands with preview-aware versions:
;; - consult-buffer:    Switch buffer with live preview
;; - consult-line:      Search current buffer (like Ctrl+F)
;; - consult-ripgrep:   Fuzzy content search across the whole project
;; - consult-fd:        Fuzzy file NAME search across the whole project
;;                       (no more navigating into subfolders manually)
;; - consult-imenu:     Jump to function/class in current file

(use-package consult
  :after vertico
  :bind
  ;; Use consult for these standard commands
  ([remap switch-to-buffer] . consult-buffer)
  ([remap goto-line] . consult-goto-line)
  ([remap imenu] . consult-imenu)

  :custom
  ;; Preview candidates as you navigate, but debounced.
  ;; 'any with no debounce re-renders (opens/highlights) a file on every
  ;; single cursor move through the candidate list — on a big consult-fd
  ;; or consult-ripgrep result set this causes visible lag/flicker.
  ;; Waiting 0.3s for you to stop moving before previewing fixes that.
  (consult-preview-key '(:debounce 0.3 any))
  ;; Tell consult to use project.el for finding project root, so
  ;; consult-fd / consult-ripgrep search from the project root even
  ;; when you invoke them from a buffer in a subdirectory.
  (consult-project-function
   (lambda (_)
     (when-let (project (project-current))
       (project-root project))))

  :config
  ;; Hide noisy internal buffers from `consult-buffer'.
  ;; This does NOT kill or disable them.
  ;; *scratch* remains visible.
  (dolist (regexp '("\\`\\*Messages\\*\\'"
                    "\\`\\*Warnings\\*\\'"
                    "\\`\\*EGLOT.*\\*\\'"
                    "\\`\\*eglot.*\\*\\'"
                    "\\`\\*Flymake.*\\*\\'"
                    "\\`\\*Echo Area.*\\*\\'"
                    "\\`\\*Compile-Log*\\*\\'"
                    "\\` \\*Minibuf-.*\\*\\'"))
    (add-to-list 'consult-buffer-filter regexp)))


;; Give Windows pipes more breathing room (default is small, causes exactly this error)
(when (eq system-type 'windows-nt)
  (setq w32-pipe-buffer-size (* 64 1024)))

;; Slow down how eagerly consult restarts the fd process while you type,
;; so rapid typing/backspacing doesn't pile up overlapping subprocesses
(setq consult-async-input-debounce 0.4   ; wait longer after keystroke before restarting search
      consult-async-input-throttle 0.6)  ; minimum time between restarts

;; Buffer isolation with perspective package
(with-eval-after-load 'consult
  (consult-customize consult-source-recent-file :hidden t :default nil)
  (with-eval-after-load 'perspective
    (consult-customize consult-source-buffer :hidden t :default nil)

    ;; Define our own version outright instead of patching perspective's
    ;; internal plist — avoids racing perspective.el's own consult hook.
    (defvar persp-consult-source
      (list :name     "Perspective"
            :narrow   ?s
            :category 'buffer
            :state    #'consult--buffer-state
            :history  'buffer-name-history
            :default  t
            :items
            (lambda ()
              (consult--buffer-query
               :sort 'visibility
               :predicate (lambda (buf)
                            (and (suhas/persp-buffer-p buf)
                                 (not (suhas/terminal-buffer-p buf))))
               :as #'buffer-name))))

    (add-to-list 'consult-buffer-sources 'persp-consult-source)

    (defvar consult-source-persp-terminal
      `( :name     "Terminal"
         :narrow   ?t
         :hidden   t
         :default  nil
         :category buffer
         :face     consult-buffer
         :state    ,#'consult--buffer-state
         :items
         ,(lambda () (mapcar #'buffer-name (suhas/persp-terminal-buffers))))
      "Perspective-scoped terminal buffers, hidden until narrowed with `t'.")

    (add-to-list 'consult-buffer-sources 'consult-source-persp-terminal t)))

;;; ============================================================
;;; PROJECT-SCOPED FIND / GREP
;;; ============================================================

;; C-c f / C-c g already search from consult-project-function's root
;; when called with a prefix arg (C-u C-c f). These two give the
;; project-rooted behavior unconditionally, no prefix needed.

(defun suhas/project-root ()
  "Return the current project root, or `default-directory'."
  (if-let ((project (project-current nil)))
      (project-root project)
    default-directory))

(defun suhas/consult-project-find ()
  "Fuzzy-find files from the current project root."
  (interactive)
  (consult-fd (suhas/project-root)))

(defun suhas/consult-project-ripgrep ()
  "Search file contents from the current project root."
  (interactive)
  (consult-ripgrep (suhas/project-root)))


;;; ============================================================
;;; CORFU — In-buffer code completion popup
;;; ============================================================

;; Vertico/Consult handle minibuffer completion (commands, files, buffers).
;; Corfu handles in-buffer completion (code suggestions, LSP completions).
;; When you're typing code and eglot (LSP) suggests completions,
;; Corfu shows them in a small popup next to your cursor.

(use-package corfu
  :init
  (global-corfu-mode 1)
  :custom
  (corfu-auto t)           ; Show popup automatically while typing
  (corfu-auto-delay 0.2)   ; Wait 200ms after you stop typing
  (corfu-auto-prefix 2)    ; Only show popup after 2+ characters
  (corfu-cycle t)          ; Tab wraps around candidate list
  (corfu-quit-no-match t)  ; Hide popup if no matches
  :bind
  (:map corfu-map
        ("<return>" . nil)
        ("RET" . nil)))
;; NOTE: if you notice popup lag specifically while Eglot is connected to a
;; slower LSP server (e.g. jdtls for Java), bump corfu-auto-prefix to 3 —
;; every keystroke past the prefix count sends a completion request to the
;; server. Don't change this preemptively; only if you actually feel it.


;;; ============================================================
;;; CAPE — Extra completion sources
;;; ============================================================

;; Corfu shows LSP completions by default.
;; Cape adds other sources: file paths, dictionary words, dabbrev (text in buffer).
;; These all feed into Corfu's popup.

(use-package cape
  :after corfu
  :custom
  ;; cape-dabbrev scans the whole buffer (and other buffers) on every
  ;; keystroke after corfu-auto-delay. On large buffers this causes
  ;; stutter for very short prefixes. Skip suggesting completions until
  ;; you've typed at least 4 characters.
  (cape-dabbrev-min-length 4)
  :config
  ;; Add file completion (M-: /path/to/fi<TAB> suggests files)
  (add-to-list 'completion-at-point-functions #'cape-file t)
  ;; Add dabbrev (completes words that appear elsewhere in the buffer)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev t))


;;; ============================================================
;;; SPEEDBAR -- inbuilt filetree
;;; ============================================================

(defun suhas/speedbar-visit-in-place (orig-fn &rest args)
  "Make speedbar visit files in the last real edit window, not its own dedicated pane."
  (let ((target (or (get-mru-window nil nil t) (selected-window)))
        (sb-buf (current-buffer)))
    (select-window target)
    (with-current-buffer sb-buf
      (apply orig-fn args))))

(advice-add 'speedbar-edit-line :around #'suhas/speedbar-visit-in-place)

(use-package speedbar
  :ensure nil
  :commands (speedbar)
  :config
  (setq speedbar-prefer-window t)
  (setq speedbar-use-images nil)

  ;; Show files speedbar would otherwise hide (yaml, etc. with no tag support)
  (setq speedbar-show-unknown-files t)
  ;; Stop hiding dotfiles/dot-directories
  (setq speedbar-directory-unshown-regexp "\\`\\'")

  ;; Fix: mouse-1 was being translated to mouse-2 (follow-link), which
  ;; fell through to Evil's global mouse-2 = paste-primary-selection binding.
  (add-hook 'speedbar-mode-hook
            (lambda () (setq-local mouse-1-click-follows-link nil)))

  ;; Fix: force files to open in the real edit window instead of
  ;; splitting, since speedbar's own dedicated window refuses them.
  (defun suhas/speedbar-visit-in-place (orig-fn &rest args)
    (let ((target (or (get-mru-window nil nil t) (selected-window)))
          (sb-buf (current-buffer)))
      (select-window target)
      (with-current-buffer sb-buf
        (apply orig-fn args))))
  (advice-add 'speedbar-edit-line :around #'suhas/speedbar-visit-in-place)

  ;; Single keyboard-only toggle: open / jump in / jump back out.
  ;; (Bug was hardcoding "*SPEEDBAR*" — real buffer is internal;
  ;; `speedbar-buffer` is the variable that always points to it.)
  (defun suhas/toggle-speedbar-window-focus ()
    "Toggle focus between the speedbar window and the previous window."
    (interactive)
    (let ((sb-win (and (buffer-live-p speedbar-buffer)
                        (get-buffer-window speedbar-buffer))))
      (cond
       ((and sb-win (eq (selected-window) sb-win))
        (select-window (get-mru-window nil nil t)))
       (sb-win
        (select-window sb-win))
       (t
        (speedbar 1)
        (select-window (get-buffer-window speedbar-buffer))))))
  (global-set-key (kbd "C-x l") #'suhas/toggle-speedbar-window-focus))
;;; completion.el ends here

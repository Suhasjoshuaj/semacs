;;; completion.el --- Vertico, Marginalia, Consult, Corfu
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
       (project-root project)))))

;; Give Windows pipes more breathing room (default is small, causes exactly this error)
(when (eq system-type 'windows-nt)
  (setq w32-pipe-buffer-size (* 64 1024)))

;; Slow down how eagerly consult restarts the fd process while you type,
;; so rapid typing/backspacing doesn't pile up overlapping subprocesses
(setq consult-async-input-debounce 0.4   ; wait longer after keystroke before restarting search
      consult-async-input-throttle 0.6)  ; minimum time between restarts


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
  (corfu-quit-no-match t)) ; Hide popup if no matches
;; NOTE: if you notice popup lag specifically while Eglot is connected to a
;; slower LSP server (e.g. jdtls for Java), bump corfu-auto-prefix to 3 —
;; every keystroke past the prefix count sends a completion request to the
;; server. Don't change this preemptively; only if you actually feel it.

;; corfu-terminal: Makes corfu work in terminal Emacs (no GUI).
;; Without this, completion renders as garbage in TTY mode.
(use-package corfu-terminal
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

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
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;; Add dabbrev (completes words that appear elsewhere in the buffer)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;;; completion.el ends here

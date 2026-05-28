;;; completion.el --- Vertico, Marginalia, Consult, Corfu
;;; Fast fuzzy completion in minibuffer (Vertico) and in-buffer (Corfu).
;;;
;;; How they work together:
;;; - vertico: Vertical list UI for minibuffer completion (file, buffer, command selection)
;;; - marginalia: Adds annotations (file size, command docstring, etc)
;;; - consult: Enhanced commands (buffer switch with preview, grep with preview, etc)
;;; - orderless: Fuzzy matching — "py find" matches "python-find-file"
;;; - corfu: In-buffer completion popup (code suggestions, LSP completions)

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
  (vertico-cycle t))        ; Wrap around when you reach the end

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
;; Orderless lets you type space-separated words in any order.
;; Example: "py find" matches "python-find-file" or "find-python-mode".

(use-package orderless
  :custom
  ;; Use orderless for all completion, except files use partial-completion
  (completion-styles '(orderless basic))
  (completion-category-overrides
   '((file (styles partial-completion))))
  ;; How to match: literal substring, regex, or initialism (ff = find-file)
  (orderless-matching-styles
   '(orderless-literal
     orderless-regexp
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
;; - consult-buffer: Switch buffer with live preview
;; - consult-line: Search current buffer (like Ctrl+F)
;; - consult-grep: Grep project files with preview
;; - consult-find: Find file by name
;; - consult-imenu: Jump to function/class in current file

(use-package consult
  :after vertico
  :bind
  ;; Use consult for these standard commands
  ([remap switch-to-buffer] . consult-buffer)
  ([remap goto-line] . consult-goto-line)
  ([remap imenu] . consult-imenu)
  :custom
  ;; Preview candidates instantly as you navigate
  (consult-preview-key 'any)
  ;; Tell consult to use project.el for finding project root
  (consult-project-function
   (lambda (_)
     (when-let (project (project-current))
       (project-root project)))))

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
  :config
  ;; Add file completion (M-: /path/to/fi<TAB> suggests files)
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;; Add dabbrev (completes words that appear elsewhere in the buffer)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;;; completion.el ends here

;;; completion.el --- Vertico, Orderless, Marginalia, Consult
;;; The four packages that make finding anything instant.
;;;
;;; How they fit together:
;;; vertico   — the UI: shows candidates in a vertical list
;;; orderless — the engine: fuzzy/space-separated matching
;;; marginalia — the context: adds annotations next to candidates
;;; consult   — the commands: search, grep, find, switch, preview

;;; ============================================================
;;; SECTION 1: VERTICO — VERTICAL COMPLETION UI
;;; ============================================================

;; Replaces Emacs' default horizontal completion with a clean
;; vertical list. Works with any command that uses minibuffer
;; completion — find-file, switch-buffer, M-x, everything.

(use-package vertico
  :ensure t
  :init
  (vertico-mode 1)
  :custom
  (vertico-count 12)          ; Show 15 candidates at a time
  (vertico-resize nil)          ; Shrink list if fewer candidates
  (vertico-cycle t))          ; Wrap around at top/bottom

;; vertico-directory: makes file navigation feel like a file picker.
;; DEL deletes one path component, RET enters directories.
(use-package vertico-directory
  :after vertico
  :ensure nil                 ; Built into vertico, no separate install
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;;; ============================================================
;;; SECTION 2: ORDERLESS — FUZZY MATCHING ENGINE
;;; ============================================================

;; Orderless lets you type space-separated components in any order.
;; Example: "find py" matches "python-find-file", "find-python", etc.
;; This is what makes completion feel modern and fast.

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   '((file (styles partial-completion)))) ; Files still use path completion
  (orderless-matching-styles
   '(orderless-literal          ; Exact substring match
     orderless-regexp           ; Regex match
     orderless-initialism)))    ; "ff" matches "find-file"

;;; ============================================================
;;; SECTION 3: MARGINALIA — ANNOTATIONS
;;; ============================================================

;; Adds helpful context next to completion candidates.
;; M-x shows what the command does.
;; find-file shows file size and date.
;; switch-buffer shows the major mode.
;; All of this without slowing down the UI.

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

;;; ============================================================
;;; SECTION 4: CONSULT — POWERFUL SEARCH COMMANDS
;;; ============================================================

;; Consult provides enhanced versions of built-in commands.
;; The key ones you'll use daily:
;;   consult-line    → search in current buffer (SPC s s)
;;   consult-grep    → grep across project files (SPC s g)
;;   consult-find    → find file by name (SPC s f)
;;   consult-buffer  → switch buffer with preview (SPC b b)
;;   consult-imenu   → jump to function/class in file

(use-package consult
  :ensure t
  :after evil
  :config

  ;; Preview files as you navigate candidates.
  ;; Move through grep results and see the file open live.
  (setq consult-preview-key 'any)

  ;; Use consult for buffer switching — replaces switch-to-buffer.
  ;; You get a live preview of each buffer as you select it.
  (global-set-key [remap switch-to-buffer] #'consult-buffer)
  (global-set-key [remap goto-line]        #'consult-goto-line)
  (global-set-key [remap imenu]            #'consult-imenu)

  ;; Tell consult how to find project root.
  ;; We use project.el (built-in) — no extra package needed.
  (setq consult-project-function
        (lambda (_)
          (when-let (project (project-current))
            (project-root project)))))

;;; ===========================================================
;;; SECTION 5: CORFU — IN-BUFFER CODE COMPLETION POPUP
;;; ============================================================

  ;; Vertico handles minibuffer completion (commands, files, buffers).
  ;; Corfu handles in-buffer completion (code, words, LSP suggestions).
  ;; They're complementary — you need both.
  ;;
  ;; When eglot sends completion candidates from a language server,
  ;; corfu shows them in a small popup next to your cursor.

  (use-package corfu
    :ensure t
    :custom
    (corfu-auto t)              ; Show popup automatically while typing
    (corfu-auto-delay 0.2)      ; Wait 200ms before showing popup
    (corfu-auto-prefix 2)       ; Start after typing 2 characters
    (corfu-cycle t)             ; Wrap around candidate list
    (corfu-quit-no-match t)     ; Hide popup if no matches
    :init
    (global-corfu-mode 1))

  ;; corfu-terminal: makes corfu work in terminal Emacs too.
  ;; Without this, the popup renders as garbage in TTY mode.
  (use-package corfu-terminal
    :ensure t
    :after corfu
    :config
    (unless (display-graphic-p)
      (corfu-terminal-mode 1)))

  ;; cape: adds extra completion sources to corfu.
  ;; File paths, dictionary words, and more — on top of LSP.
  (use-package cape
    :ensure t
    :config
    (add-to-list 'completion-at-point-functions #'cape-file)
    (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;;; completion.el ends here

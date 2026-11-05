;;; completion.el --- Vertico, Marginalia, Consult, Corfu ... -*- lexical-binding: t; -*-
;;; Fast fuzzy completion in minibuffer (Vertico) and in-buffer (Corfu).
;;;
;;; How they work together:
;;; - vertico: Vertical list UI for minibuffer completion (file, buffer, command selection)
;;; - marginalia: Adds annotations (file size, command docstring, etc)
;;; - consult: Enhanced commands (buffer switch with preview, grep with preview, etc)
;;; - orderless: space-separated words in any order — "py find" matches "python-find-file"
;;; - corfu: In-buffer completion popup (code suggestions, LSP completions)
;;;
;;; Projects, find-file-anywhere, grep, recent files and speedbar live in
;;; search.el. This file is only the completion UI + the consult tuning.
;;;
;;; External binaries (used from search.el):
;;;   Arch:    sudo pacman -S fd ripgrep
;;;   Debian:  sudo apt install fd-find ripgrep     (binary is `fdfind'; handled)
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
  (vertico-resize nil)      ; Fixed-height list (no jumping as you type)
  (vertico-cycle t)         ; Wrap around when you reach the end
  ;; List above the prompt (bottom-anchored). This DOES work from :custom:
  ;; use-package applies it through Custom, and the mode is autoloaded.
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
  ;; Emacs ships per-category defaults (buffer, project-file, xref-location,
  ;; info-menu...) that use plain `substring' matching and take PRIORITY
  ;; over `completion-styles'. So Orderless was silently NOT used for
  ;; `SPC SPC' buffers, `SPC p f' project files or xref results:
  ;; "foo bar" (two words) found nothing there. nil = everything uses the
  ;; styles below, so every list behaves the same way.
  (completion-category-defaults nil)
  (completion-category-overrides
   '(;; find-file / recent files: orderless first, partial-completion as
     ;; fallback so "us/lo/bin" -> /usr/local/bin still works.
     (file (styles orderless partial-completion))
     ;; project files get true fuzzy matching (see style below).
     (project-file (styles suhas-fuzzy))))
  ;; Predictable everywhere else: words in any order, as literals or
  ;; regexps, or initials ("cvf" -> completion-vertico-file only when the
  ;; words start with c, v, f). `orderless-flex' is deliberately NOT
  ;; global: it matches almost anything and turns M-x / buffer lists into
  ;; noise. You can still ask for it on demand by ending a word with ~
  ;; ("cvf~" = flex).
  (orderless-matching-styles
   '(orderless-literal orderless-regexp orderless-initialism))
  :config
  ;; Fuzzy style used ONLY for the project file list (SPC p f), where the
  ;; candidates are a static list of relative paths: "srcmain" finds
  ;; "src/main.c". (Not for consult-fd/ripgrep: those hand your input to
  ;; fd/rg, and Orderless only filters what you type AFTER a `#'.)
  (orderless-define-completion-style suhas-fuzzy
    (orderless-matching-styles
     '(orderless-literal orderless-regexp orderless-flex))))

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

;; (recentf, savehist and save-place moved to search.el.)

;;; ============================================================
;;; CONSULT — Enhanced search and navigation commands
;;; ============================================================

;; Consult replaces built-in commands with preview-aware versions:
;; - consult-buffer:    Switch buffer with live preview
;; - consult-line:      Search current buffer (like Ctrl+F)
;; - consult-ripgrep:   Content search (project, or ALL your repos)
;; - consult-fd:        File NAME search across ALL your repos
;; - consult-xref:      Shows definitions/references with live preview
;; - consult-imenu:     Jump to function/class in current file
;; The project/repo wrappers are in search.el.

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
  ;; (Removed the `consult-project-function' override: Consult's default
  ;; already uses project.el, and the override additionally dropped the
  ;; "prompt for a project" behavior.)

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
                    "\\`\\*Compile-Log\\*\\'"
                    "\\` \\*Minibuf-.*\\*\\'"))
    (add-to-list 'consult-buffer-filter regexp))

  ;; Definitions / references: one Vertico list WITH live preview, instead
  ;; of an *xref* buffer. This also fixes "xref can't open the target":
  ;; in the *xref* buffer, evil's RET (evil-ret) shadowed xref's own RET.
  ;; M-. / M-? / project-find-regexp / eglot references all go through
  ;; these two variables.
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Ripgrep: also search dotfiles (.github, .env, ...) but never .git.
  (setq consult-ripgrep-args
        (append (if (listp consult-ripgrep-args)
                    consult-ripgrep-args
                  (list consult-ripgrep-args))
                (list "--hidden --glob=!.git/")))

  ;; fd (consult-fd): file NAMES only, files only, dotfiles included.
  ;; Consult's default passes --full-path, and fd then matches your text
  ;; against the ABSOLUTE path: typing "cpp" inside ~/cpp (or your user
  ;; name, or the project folder's name) matched EVERY file.
  (setq consult-fd-args
        '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
          "--color=never --hidden --type f --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv")))


;; Give Windows pipes more breathing room (default is small, causes exactly this error)
(when (eq system-type 'windows-nt)
  (setq w32-pipe-buffer-size (* 64 1024)))

;; Windows only: slow down how eagerly consult restarts fd/rg while you
;; type, so rapid typing doesn't pile up overlapping subprocesses. On
;; Linux the defaults (0.2s / 0.5s) feel noticeably snappier.
(when (eq system-type 'windows-nt)
  (setq consult-async-input-debounce 0.4
        consult-async-input-throttle 0.6))

;; Buffer isolation with perspective package
(with-eval-after-load 'consult
  ;; Recent files are no longer hidden: SPC SPC now also finds files you
  ;; opened before (that is how you reopen things without C-x C-f).
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


;;; completion.el ends here

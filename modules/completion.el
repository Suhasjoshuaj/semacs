;;; completion.el --- Vertico, Orderless, Marginalia, Consult, Corfu, Cape  -*- lexical-binding: t; -*-
;;;
;;;   vertico     vertical list for every minibuffer prompt
;;;   orderless   space-separated words in any order
;;;   marginalia  annotations next to candidates
;;;   consult     search/navigation commands with live preview
;;;   corfu       in-buffer completion popup (LSP, words, paths)
;;;   cape        extra completion sources for corfu
;;;
;;; None of them load during startup: the UI modes switch on at the first
;;; keypress (`suhas/first-input-hook'), consult loads on its first command.
;;; Projects, find-anywhere and grep wrappers live in search.el.

;;; ============================================================
;;; VERTICO
;;; ============================================================

(use-package vertico
  :custom
  (vertico-count 12)
  (vertico-resize nil)      ; fixed height, no jumping while typing
  (vertico-cycle t)
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ;; DEL at a directory boundary goes up one level.
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(defun suhas/completion-first-input ()
  "Switch the completion UI on (first keypress).
Each piece is optional: a package that is not installed yet (first start
without network) is skipped and the built-in completion keeps working."
  (require 'orderless nil t)
  (dolist (mode '(vertico-mode
                  vertico-reverse-mode   ; list above the prompt
                  marginalia-mode
                  global-corfu-mode
                  corfu-popupinfo-mode))
    (when (fboundp mode)
      (funcall mode 1))))
(add-hook 'suhas/first-input-hook #'suhas/completion-first-input)

;;; ============================================================
;;; ORDERLESS
;;; ============================================================

(use-package orderless
  :custom
  ;; Words as literals, regexps or initials. Flex is deliberately not
  ;; global (it turns M-x into noise); end a word with ~ to ask for it.
  (orderless-matching-styles
   '(orderless-literal orderless-regexp orderless-initialism))
  :config
  ;; True fuzzy, for project files only ("srcmain" finds src/main.c).
  (orderless-define-completion-style suhas-fuzzy
    (orderless-matching-styles
     '(orderless-literal orderless-regexp orderless-flex)))
  (setq completion-styles '(orderless basic)
        ;; Emacs ships per-category defaults (buffer, project-file, ...)
        ;; that take priority over `completion-styles'. nil = every list
        ;; uses the styles here and behaves the same way.
        completion-category-defaults nil
        completion-category-overrides
        '(;; partial-completion as fallback: "us/lo/bin" -> /usr/local/bin
          (file (styles orderless partial-completion))
          (project-file (styles suhas-fuzzy)))))

;;; ============================================================
;;; MARGINALIA
;;; ============================================================

(use-package marginalia)

;;; ============================================================
;;; CONSULT
;;; ============================================================

;; Definitions / references: one list with live preview instead of an
;; *xref* buffer. (`consult-xref' is autoloaded; this does not load consult.)
(setq xref-show-xrefs-function #'consult-xref
      xref-show-definitions-function #'consult-xref)

(use-package consult
  :bind
  ([remap switch-to-buffer] . consult-buffer)
  ([remap goto-line] . consult-goto-line)
  ([remap imenu] . consult-imenu)
  :custom
  ;; Debounced preview: without it every cursor move through a big result
  ;; list opens a file.
  (consult-preview-key '(:debounce 0.3 any))
  ;; fd: file NAMES only, dotfiles included. (Consult's default matches the
  ;; absolute path, so "cpp" inside ~/cpp matched every file.)
  (consult-fd-args
   '((if (executable-find "fdfind" 'remote) "fdfind" "fd")
     "--color=never --hidden --type f --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv"))
  :config
  ;; ripgrep: dotfiles too (.github, .env), never .git.
  (when (and (stringp consult-ripgrep-args)
             (not (string-search "--hidden" consult-ripgrep-args)))
    (setq consult-ripgrep-args
          (concat consult-ripgrep-args " --hidden --glob=!.git/")))

  (dolist (regexp '("\\`\\*Messages\\*\\'"
                    "\\`\\*Warnings\\*\\'"
                    "\\`\\*EGLOT.*\\*\\'"
                    "\\`\\*eglot.*\\*\\'"
                    "\\`\\*Flymake.*\\*\\'"
                    "\\`\\*Compile-Log\\*\\'"))
    (add-to-list 'consult-buffer-filter regexp))

  ;; SPC SPC shows: this workspace's buffers, then recent files.
  ;; Narrow with:  t = this workspace's terminals   b = ALL buffers.
  (defvar suhas/consult-source-workspace
    `( :name     "Workspace"
       :narrow   ?w
       :category buffer
       :face     consult-buffer
       :history  buffer-name-history
       :state    ,#'consult--buffer-state
       :default  t
       :items
       ,(lambda ()
          (consult--buffer-query
           :sort 'visibility
           :as #'buffer-name
           :predicate (lambda (buf)
                        (and (suhas/persp-buffer-p buf)
                             (not (suhas/terminal-buffer-p buf)))))))
    "Buffers of the current workspace, without its terminals.")

  (defvar suhas/consult-source-terminal
    `( :name     "Terminal"
       :narrow   ?t
       :hidden   t
       :category buffer
       :face     consult-buffer
       :history  buffer-name-history
       :state    ,#'consult--buffer-state
       :items
       ,(lambda ()
          (consult--buffer-query
           :sort 'visibility
           :as #'buffer-name
           :predicate (lambda (buf)
                        (and (suhas/persp-buffer-p buf)
                             (suhas/terminal-buffer-p buf))))))
    "Terminals of the current workspace; shown after narrowing with t.")

  (consult-customize consult-source-buffer :hidden t :default nil)
  (setq consult-buffer-sources
        '(suhas/consult-source-workspace
          consult-source-recent-file
          suhas/consult-source-terminal
          consult-source-buffer)))

;;; ============================================================
;;; CORFU — in-buffer completion popup
;;; ============================================================

(use-package corfu
  :init
  ;; Not in terminals: every key there belongs to the shell.
  (setq global-corfu-modes '((not ghostel-mode) t))
  ;; In the minibuffer, but not on top of Vertico and not in Evil's `:'
  ;; prompt (its completion function misbehaves under an auto popup).
  (setq global-corfu-minibuffer
        (lambda ()
          (not (or (bound-and-true-p vertico--input)
                   (bound-and-true-p evil-ex-current-buffer)))))
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  (corfu-quit-no-match t)
  ;; Documentation beside the popup once you rest on a candidate.
  (corfu-popupinfo-delay '(1.0 . 0.3))
  :bind
  ;; RET always means newline; TAB accepts.
  (:map corfu-map
        ("<return>" . nil)
        ("RET" . nil)))
;; If the popup lags with a slow server (jdtls), raise `corfu-auto-prefix'
;; to 3 in local.el: every key past the prefix is a completion request.

;;; ============================================================
;;; CAPE — extra sources
;;; ============================================================

;; File paths and words from open buffers, after whatever the mode
;; itself offers (LSP). Both are autoloaded: cape loads on first use.
(use-package cape
  :custom
  ;; Scanning buffers for 2-letter prefixes stutters on big files.
  (cape-dabbrev-min-length 4))
(add-hook 'completion-at-point-functions #'cape-file t)
(add-hook 'completion-at-point-functions #'cape-dabbrev t)

;; Evil's `:' completion reads one position before point and signals
;; args-out-of-range on an empty line. No completions is the right answer.
(defun suhas/evil-ex-completion-safe (fn &rest args)
  "Call FN with ARGS; an `args-out-of-range' just means no completions."
  (condition-case nil (apply fn args)
    (args-out-of-range nil)))

(with-eval-after-load 'evil-ex
  (advice-add 'evil-ex-command-completion-at-point :around
              #'suhas/evil-ex-completion-safe))

;;; completion.el ends here

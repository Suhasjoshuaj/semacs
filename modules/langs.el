;;; langs.el --- Tree-sitter major modes and per-language settings  -*- lexical-binding: t; -*-
;;;
;;; Language servers are wired up in lsp.el, formatters in formatter.el.
;;;
;;; TREE-SITTER, AND WHY IT IS HANDLED CAREFULLY
;;;
;;; A tree-sitter mode needs a compiled grammar (libtree-sitter-LANG.so /
;;; .dll). Two things go wrong when grammars are fetched carelessly:
;;;
;;;   1. ABI: every grammar is generated for an ABI version, and the
;;;      tree-sitter library inside your Emacs only loads a range of them
;;;      (M-x suhas/doctor prints it). "Latest master" of a grammar is often
;;;      newer than a distro's library can load.
;;;   2. A grammar newer than the major mode expects renames syntax nodes,
;;;      and highlighting or indentation silently breaks.
;;;
;;; So this config never builds "latest". `suhas/treesit-install' builds the
;;; exact revisions Emacs 31 pins for its own modes (they pick an older
;;; revision themselves when the library is old), then LOADS each grammar to
;;; prove it works; one that does not load is deleted again. And a
;;; tree-sitter mode is only switched on when its grammar file is present,
;;; so a missing or rejected grammar leaves you with the classic mode, never
;;; with a broken buffer.
;;;
;;;   M-x suhas/treesit-install   (SPC c g)  build what is missing; needs git + cc
;;;   M-x suhas/doctor            (SPC c h)  per-grammar status and ABI

;;; ============================================================
;;; TREE-SITTER
;;; ============================================================

(defconst suhas/treesit-directory
  (expand-file-name "tree-sitter/" user-emacs-directory)
  "Where this config's grammars are built (Emacs's standard location).")

(defun suhas/--treesit-grammar-file (lang)
  "The installed grammar library for LANG, or nil.
A file check only: nothing is loaded, so it costs nothing at startup."
  (seq-some (lambda (dir)
              (seq-some (lambda (suffix)
                          (let ((file (expand-file-name
                                       (format "libtree-sitter-%s%s" lang suffix) dir)))
                            (and (not (string-empty-p suffix))
                                 (file-exists-p file)
                                 file)))
                        dynamic-library-suffixes))
            (cons suhas/treesit-directory treesit-extra-load-path)))

(defun suhas/treesit-enable ()
  "Switch on each mode of `suhas/treesit-modes' whose grammars are installed."
  (let (enabled)
    (pcase-dolist (`(,mode . ,langs) suhas/treesit-modes)
      (let ((remap (rassq mode treesit-major-mode-remap-alist)))
        (if (seq-every-p #'suhas/--treesit-grammar-file langs)
            (progn (push mode enabled)
                   (when remap (add-to-list 'major-mode-remap-alist remap)))
          (setq major-mode-remap-alist (delete remap major-mode-remap-alist)))))
    (setq treesit-enabled-modes (nreverse enabled))))

(suhas/treesit-enable)

(defun suhas/treesit-status ()
  "List of (LANG STATE DETAIL) for every grammar in `suhas/treesit-modes'.
STATE is `ok' (DETAIL = its ABI version), `missing', or `broken' (DETAIL =
why it does not load, e.g. an ABI mismatch)."
  (require 'treesit)
  (mapcar
   (lambda (lang)
     (pcase-let ((`(,available . ,why) (treesit-language-available-p lang t)))
       (cond (available (list lang 'ok (treesit-language-abi-version lang)))
             ((suhas/--treesit-grammar-file lang) (list lang 'broken why))
             (t (list lang 'missing nil)))))
   (delete-dups (mapcan (lambda (entry) (copy-sequence (cdr entry)))
                        suhas/treesit-modes))))

(defvar warning-minimum-level)

(defun suhas/treesit-install (&optional rebuild)
  "Build the grammars `suhas/treesit-modes' needs, at Emacs's pinned revisions.
Each one is loaded afterwards; a grammar the tree-sitter library rejects
\(ABI mismatch) is deleted, so its language keeps the classic mode.
With prefix argument REBUILD, rebuild the ones already installed too.
Needs git and a C/C++ compiler on PATH."
  (interactive "P")
  (require 'treesit)
  ;; Loading a mode's library registers its pinned grammar recipe.
  (dolist (entry suhas/treesit-modes)
    (ignore-errors (autoload-do-load (symbol-function (car entry)) (car entry))))
  (let (built failed)
    (pcase-dolist (`(,lang ,state ,_) (suhas/treesit-status))
      (when (or rebuild (not (eq state 'ok)))
        (cond
         ((not (assq lang treesit-language-source-alist))
          (push (format "%s: Emacs has no recipe for it" lang) failed))
         (t
          (message "Building tree-sitter grammar `%s'..." lang)
          (let ((warning-minimum-level :emergency)) ; reported below instead
            (treesit-install-language-grammar lang suhas/treesit-directory))
          (pcase-let ((`(,available . ,why) (treesit-language-available-p lang t)))
            (if available
                (push lang built)
              (when-let* ((file (suhas/--treesit-grammar-file lang)))
                (delete-file file))
              (push (format "%s: %s" lang (or why "build failed (git and cc on PATH?)"))
                    failed)))))))
    (suhas/treesit-enable)
    (message "Tree-sitter (library loads ABI %d-%d): %d built%s%s"
             (treesit-library-abi-version t) (treesit-library-abi-version)
             (length built)
             (if built (format " (%s)" (mapconcat #'symbol-name (nreverse built) " ")) "")
             (if failed
                 (format "; NOT usable, classic mode stays: %s"
                         (string-join (nreverse failed) "; "))
               ""))))

(defun suhas/treesit-hint ()
  "Say why a file opened in fundamental-mode when its grammar is missing.
Go, Rust, TypeScript, YAML, TOML and Dockerfile have no classic mode in
Emacs, only a tree-sitter one."
  (when (and buffer-file-name (eq major-mode 'fundamental-mode))
    (let ((mode (assoc-default buffer-file-name auto-mode-alist #'string-match-p)))
      (when (and mode (symbolp mode)
                 (string-suffix-p "-ts-mode-maybe" (symbol-name mode)))
        (message "No tree-sitter grammar for this file type yet: M-x suhas/treesit-install")))))
(add-hook 'find-file-hook #'suhas/treesit-hint)

;;; ============================================================
;;; PER-LANGUAGE SETTINGS
;;; ============================================================
;; Plain `setq's of options: nothing here loads a mode.

(setq python-indent-offset 4
      js-indent-level 2
      typescript-ts-mode-indent-offset 2
      css-indent-offset 2
      c-ts-mode-indent-offset 4
      c-basic-offset 4
      java-ts-mode-indent-offset 4
      ;; Go indents with real tabs; show them 4 wide like everything else.
      go-ts-mode-indent-offset 4)

(use-package markdown-mode
  :mode (("\\.md\\'" . markdown-mode)
         ("README\\'" . markdown-mode)))

(defun suhas/java-style ()
  "Java: spaces, and trailing whitespace trimmed on save."
  (setq-local indent-tabs-mode nil)
  (when (derived-mode-p 'java-mode)   ; the classic (CC Mode) variant
    (c-set-style "java"))
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t))
(add-hook 'java-mode-hook #'suhas/java-style)
(add-hook 'java-ts-mode-hook #'suhas/java-style)

;;; langs.el ends here

;;; compile.el --- Compile command setup  ... -*- lexical-binding: t; -*-

(use-package compile
  :ensure nil
  :custom
  (compilation-scroll-output nil)
  (compilation-auto-jump-to-first-error t)
  ;; Save modified buffers before compiling without asking each time.
  (compilation-ask-about-save nil))

;; SPC m b -- ONE command that builds/runs the file you are looking at,
;; chosen by language. (It replaces five separate per-language functions
;; that were never bound and built broken paths.) Anything language- or
;; project-specific belongs in `compile' (SPC m c) with a per-project
;; `compile-command' in .dir-locals.el.

(defun suhas/--run-command (file)
  "Shell command to build/run FILE (bare name) for this mode, or nil."
  (let* ((q (shell-quote-argument file))
         (base (shell-quote-argument (file-name-sans-extension file)))
         (make-p (and suhas/c-run-with-makefile (file-exists-p "Makefile"))))
    (cond
     ((derived-mode-p 'c++-mode)
      (if make-p
          (format "make src=%s" q)
        (format "g++ -Wall -g -O2 -std=c++17 %s -o %s && ./%s" q base base)))
     ((derived-mode-p 'c-mode)
      (if make-p
          (format "make src=%s" q)
        (format "gcc -Wall -g -O2 %s -o %s && ./%s" q base base)))
     ((derived-mode-p 'rust-mode) "cargo run")
     ((derived-mode-p 'go-mode) (format "go run %s" q))
     ((derived-mode-p 'python-mode) (format "%s %s" suhas/python-command q))
     ((derived-mode-p 'js-mode) (format "node %s" q)))))

(defun suhas/run-current-file ()
  "Build and/or run the current file (SPC m b), by major mode.
Runs in the file's own directory, output in the *compilation* buffer
\(then SPC m n / SPC m p walk the errors)."
  (interactive)
  (unless buffer-file-name
    (user-error "This buffer is not visiting a file"))
  (let* ((default-directory (file-name-directory buffer-file-name))
         (cmd (suhas/--run-command (file-name-nondirectory buffer-file-name))))
    (unless cmd
      (user-error "No run command for %s; use SPC m c (compile)" major-mode))
    (compile cmd)))

;;; compile.el ends here

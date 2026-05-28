;;; compile.el --- Compile command setup

(use-package compile
  :ensure nil
  :custom
  (compilation-scroll-output nil)
  (compilation-auto-jump-to-first-error t))

(defun suhas/compile-c ()
  "Compile current C file."
  (interactive)
  (let ((file (file-name-sans-extension (buffer-file-name)))
        (flags "-Wall -g -O2"))
    (compile (format "gcc %s '%s.c' -o '%s' && './%s'" flags file file file))))

(defun suhas/compile-cpp ()
  "Compile current C++ file."
  (interactive)
  (let ((file (file-name-sans-extension (buffer-file-name)))
        (flags "-Wall -g -O2 -std=c++17"))
    (compile (format "g++ %s '%s.cpp' -o '%s' && './%s'" flags file file file))))

(defun suhas/compile-rust ()
  "Compile current Rust project."
  (interactive)
  (compile "cargo build"))

(defun suhas/run-python ()
  "Run current Python file."
  (interactive)
  (compile (format "python '%s'" (buffer-file-name))))

(defun suhas/run-js ()
  "Run current JavaScript file."
  (interactive)
  (compile (format "node '%s'" (buffer-file-name))))

;;; compile.el ends here

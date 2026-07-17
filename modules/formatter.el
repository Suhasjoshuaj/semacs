;;; formatter.el --- Code formatting integration

(use-package format-all
  :commands format-all-buffer format-all-region
  :hook
  ((prog-mode . format-all-ensure-formatter))
  :custom
  (format-all-default-formatters
   '((c-mode . clang-format)
     (c++-mode . clang-format)
     (python-mode . black)
     (rust-mode . rustfmt)
     (js-mode . prettier)
     (java-mode . google-java-format))))

;;; formatter.el ends here


;; to delete after windows.
;; Enable automatic bracket/quote pairs globally
(electric-pair-mode 1)

;; Configure Java-specific indentation and spacing rules
(defun my-java-style-hook ()
  ;; Use the standard "java" style ruleset
  (c-set-style "java")
  
  ;; Set indentation to exactly 4 spaces
  (setq c-basic-offset 4)
  (setq tab-width 4)
  (setq indent-tabs-mode nil) ; Force spaces, no tabs
  
  ;; Automatically clean up messy spaces at the end of lines when saving
  (add-hook 'before-save-hook 'delete-trailing-whitespace nil t))

;; Apply these spacing rules every time a Java file opens
(add-hook 'java-mode-hook 'my-java-style-hook)

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
     (typescript-ts-mode . prettier)
     (tsx-ts-mode . prettier)
     (java-mode . google-java-format))))

;;; formatter.el ends here

;;; formatter.el --- Code formatting integration

(use-package format-all
  :commands format-all-buffer format-all-region
  :hook
  ((prog-mode . format-all-ensure-formatter)
   (yaml-mode . format-all-ensure-formatter)) ; yaml-mode isn't prog-mode-derived, needs its own hook
  :custom
  (format-all-default-formatters
   '((c-mode . clang-format)
     (c++-mode . clang-format)
     (python-mode . black)
     (rust-mode . rustfmt)
     (js-mode . prettier)
     (typescript-mode . prettier)
     (yaml-mode . prettier) ; same prettier binary you already use for js/ts
     (java-mode . google-java-format))))

;;; formatter.el ends here

;;; formatter.el --- Code formatting integration  ... -*- lexical-binding: t; -*-

;; yaml-mode isn't prog-mode-derived, so it needs its own hook.
(use-package format-all
  :commands (format-all-buffer format-all-region)
  :hook
  ((prog-mode . format-all-ensure-formatter)
   (yaml-mode . format-all-ensure-formatter)))

;; (Removed a `format-all-default-formatters' override: format-all looks
;; formatters up by LANGUAGE NAME ("C++", "Python"), and the list used
;; major-mode symbols (c++-mode ...), so no entry could ever match and
;; format-all always used its own defaults. Those defaults already are
;; clang-format, black, rustfmt, prettier (js/ts/yaml) and
;; google-java-format -- exactly what the list tried to say.)

;;; formatter.el ends here

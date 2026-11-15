;;; formatter.el --- Code formatting integration  ... -*- lexical-binding: t; -*-

;; yaml-mode isn't prog-mode-derived, so it needs its own hook.
(use-package format-all
  :commands (format-all-buffer format-all-region)
  :hook
  ((prog-mode . format-all-ensure-formatter)
   (yaml-mode . format-all-ensure-formatter)))

;; format-all looks formatters up by LANGUAGE name and its defaults already
;; are clang-format, black, rustfmt, gofmt, prettier (js/ts/yaml) and
;; google-java-format -- install the tools you need; SPC e o formats the buffer.

;; Optional format-on-save, OFF by default: reformatting a file you do not
;; own makes noisy diffs. Opt in per language in local.el:
;;   (setq suhas/format-on-save-modes '(go-mode rust-mode))
(defun suhas/maybe-format-on-save ()
  "Format the buffer before saving when its mode is in `suhas/format-on-save-modes'.
Any formatter error is reported but never blocks the save."
  (when (and suhas/format-on-save-modes
             (apply #'derived-mode-p suhas/format-on-save-modes)
             (fboundp 'format-all-buffer))
    (condition-case err
        (format-all-buffer)
      (error (message "format-on-save skipped: %s" (error-message-string err))))))
(add-hook 'before-save-hook #'suhas/maybe-format-on-save)

;;; formatter.el ends here

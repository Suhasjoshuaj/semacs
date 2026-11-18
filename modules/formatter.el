;;; formatter.el --- Format the buffer (SPC e f), optional format-on-save  -*- lexical-binding: t; -*-
;;;
;;; ONE command: the language server formats when it can (clangd, gopls,
;;; rust-analyzer ...); otherwise format-all runs the language's standard
;;; tool (black, prettier, clang-format, rustfmt, gofmt, shfmt ...).
;;; format-all is loaded on first use, never at startup.

(use-package format-all
  :commands (format-all-buffer format-all-ensure-formatter))

(defun suhas/format-buffer ()
  "Format the current buffer (SPC e f)."
  (interactive)
  (if (and (bound-and-true-p eglot--managed-mode)
           (eglot-server-capable :documentFormattingProvider))
      (eglot-format-buffer)
    (format-all-ensure-formatter)
    (format-all-buffer)))

;; Format-on-save is OFF by default: reformatting a file you do not own
;; makes noisy diffs. Opt in per language in local.el:
;;   (setq suhas/format-on-save-modes '(go-ts-mode rust-ts-mode))
(defun suhas/maybe-format-on-save ()
  "Format before saving when the mode is in `suhas/format-on-save-modes'.
A formatter error is reported but never blocks the save."
  (when (and suhas/format-on-save-modes
             (derived-mode-p suhas/format-on-save-modes))
    (condition-case err
        (suhas/format-buffer)
      (error (message "format-on-save skipped: %s" (error-message-string err))))))
(add-hook 'before-save-hook #'suhas/maybe-format-on-save)

;;; formatter.el ends here

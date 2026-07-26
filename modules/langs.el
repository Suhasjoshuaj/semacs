;;; langs.el --- Per-language configuration

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-mode)
  :custom
  (python-indent-offset 4))

(use-package js
  :ensure nil
  :mode ("\\.js\\'" . js-mode)
  :custom
  (js-indent-level 2))


(add-hook 'prog-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)))

;;; langs.el ends here

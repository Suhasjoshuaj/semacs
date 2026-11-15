;;; forge.el --- Pull requests and issues inside magit  ... -*- lexical-binding: t; -*-
;;;
;;; GitHub / GitLab from magit: list and review PRs, create them, read issues.
;;;
;;; SETUP (once): forge needs an access token in ~/.authinfo (or the
;;; auth-source you use): see https://magit.vc/manual/forge/Token-Creation.html
;;; Then in a repo:  SPC g s (magit status), SPC g f (forge menu), `f p' pull.
;;;
;;; Needs Emacs built with sqlite (M-x suhas/doctor checks). Loads only
;;; after magit; remove "forge" from `suhas/modules' to drop it entirely.

(use-package forge
  :after magit
  :ensure t)

(with-eval-after-load 'evil
  (suhas/leader "g f" #'forge-dispatch))

;;; forge.el ends here

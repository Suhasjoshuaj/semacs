;;; forge.el --- Pull requests and issues inside magit  -*- lexical-binding: t; -*-
;;;
;;; GitHub / GitLab from magit: list and review PRs, create them, read issues.
;;;
;;; SETUP (once): forge needs an access token in ~/.authinfo (or the
;;; auth-source you use): https://magit.vc/manual/forge/Token-Creation.html
;;; Then in a repo:  SPC g s (magit status), SPC g f (forge menu), `f p' pull.
;;;
;;; Loads right after magit, never at startup. Remove "forge" from
;;; `suhas/modules' to drop it.

(use-package forge
  :after magit
  :demand t)

(suhas/leader "g f" #'forge-dispatch)

;;; forge.el ends here

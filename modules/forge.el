;;; forge.el --- Pull requests and issues inside magit  -*- lexical-binding: t; -*-
;;;
;;; GitHub / GitLab from magit: list and review PRs, create them, read issues.
;;;
;;; SETUP (once): forge needs an access token in ~/.authinfo (or the
;;; auth-source you use): https://magit.vc/manual/forge/Token-Creation.html
;;; Then in a repo:  SPC g s (magit status), SPC g f or N (forge menu).
;;;
;;; Loads the first time you use it (SPC g f, or N / ' in magit), never
;;; with magit itself: forge's database layer (closql) wraps every EIEIO
;;; slot read in Emacs, about 4x slower, which magit sections, eglot and
;;; jsonrpc all pay for once it is loaded. Its pull-request sections join
;;; magit status from then on. Remove "forge" from `suhas/modules' to drop it.

(use-package forge
  :commands (forge-dispatch))

(suhas/leader "g f" #'forge-dispatch)

;;; forge.el ends here

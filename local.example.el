;;; local.example.el --- Template for YOUR machine-specific settings  -*- lexical-binding: t; -*-
;;;
;;; Copy this file to local.el (in the same folder as init.el), or press
;;; SPC c o inside Emacs and it will do that for you. local.el is gitignored:
;;; it never gets committed and `git pull' never conflicts with it.
;;;
;;; It is loaded right after modules/settings.el and BEFORE every other
;;; module, so a `setq' here overrides any default. Every knob, with its
;;; default and an explanation, is in modules/settings.el.
;;; After editing: SPC c r (reload) -- or restart for a clean slate.

;; Where your repos live. Each folder that exists is searched; each repo
;; inside (up to `suhas/repo-root-depth' levels down) becomes a project.
;; (setq suhas/repo-root-candidates '("~/work" "~/code" "~/personal"))
;; (setq suhas/repo-root-depth 2)

;; Switch whole features off by removing their module. Notes and
;; org-roam are personal; skip them on a work machine:
;; (setq suhas/modules (delete "org" suhas/modules))
;; No pull-request integration:
;; (setq suhas/modules (delete "forge" suhas/modules))

;; Font (applied only when installed) and theme list.
;; (setq suhas/font-family "JetBrains Mono")
;; (setq suhas/font-size 110)

;; Start with plain Emacs keys instead of Vim keys (toggle: SPC c v / C-c v).
;; (setq suhas/vim-mode-enabled nil)

;; Languages and servers.
;; (setq suhas/python-lsp-command '("basedpyright-langserver" "--stdio"))
;; (setq suhas/lsp-confirm-edits nil)              ; do not ask before server edits
;; (setq suhas/format-on-save-modes '(go-mode rust-mode))

;; Claude Code.
;; (setq suhas/claude-command "claude")            ; flags allowed
;; (setq suhas/claude-integration 'claude-code-ide) ; MCP bridge (Emacs 30+)

;; Behind a corporate proxy, make sure the variables are copied into GUI Emacs
;; (the defaults already include the usual proxy variables).
;; (add-to-list 'suhas/shell-env-variables "NODE_EXTRA_CA_CERTS")

;; Anything else machine-specific can go here too: it is just Emacs Lisp.

;;; local.example.el ends here

;;; local.example.el --- Template for YOUR machine-specific settings  -*- lexical-binding: t; -*-
;;;
;;; Copy this file to local.el (next to init.el), or press SPC c o inside
;;; Emacs and it is done for you. local.el is gitignored: it never gets
;;; committed and `git pull' never conflicts with it.
;;;
;;; It is loaded right after modules/settings.el and BEFORE every other
;;; module, so a `setq' here overrides any default. Every knob, with its
;;; default and an explanation, is in modules/settings.el.
;;; After editing: restart, or SPC c r (reload).

;; Where your repos live. Each folder that exists is searched; each repo
;; inside (up to `suhas/repo-root-depth' levels down) becomes a project.
;; (setq suhas/repo-root-candidates '("~/work" "~/code" "~/personal"))
;; (setq suhas/repo-root-depth 2)

;; Switch whole features off by removing their module.
;; (setq suhas/modules (delete "org" suhas/modules))     ; no notes tooling
;; (setq suhas/modules (delete "forge" suhas/modules))   ; no pull-request integration

;; Looks.
;; (setq suhas/font-family "JetBrains Mono")
;; (setq suhas/font-size 110)
;; (setq suhas/default-theme 'modus-operandi-tinted)     ; light
;; (setq suhas/frame-padding 0)

;; Start with plain Emacs keys instead of Vim keys (toggle: SPC c v / C-c v).
;; (setq suhas/vim-mode-enabled nil)

;; Terminal.
;; (setq suhas/terminal-position 'right)
;; (setq suhas/terminal-escape 'auto)      ; ESC = Evil normal state at a shell prompt

;; Languages and servers.
;; (setq suhas/python-lsp-command '("basedpyright-langserver" "--stdio"))
;; (setq suhas/lsp-confirm-edits nil)                    ; do not ask before server edits
;; (setq suhas/lsp-auto-start nil)                       ; start servers by hand (M-x eglot)
;; (setq suhas/format-on-save-modes '(go-ts-mode rust-ts-mode))
;; Keep the classic (non tree-sitter) mode for a language:
;; (setq suhas/treesit-modes (assq-delete-all 'c-ts-mode suhas/treesit-modes))

;; Company network: an internal package mirror, extra variables for GUI Emacs.
;; (setq suhas/package-archives '(("gnu" . "https://mirror.example.com/gnu/") ...))
;; (add-to-list 'suhas/shell-env-variables "NODE_EXTRA_CA_CERTS")

;; Anything else machine-specific can go here too: it is just Emacs Lisp.

;;; local.example.el ends here

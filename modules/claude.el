;;; claude.el --- Claude Code from Emacs  ... -*- lexical-binding: t; -*-
;;;
;;; SPC a c   open Claude Code in a new terminal at the project root
;;; SPC a r   same, but resume a previous conversation (claude --resume)
;;; SPC a m   menu of the optional integration (only if enabled)
;;;
;;; Claude Code is a terminal program, and this config already has a good
;;; terminal (ghostel). So the default is deliberately simple: no extra
;;; packages, no MCP bridge -- just `claude' running in a ghostel buffer
;;; named *term:claude:<project>*, started in the project's directory, inside
;;; the current perspective. When Claude exits, its terminal buffer closes.
;;;
;;; Things that make this pleasant, all already configured elsewhere:
;;;   - auto-revert (core.el): files Claude edits refresh in your buffers
;;;   - diff-hl + magit: review what Claude changed (SPC g s)
;;;   - ESC goes to Claude, not to Evil (see below)
;;;   - SPC s g / SPC s f / consult-xref to read what it touched
;;;
;;; ESC: Claude Code uses ESC to interrupt and (twice) to rewind. evil-ghostel's
;;; default `auto' routing only forwards ESC to programs on the ALTERNATE
;;; screen (vim, less, htop); Claude Code draws on the normal screen. So these
;;; buffers pin ESC to the program. To get Evil's normal state in one:
;;; C-c e (cycles auto -> app -> evil). SPC t e does the same from normal state.
;;;
;;; Optional: `(setq suhas/claude-integration 'claude-code-ide)' in local.el
;;; adds manzaltu/claude-code-ide.el: Claude can see your selection, open
;;; buffers and Flymake diagnostics. Needs Emacs 30+.

(defun suhas/--login-shell-argv (command)
  "ARGV for `suhas/terminal-spawn': COMMAND in a login, interactive shell.
Login + interactive so PATH is the one you get in a real terminal (that is
where `claude' is installed)."
  (if suhas/windows-p
      (list (expand-file-name "usr/bin/bash.exe" suhas/git-for-windows-root)
            "--login" "-i" "-c" command)
    (list (or (getenv "SHELL") "/bin/sh") "-l" "-i" "-c" command)))

(defun suhas/claude (&optional resume)
  "Open Claude Code in a new terminal at the project root (SPC a c).
With prefix argument RESUME, pass --resume to pick a previous conversation."
  (interactive "P")
  (unless (executable-find (car (split-string suhas/claude-command)))
    ;; Not fatal: a login shell may find it even when Emacs's PATH cannot.
    (message "Note: `%s' is not on Emacs's PATH; trying a login shell."
             (car (split-string suhas/claude-command))))
  (let* ((root (suhas/project-dir))
         (default-directory root)
         (command (if resume
                      (concat suhas/claude-command " --resume")
                    suhas/claude-command))
         (name (format "claude:%s"
                       (file-name-nondirectory (directory-file-name root)))))
    (suhas/terminal-spawn name (suhas/--login-shell-argv command))
    (suhas/terminal-escape-to-app)))

(defun suhas/claude-resume ()
  "Open Claude Code and pick a previous conversation to resume (SPC a r)."
  (interactive)
  (suhas/claude t))

(with-eval-after-load 'evil
  (suhas/leader
    "a c" #'suhas/claude
    "a r" #'suhas/claude-resume))

;;; ------------------------------------------------------------
;;; Optional integration (off by default)
;;; ------------------------------------------------------------

(when (eq suhas/claude-integration 'claude-code-ide)
  (if (< emacs-major-version 30)
      (display-warning 'semacs
                       "claude-code-ide integration needs Emacs 30+ (package :vc); skipped."
                       :warning)
    ;; `eval', so the :vc keyword is only macro-expanded on Emacs 30+
    ;; (Emacs 29's use-package would reject it while loading this file).
    (eval '(use-package claude-code-ide
             :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
             :custom
             (claude-code-ide-terminal-backend 'ghostel)
             :config
             (claude-code-ide-emacs-tools-setup))
          t)
    (with-eval-after-load 'evil
      (suhas/leader "a m" #'claude-code-ide-menu))))

;;; claude.el ends here

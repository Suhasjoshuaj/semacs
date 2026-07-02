;;; terminal.el --- Cross-platform terminal configuration -*- lexical-binding: t; -*-

;;; ===========================================================================
;;; TERMINAL
;;; ===========================================================================
;;
;; Windows
;; ---------
;; We intentionally use `shell` instead of `eat`.
;;
;; Why?
;;
;; `eat` requires a real PTY backend.
;; Native Windows Emacs does not provide one.
;;
;; `shell` uses Comint (pipes), which works reliably with Git Bash.
;;
;;
;; Linux
;; -----
;; Use Eat because it gives a real terminal emulator with full ANSI,
;; mouse support, shell integration, etc.
;;
;;; ===========================================================================

(if suhas/windows-p

    ;; =======================================================================
    ;; Windows
    ;; =======================================================================

    (progn

      (let* ((git-root "C:/Program Files/Git")
             (usr-bin (concat git-root "/usr/bin"))
             (mingw-bin (concat git-root "/mingw64/bin"))
             (bash (concat usr-bin "/bash.exe")))

        ;; ------------------------------------------------------------
        ;; Configure Bash
        ;; ------------------------------------------------------------

        (setq shell-file-name bash)
        (setq explicit-shell-file-name bash)

        ;; Start as an interactive login shell.
        (setq explicit-bash-args
              '("--login" "-i"))

        ;; Used by shell-command, async-shell-command, etc.
        (setq shell-command-switch "-lc")

        ;; ------------------------------------------------------------
        ;; Git Bash environment
        ;; ------------------------------------------------------------

        ;; Git Bash normally sets these itself.
        ;; Since Emacs launches bash directly, we do it here.

        (setenv "MSYSTEM" "MINGW64")
        (setenv "CHERE_INVOKING" "1")

        ;; ------------------------------------------------------------
        ;; PATH
        ;; ------------------------------------------------------------

        ;; Git utilities live here:
        ;;
        ;; usr/bin      -> clear, ls, grep, sed...
        ;; mingw64/bin  -> gcc, dlls, runtime...

        (dolist (dir (list usr-bin mingw-bin))
          (unless (member dir exec-path)
            (push dir exec-path)))

        (setenv
         "PATH"
         (mapconcat
          #'identity
          (append
           (list usr-bin mingw-bin)
           (split-string (or (getenv "PATH") "") ";" t))
          ";"))

        ;; UTF-8 everywhere.

        (set-language-environment "UTF-8")
        (prefer-coding-system 'utf-8-unix))

      ;; ------------------------------------------------------------
      ;; Open terminal
      ;; ------------------------------------------------------------

      (defun suhas/open-terminal ()
        "Open Git Bash in a bottom split."

        (interactive)

        (let ((buf (get-buffer "*shell*")))

          (if (and buf
                   (get-buffer-window buf))

              (select-window
               (get-buffer-window buf))

            (split-window-below 15)

            (other-window 1)

            (if buf
                (switch-to-buffer buf)
              (shell)))))

      (defun suhas/close-terminal ()
        "Close terminal window."

        (interactive)

        (delete-window)))

  ;; =======================================================================
  ;; Linux
  ;; =======================================================================

  (progn

    (use-package eat
      :ensure t
      :commands eat

      :custom

      (eat-kill-buffer-on-exit t)
      (eat-enable-mouse t)

      :config

      (add-hook
       'eat-mode-hook
       (lambda ()

         (display-line-numbers-mode -1)

         (setq-local scroll-margin 0))))

    (defun suhas/open-terminal ()

      (interactive)

      (let ((buf (get-buffer "*eat*")))

        (if (and buf
                 (get-buffer-window buf))

            (select-window
             (get-buffer-window buf))

          (split-window-below 15)

          (other-window 1)

          (if buf
              (switch-to-buffer buf)
            (eat)))))

    (defun suhas/close-terminal ()

      (interactive)

      (delete-window))))

(provide 'terminal)

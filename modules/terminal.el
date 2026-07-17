;;; terminal.el --- Cross-platform terminal configuration -*- lexical-binding: t; -*-
(if suhas/windows-p

    ;; =======================================================================
    ;; Windows
    ;; =======================================================================

    (progn

      (use-package ghostel
        :ensure t
        :commands ghostel)

      (use-package evil-ghostel
        :ensure t
        :after (ghostel evil)
        :hook (ghostel-mode . evil-ghostel-mode))

      (let* ((git-root "C:/Program Files/Git")
             (usr-bin (concat git-root "/usr/bin"))
             (mingw-bin (concat git-root "/mingw64/bin"))
             (bash (concat usr-bin "/bash.exe")))

        ;; ------------------------------------------------------------
        ;; Configure Bash for ghostel
        ;; ------------------------------------------------------------

        ;; List form: executable + args. Long options before short ones
        ;; (bash rejects long options that follow short ones) --
        ;; "--login" before "-i" already satisfies this.
        (setq ghostel-shell (list bash "--login" "-i"))

        (setq ghostel-kill-buffer-on-exit t)

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
        "Open Git Bash (via ghostel) in a bottom split."

        (interactive)

        (require 'ghostel)

        (let ((buf (get-buffer ghostel-buffer-name)))

          (if (and buf
                   (get-buffer-window buf))

              (select-window
               (get-buffer-window buf))

            ;;(split-window-right 100)
            (split-window-below 25)

            (other-window 1)

            (if buf
                (switch-to-buffer buf)
              (ghostel)))))

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

          ;;(split-window-right 100)
          (split-window-below 30)

          (other-window 1)

          (if buf
              (switch-to-buffer buf)
            (eat)))))

    (defun suhas/close-terminal ()

      (interactive)

      (delete-window))))

(provide 'terminal)

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
        (prefer-coding-system 'utf-8-unix)))

      ;; ------------------------------------------------------------
      ;; Open terminal
      ;; ------------------------------------------------------------

;;      (defun suhas/open-terminal ()
;;        "Open Git Bash (via ghostel) in a bottom split."
;;        (interactive)
;;        (require 'ghostel)
;;        (let ((buf (get-buffer ghostel-buffer-name)))
;;          (if (and buf
;;                   (get-buffer-window buf))
;;              (select-window
;;               (get-buffer-window buf))
;;
;;            ;;(split-window-right 100)
;;            (split-window-below 25)
;;            (other-window 1)
;;            (if buf
;;                (switch-to-buffer buf)
;;              (ghostel)))))
;;
;;      (defun suhas/close-terminal ()
;;        "Close terminal window."
;;        (interactive)
;;        (delete-window)))

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
         (setq-local scroll-margin 0))))))

;;    (defun suhas/open-terminal ()
;;      (interactive)
;;      (let ((buf (get-buffer "*eat*")))
;;        (if (and buf
;;                 (get-buffer-window buf))
;;            (select-window
;;             (get-buffer-window buf))
;;          ;;(split-window-right 100)
;;          (split-window-below 30)
;;          (other-window 1)
;;          (if buf
;;              (switch-to-buffer buf)
;;            (eat)))))
;;
;;    (defun suhas/close-terminal ()
;;      (interactive) (delete-window))))

;; ... (your existing Windows/Linux branches stay exactly as they are,
;;      but delete suhas/open-terminal and suhas/close-terminal from
;;      inside each branch — they're replaced below, unified) ...

;; ===========================================================================
;; Shared multi-terminal layer
;; ===========================================================================

(defvar suhas/terminal-mode (if suhas/windows-p 'ghostel-mode 'eat-mode)
  "Major mode of the active terminal backend on this platform.")

(defun suhas/terminal-buffer-p (buf)
  (and (buffer-live-p buf)
       (with-current-buffer buf (derived-mode-p suhas/terminal-mode))))

(defun suhas/terminal-buffers ()
  "Live terminal buffers, most-recently-used first.
No cached list to go stale -- `buffer-list' already tracks MRU order,
we just filter it on demand."
  (seq-filter #'suhas/terminal-buffer-p (buffer-list)))

(defun suhas/terminal-window ()
  "Window reserved for terminals, identified by a tag set at creation --
not by buffer content, so it's safe to call before a terminal exists in it."
  (seq-find (lambda (w) (window-parameter w 'suhas-terminal-slot))
            (window-list)))

(defun suhas/terminal--split! ()
  "Create the small bottom split and select it."
  (let* ((desired (round (* (if suhas/windows-p 0.28 0.32) (frame-height))))
         (room (- (window-height) window-min-height 1)))
    (cond
     ((>= room desired) (split-window-below (- desired)) (other-window 1))
     ((> room 4)        (split-window-below (- room))    (other-window 1))
     (t nil))
    (set-window-parameter (selected-window) 'suhas-terminal-slot t)))

(defun suhas/terminal-ensure-window ()
  "Ensure the terminal split exists and select it.
Idempotent: calling it twice in a row never double-splits.

Also handles SPC w o (`delete-other-windows') collapsing the frame
down to just the terminal window: that window keeps the
`suhas-terminal-slot' parameter, so naive logic would just re-select
it and leave it full-frame forever. We detect \"only one window on
the frame\" and rebuild the small split, restoring whatever buffer
was on screen before the collapse."
  (let* ((win (suhas/terminal-window))
         (collapsed (and win (= 1 (length (window-list))))))
    (cond
     ((and win (not collapsed))
      (select-window win))

     (collapsed
      (let ((term-buf (window-buffer win))
            (other-buf (or (seq-find (lambda (b) (not (suhas/terminal-buffer-p b)))
                                      (buffer-list))
                           (get-buffer-create "*scratch*"))))
        (select-window win)
        (set-window-parameter win 'suhas-terminal-slot nil)
        (switch-to-buffer other-buf)
        (suhas/terminal--split!)
        (switch-to-buffer term-buf)))

     (t (suhas/terminal--split!)))))

(defun suhas/terminal-spawn (&optional name)
  "Create a brand-new terminal instance, optionally naming it."
  (suhas/terminal-ensure-window)
  (let ((current-prefix-arg '(4))) ; mimics C-u M-x eat / C-u M-x ghostel -> forces a NEW buffer
    (if suhas/windows-p
        (call-interactively #'ghostel)
      (call-interactively #'eat)))
  (when name
    (rename-buffer (format "*term:%s*" name) t)))

(defun suhas/open-terminal ()
  "SPC t t -- show the most recently used terminal, or create one."
  (interactive)
  (suhas/terminal-ensure-window)
  (unless (suhas/terminal-buffer-p (window-buffer (selected-window)))
    (let ((bufs (suhas/terminal-buffers)))
      (if bufs
          (switch-to-buffer (car bufs)) ; car = most recently used, since buffer-list is MRU-ordered
        (suhas/terminal-spawn)))))

(defun suhas/terminal-create-named ()
  "SPC t n -- prompt for a name, open a new terminal with it."
  (interactive)
  (let ((name (read-string "Name: ")))
    (suhas/terminal-spawn (unless (string-empty-p name) name))))

(defun suhas/terminal-switch ()
  "Pick a running terminal by name (Vertico-powered, since it's plain `completing-read')."
  (interactive)
  (let ((bufs (suhas/terminal-buffers)))
    (if (null bufs)
        (suhas/terminal-spawn)
      (let ((choice (completing-read "Terminal: " (mapcar #'buffer-name bufs) nil t)))
        (suhas/terminal-ensure-window)
        (switch-to-buffer choice)))))

(defun suhas/terminal-kill-all ()
  "Kill every terminal buffer and close the terminal window."
  (interactive)
  (let ((bufs (suhas/terminal-buffers)))
    (if (null bufs)
        (message "No terminals running")
      (let ((kill-buffer-query-functions nil)) ; skip the per-buffer "process running, kill?" prompt
        (mapc #'kill-buffer bufs))
      (when (suhas/terminal-window)
        (delete-window (suhas/terminal-window)))
      (message "Killed %d terminal(s)" (length bufs)))))

(defun suhas/terminal--target ()
  "The terminal buffer to act on: current buffer if it's a terminal,
otherwise whatever's showing in the terminal window. Nil if neither."
  (cond
   ((suhas/terminal-buffer-p (current-buffer)) (current-buffer))
   ((suhas/terminal-window) (window-buffer (suhas/terminal-window)))
   (t nil)))

(defun suhas/terminal-kill ()
  (interactive)
  (delete-window))

(defun suhas/terminal-rename ()
  "SPC t r -- rename the current (or displayed) terminal."
  (interactive)
  (let ((target (suhas/terminal--target)))
    (if (not target)
        (message "No terminal to rename")
      (let ((name (read-string "Rename terminal to: ")))
        (unless (string-empty-p name)
          (with-current-buffer target
            (rename-buffer (format "*term:%s*" name) t)))))))

(provide 'terminal)

;;; terminal.el --- Cross-platform terminal configuration -*- lexical-binding: t; -*-
(if suhas/windows-p

    ;; =======================================================================
    ;; Windows
    ;; =======================================================================

    (progn

      (use-package ghostel
        :ensure t
        :commands ghostel
        :custom
        ;; Evil's visual state (v) activates the mark; isearch and
        ;; minibuffer-exit move point off the live cursor. Ghostel's
        ;; defaults treat any of those as "user wants to read/copy" and
        ;; silently freeze the buffer into copy-mode -- a mode evil's
        ;; own i/a/ESC don't know how to exit. nil keeps semi-char (live
        ;; typing) active through all three; use `C-c C-t' / `C-x C-q'
        ;; when you actually do want the frozen, selectable view.
        (ghostel-mark-activation-input-mode nil)
        (ghostel-mouse-drag-input-mode nil)
        (ghostel-point-leave-input-mode nil))

      (use-package evil-ghostel
        :ensure t
        :after (ghostel evil)
        :hook (ghostel-mode . evil-ghostel-mode)
        :custom
        ;; 'auto (the default): ESC -> normal state at a plain shell
        ;; prompt (standard vim ESC/i/a/v), and ESC -> forwarded to the
        ;; app while an alt-screen program (vim, less, htop) is running,
        ;; so nested apps still work normally too. Left explicit here so
        ;; it's obvious this was a deliberate choice, not an oversight.
        (evil-ghostel-escape 'auto))

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

;; ===========================================================================
;; Shared multi-terminal layer
;; ===========================================================================

(defvar suhas/terminal-mode (if suhas/windows-p 'ghostel-mode 'eat-mode)
  "Major mode of the active terminal backend on this platform.")

(defvar suhas/terminal-position 'below
  "Where the terminal window is placed: `below' or `right'.
Set via `suhas/terminal-set-position' (SPC t p), not by hand --
that function also relocates an already-open terminal window.")

(defvar suhas/terminal-height-fraction (if suhas/windows-p 0.28 0.32)
  "Fraction of frame height the terminal gets when split below.")

(defvar suhas/terminal-width-fraction 0.35
  "Fraction of frame width the terminal gets when split right.")

(defun suhas/terminal-buffer-p (buf)
  (and (buffer-live-p buf)
       (with-current-buffer buf (derived-mode-p suhas/terminal-mode))))

(defun suhas/terminal-buffers ()
  "Live terminal buffers, most-recently-used first.
No cached list to go stale -- `buffer-list' already tracks MRU order,
we just filter it on demand."
  (seq-filter #'suhas/terminal-buffer-p (buffer-list)))

(defun suhas/persp-terminal-buffers ()
  "This perspective's live terminal buffers, most-recently-used first.
Everything below that shows, switches, or rotates terminals uses this,
never `suhas/terminal-buffers' directly -- terminals stay put in the
perspective they were created in."
  (seq-filter #'suhas/persp-buffer-p (suhas/terminal-buffers)))

(defun suhas/terminal-window ()
  "Window reserved for terminals, identified by a tag set at creation --
not by buffer content, so it's safe to call before a terminal exists in it."
  (seq-find (lambda (w) (window-parameter w 'suhas-terminal-slot))
            (window-list)))

(defun suhas/terminal--split-below! ()
  "Create the small bottom split and select it."
  (let* ((desired (+ 3 (round (* suhas/terminal-height-fraction (frame-height)))))
         (room (- (window-height) window-min-height 1)))
    (cond
     ((>= room desired) (split-window-below (- desired)) (other-window 1))
     ((> room 4)        (split-window-below (- room))    (other-window 1))
     (t nil))))

(defun suhas/terminal--split-right! ()
  "Create the narrow right split and select it."
  (let* ((desired (round (* suhas/terminal-width-fraction (frame-width))))
         (room (- (window-width) window-min-width 1)))
    (cond
     ((>= room desired) (split-window-right (- desired)) (other-window 1))
     ((> room 4)        (split-window-right (- room))    (other-window 1))
     (t nil))))

(defun suhas/terminal--split! ()
  "Create the terminal split in `suhas/terminal-position' and select it."
  (if (eq suhas/terminal-position 'right)
      (suhas/terminal--split-right!)
    (suhas/terminal--split-below!))
  (set-window-parameter (selected-window) 'suhas-terminal-slot t))

(defun suhas/terminal-set-position (&optional position)
  "SPC t p -- choose whether the terminal splits `below' or `right'.
If a terminal window is already open, it's relocated on the spot
instead of waiting for the next `suhas/open-terminal' call."
  (interactive
   (list (intern (completing-read "Terminal position: " '("below" "right") nil t))))
  (setq suhas/terminal-position position)
  (let ((win (suhas/terminal-window)))
    (when win
      (let ((buf (window-buffer win)))
        (set-window-parameter win 'suhas-terminal-slot nil)
        (delete-window win)
        (suhas/terminal--split!)
        (switch-to-buffer buf))))
  (message "Terminal now splits %s" position))

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
                                      (seq-filter #'suhas/persp-buffer-p (buffer-list)))
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
  "SPC t t -- show this perspective's most recently used terminal,
or create a new one if this perspective doesn't have one yet.
Never pulls in a terminal from another perspective; use
`persp-switch-to-buffer' directly if you want that."
  (interactive)
  (suhas/terminal-ensure-window)
  (unless (suhas/terminal-buffer-p (window-buffer (selected-window)))
    (let ((bufs (suhas/persp-terminal-buffers)))
      (if bufs
          (switch-to-buffer (car bufs)) ; car = most recently used, since buffer-list is MRU-ordered
        (suhas/terminal-spawn)))))

(defun suhas/terminal-create-named ()
  "SPC t n -- prompt for a name, open a new terminal with it."
  (interactive)
  (let ((name (read-string "Name: ")))
    (suhas/terminal-spawn (unless (string-empty-p name) name))))

(defun suhas/terminal-switch ()
  "SPC t s -- pick a terminal in the current perspective by name
(Vertico-powered, since it's plain `completing-read'). Terminals in
other perspectives are never listed here."
  (interactive)
  (let ((bufs (suhas/persp-terminal-buffers)))
    (if (null bufs)
        (suhas/terminal-spawn)
      (let ((choice (completing-read "Terminal: " (mapcar #'buffer-name bufs) nil t)))
        (suhas/terminal-ensure-window)
        (switch-to-buffer choice)))))

(defun suhas/terminal-kill-all ()
  "Kill every terminal buffer in this perspective and close the
terminal window. Terminals belonging to other perspectives are untouched."
  (interactive)
  (let ((bufs (suhas/persp-terminal-buffers)))
    (if (null bufs)
        (message "No terminals running in this perspective")
      (let ((kill-buffer-query-functions nil)) ; skip the per-buffer "process running, kill?" prompt
        (mapc #'kill-buffer bufs))
      (when (suhas/terminal-window)
        (delete-window (suhas/terminal-window)))
      (message "Killed %d terminal(s)" (length bufs)))))

(defun suhas/terminal-rotate (direction)
  "Cycle the terminal window through this perspective's terminal
buffers, in DIRECTION ('next or 'prev). Same MRU-walk as code-buffer
rotation (`suhas/mru-step'), just applied to the terminal pool instead."
  (let ((bufs (suhas/persp-terminal-buffers))
        (win (suhas/terminal-window)))
    (cond
     ((null bufs) (message "No terminals in this perspective"))
     ((null win) (suhas/open-terminal))
     (t (select-window win)
        (switch-to-buffer (suhas/mru-step bufs direction))))))

(defun suhas/terminal-next ()
  "SPC t l -- cycle to the next terminal in this perspective."
  (interactive)
  (suhas/terminal-rotate 'next))

(defun suhas/terminal-prev ()
  "SPC t h -- cycle to the previous terminal in this perspective."
  (interactive)
  (suhas/terminal-rotate 'prev))

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

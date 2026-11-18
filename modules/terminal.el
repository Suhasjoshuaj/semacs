;;; terminal.el --- ghostel terminal: one panel, terminals per workspace  -*- lexical-binding: t; -*-
;;;
;;; ghostel (libghostty) on every OS. It needs an Emacs with dynamic-module
;;; support; the first SPC t t offers to DOWNLOAD the prebuilt native module
;;; (answer yes). Install ghostel from MELPA as below, never with :vc, and
;;; leave `ghostel-module-directory' alone.
;;;
;;; THE MODEL
;;;   - Terminal buffers always appear in ONE panel (below or right), no
;;;     matter which command shows them. C-` / SPC t t toggles it.
;;;   - Every workspace (perspective) has its own terminals; a new one
;;;     starts in the project root and is named *term:PROJECT*.
;;;   - It behaves like a normal terminal emulator: every key, ESC included,
;;;     goes to the program. That is what coding agents and TUIs expect, so
;;;     none of them needs special handling.
;;;
;;;
;;; EDITING THE COMMAND LINE
;;;   - Click on the line you are typing to move the shell's cursor there.
;;;   - The shell's cursor only moves along its current line: to a shell,
;;;     Up/Down mean history, never "the line above".
;;;   - Long or multi-line input: edit it in a real Emacs buffer. bash:
;;;     C-. e; Claude Code: Ctrl+G; `git commit' opens one by itself.
;;;     Finish with C-c C-c (or :wq), abort with C-c C-k.
;;;
;;; KEYS (C-. works in every state, inside terminals too; SPC t is the same map)
;;;   C-`  or C-c t   go to the terminal / hide the panel
;;;   C-. n s l h     new / pick / next / previous
;;;   C-. r k K       rename / kill / kill all of this workspace
;;;   C-. p y a e     panel side / send region or path:line / attention / edit input
;;;
;;; WHILE TYPING IN A TERMINAL
;;;   C-c ESC or C-x ESC   Evil normal state (move, search, yank; i/a to type again)
;;;   C-c SPC              the leader          C-c C-t   copy mode (frozen view)
;;;   C-y / M-y            paste / older kills (p and P in normal state)
;;;   mouse drag           select = copy (y in normal state also copies)
;;;   C-c C-r              change where ESC goes in this terminal
;;;
;;; Position, size, ESC routing and prompt are knobs in settings.el.

(use-package ghostel
  :commands (ghostel ghostel-create ghostel-paste-string ghostel-status-next
             ghostel-buffer-focused-p)
  :custom
  (ghostel-kill-buffer-on-exit t)
  ;; Keys Emacs keeps for itself: ghostel's defaults, the terminal map,
  ;; buffer cycling and workspace switching. Everything else goes to the
  ;; program.
  (ghostel-keymap-exceptions
   '("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "C-\\"
     "C-." "C-`" "C-;" "C-'" "C-,"
     "M-1" "M-2" "M-3" "M-4" "M-5" "M-6" "M-7" "M-8" "M-9"))
  ;; A click on the line you are typing moves the shell's cursor
  ;; (`suhas/terminal-click'); a click anywhere else just sets point. No
  ;; switch to a frozen copy mode on click: drag to select instead.
  (ghostel-mouse-drag-input-mode nil)
  ;; `ring-bell-function' is `ignore', so a BEL would vanish. Say it instead.
  (ghostel-bell-functions '(suhas/terminal-bell))
  :config
  (add-hook 'ghostel-mode-hook #'suhas/terminal-buffer-setup)
  (advice-add 'ghostel-mouse-release-or-set-point :around #'suhas/terminal-click)
  ;; Modeline indicator when a program in any terminal reports that it is
  ;; blocked / done / failed (OSC status reports; coding agents send them).
  (ghostel-status-indicator-mode 1))

(use-package evil-ghostel
  :commands (evil-ghostel-mode)
  :custom
  (evil-ghostel-escape suhas/terminal-escape)
  :config
  ;; C-y pastes YOUR kill ring (evil-ghostel sends it to the shell's own,
  ;; separate one).
  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "C-y") #'ghostel-yank
    (kbd "M-y") #'ghostel-yank-pop)
  ;; Never move the shell's cursor across lines (see below).
  (advice-add 'evil-ghostel-goto-input-position :filter-args
              #'suhas/terminal--same-row)
  (advice-add 'evil-ghostel-delete-input-region :before
              #'suhas/terminal--check-delete))

(defun suhas/terminal-buffer-setup ()
  "Per-terminal-buffer setup."
  (setq-local scroll-margin 0
              ;; A terminal buffer always counts as modified: show "--".
              mode-line-modified "--"
              ;; Selecting with the mouse copies, like any terminal
              ;; emulator (keys such as M-w belong to the program).
              mouse-drag-copy-region t)
  (when (bound-and-true-p evil-mode)
    (evil-ghostel-mode 1)))

;;; ============================================================
;;; CURSOR FIXES — the shell owns its cursor
;;; ============================================================

;; evil-ghostel moves the shell's cursor to point by sending arrow keys.
;; Left/Right are safe; Up/Down are not: to bash (readline) they mean
;; "previous/next command", so a paste on an earlier line of a multi-line
;; command recalled history and landed after it.

(defun suhas/terminal--same-row (args)
  "Keep a cursor move on the shell cursor's row (`:filter-args' advice).
A target on another row becomes the shell cursor itself: a paste or
insert happens where the shell's cursor is."
  (let ((pos (car args)))
    (if (or (null ghostel--cursor-char-pos)
            (ghostel-point-on-cursor-row-p pos))
        args
      (cons ghostel--cursor-char-pos (cdr args)))))

(defun suhas/terminal--check-delete (beg end)
  "Refuse to delete input across lines; the shell cannot do it safely."
  (unless (and (ghostel-point-on-cursor-row-p beg)
               (ghostel-point-on-cursor-row-p (max beg (1- end))))
    (user-error "The shell edits one line at a time: C-. e edits the input in a buffer")))

(defun suhas/terminal-click (fn event &rest args)
  "Around `ghostel-mouse-release-or-set-point': click to move the shell cursor.
FN runs first: it hands the click to a mouse-aware program, or sets
point. When point is now where you clicked, on the row you are typing on
\(insert state, or Vim keys off), the shell's cursor follows, so typing
and pasting happen there."
  (let ((clicked (posn-point (event-end event))))
    (apply fn event args)
    (when (and clicked
               (= (point) clicked)
               (= (event-click-count event) 1)
               (eq ghostel--input-mode 'semi-char)
               (not (and (bound-and-true-p evil-local-mode)
                         (not (eq evil-state 'insert))))
               (ghostel-point-on-cursor-row-p (point))
               (require 'evil-ghostel nil t))
      (evil-ghostel-goto-input-position (point)))))

;;; ============================================================
;;; THE PANEL — where terminal buffers are displayed
;;; ============================================================

(defun suhas/terminal-window ()
  "The window showing a terminal in this frame, or nil.
Found by its content, so there is no state to go stale."
  (seq-find (lambda (w) (suhas/terminal-buffer-p (window-buffer w)))
            (window-list nil 'no-minibuffer)))

(defun suhas/terminal--display (buffer alist)
  "`display-buffer' action: show terminal BUFFER in the terminal panel.
Reuses the window that already shows a terminal; otherwise splits the
whole frame below or right (`suhas/terminal-position'). The panel is
dedicated: a file you open while standing in it appears in an editing
window, never in place of the terminal."
  (let ((win (or (get-buffer-window buffer) (suhas/terminal-window))))
    (if win
        (progn (set-window-dedicated-p win nil)
               (window--display-buffer buffer win 'reuse alist))
      (setq win (display-buffer-in-direction
                 buffer
                 (append (if (eq suhas/terminal-position 'right)
                             `((direction . rightmost)
                               (window-width . ,suhas/terminal-width-fraction))
                           `((direction . bottom)
                             (window-height . ,suhas/terminal-height-fraction)))
                         alist))))
    (when win (set-window-dedicated-p win t))
    win))

;; Every way of showing a terminal buffer goes through the rule: ghostel's
;; own commands, SPC SPC, links, `pop-to-buffer' ...
(add-to-list 'display-buffer-alist
             '((derived-mode . ghostel-mode) (suhas/terminal--display)))
;; ... including plain `switch-to-buffer'. And switching to some other
;; buffer from inside the (dedicated) panel uses an editing window.
(setq switch-to-buffer-obey-display-actions t
      switch-to-buffer-in-dedicated-window 'pop)

(defun suhas/terminal--show (buffer)
  "Show terminal BUFFER in the panel, select it, ready to type."
  (pop-to-buffer buffer)
  (when (and (bound-and-true-p evil-local-mode)
             (not (memq evil-state '(insert emacs))))
    (evil-insert-state)))

;;; ============================================================
;;; TERMINALS OF THIS WORKSPACE
;;; ============================================================

(defun suhas/persp-terminal-buffers ()
  "This workspace's terminal buffers, most recently used first."
  (seq-filter (lambda (b) (and (suhas/terminal-buffer-p b)
                               (suhas/persp-buffer-p b)))
              (buffer-list)))

(defun suhas/terminal--ring ()
  "This workspace's terminal buffers in a stable order (by name)."
  (sort (suhas/persp-terminal-buffers)
        :key #'buffer-name :lessp #'string<))

(defun suhas/terminal--target ()
  "The terminal to act on: this buffer, else the one in the panel, else nil."
  (cond ((suhas/terminal-buffer-p (current-buffer)) (current-buffer))
        ((suhas/terminal-window) (window-buffer (suhas/terminal-window)))))

(defun suhas/terminal-new (&optional name)
  "SPC t n -- start a new terminal in the project root.
NAME (asked for interactively; empty = the project's name) goes into the
buffer name: *term:NAME*."
  (interactive
   (list (let ((n (read-string "Terminal name (empty = project): ")))
           (unless (string-empty-p n) n))))
  (let* ((default-directory (suhas/project-dir))
         (name (or name (file-name-nondirectory
                         (directory-file-name default-directory)))))
    (suhas/terminal--prepare-environment)
    (suhas/terminal--show
     (ghostel-create (format "*term:%s*" name) '(suhas/terminal--display)))))

(defun suhas/terminal-toggle ()
  "C-` / SPC t t -- go to this workspace's terminal; from it, hide the panel.
Creates the first terminal of a workspace on demand."
  (interactive)
  (cond
   ((suhas/terminal-buffer-p (current-buffer))
    (if (one-window-p)
        (progn
          (set-window-dedicated-p nil nil)
          (switch-to-buffer
         (or (seq-find (lambda (b)
                         (and (suhas/persp-buffer-p b)
                              (not (suhas/terminal-buffer-p b))
                              (not (string-prefix-p " " (buffer-name b)))))
                       (buffer-list))
             (get-scratch-buffer-create))))
      (delete-window)))
   ((suhas/terminal-window)
    (suhas/terminal--show (window-buffer (suhas/terminal-window))))
   ((suhas/persp-terminal-buffers)
    (suhas/terminal--show (car (suhas/persp-terminal-buffers))))
   (t (suhas/terminal-new))))

(defun suhas/terminal-switch ()
  "SPC t s -- pick one of this workspace's terminals by name."
  (interactive)
  (let ((bufs (suhas/persp-terminal-buffers)))
    (if (null bufs)
        (suhas/terminal-new)
      (suhas/terminal--show
       (completing-read "Terminal: " (mapcar #'buffer-name bufs) nil t)))))

(defun suhas/terminal-cycle (step)
  "Show the terminal STEP places along this workspace's ring (wraps)."
  (let* ((ring (suhas/terminal--ring))
         (pos (seq-position ring (suhas/terminal--target))))
    (cond ((null ring) (suhas/terminal-new))
          ((null pos) (suhas/terminal--show (car ring)))
          (t (suhas/terminal--show
              (nth (mod (+ pos step) (length ring)) ring))))))

(defun suhas/terminal-next ()
  "SPC t l -- next terminal of this workspace."
  (interactive)
  (suhas/terminal-cycle 1))

(defun suhas/terminal-prev ()
  "SPC t h -- previous terminal of this workspace."
  (interactive)
  (suhas/terminal-cycle -1))

(defun suhas/terminal-kill ()
  "SPC t k -- kill the current (or displayed) terminal.
The panel then shows another terminal of this workspace, or closes."
  (interactive)
  (let ((target (suhas/terminal--target)))
    (if (not target)
        (message "No terminal to kill")
      (let ((others (remq target (suhas/persp-terminal-buffers)))
            (win (get-buffer-window target))
            (kill-buffer-query-functions nil))
        (cond ((and others (window-live-p win))
               (display-buffer (car others)))
              ((and (window-live-p win) (not (one-window-p)))
               (delete-window win))
              ((window-live-p win)
               (set-window-dedicated-p win nil)))
        (kill-buffer target)))))

(defun suhas/terminal-kill-all ()
  "SPC t K -- kill every terminal of this workspace and close the panel."
  (interactive)
  (let ((bufs (suhas/persp-terminal-buffers))
        (win (suhas/terminal-window))
        (kill-buffer-query-functions nil))
    (when win
      (if (one-window-p)
          (set-window-dedicated-p win nil)
        (delete-window win)))
    (mapc #'kill-buffer bufs)
    (message "Killed %d terminal(s)" (length bufs))))

(defun suhas/terminal-rename (name)
  "SPC t r -- rename the current (or displayed) terminal to *term:NAME*."
  (interactive
   (list (if (suhas/terminal--target)
             (read-string "Rename terminal to: ")
           (user-error "No terminal to rename"))))
  (unless (string-empty-p name)
    (with-current-buffer (suhas/terminal--target)
      (rename-buffer (format "*term:%s*" name) t))))

(defun suhas/terminal-set-position (position)
  "SPC t p -- put the terminal panel `below' or `right', now and from now on."
  (interactive
   (list (intern (completing-read "Terminal position: " '("below" "right") nil t))))
  (setq suhas/terminal-position position)
  (when-let* ((win (suhas/terminal-window))
              (buf (window-buffer win))
              ((not (one-window-p))))
    (delete-window win)
    (suhas/terminal--show buf))
  (message "Terminal panel: %s" position))

;;; ============================================================
;;; TALKING TO WHATEVER RUNS IN THE TERMINAL
;;; ============================================================

(defun suhas/terminal-send ()
  "SPC t y -- paste into this workspace's terminal, then go there.
With a region: its text. Without: `path:line' of point. A bracketed paste,
so shells and coding agents receive it as one block and nothing runs
until you press RET."
  (interactive)
  (let ((text (if (use-region-p)
                  (string-trim-right
                   (buffer-substring-no-properties (region-beginning) (region-end))
                   "\n+")
                (suhas/location)))
        (term (or (and (suhas/terminal-window)
                       (window-buffer (suhas/terminal-window)))
                  (car (suhas/persp-terminal-buffers))
                  (user-error "No terminal in this workspace (SPC t t)"))))
    (deactivate-mark)
    (with-current-buffer term
      (ghostel-paste-string text))
    (suhas/terminal--show term)))

(defvar suhas/terminal--bell-buffer nil
  "The terminal that rang the bell most recently while you were elsewhere.")

(defun suhas/terminal-bell ()
  "A program rang the bell: if you are not looking at it, say so."
  (unless (ghostel-buffer-focused-p (current-buffer))
    (setq suhas/terminal--bell-buffer (current-buffer))
    (message "%s wants attention (SPC t a)" (buffer-name))))

(defun suhas/terminal-attention ()
  "SPC t a -- jump to the terminal that asked for attention.
First the one that rang the bell, otherwise the next terminal whose
program reported being blocked, done or failed."
  (interactive)
  (if (buffer-live-p suhas/terminal--bell-buffer)
      (let ((buf suhas/terminal--bell-buffer))
        (setq suhas/terminal--bell-buffer nil)
        (when (and (bound-and-true-p persp-mode)
                   (not (suhas/persp-buffer-p buf)))
          (persp-switch-to-buffer buf))
        (suhas/terminal--show buf))
    (ghostel-status-next)))

;;; ============================================================
;;; ENVIRONMENT — prompt, and Emacs as the editor
;;; ============================================================

(defun suhas/terminal--editor ()
  "emacsclient, as a path without spaces (Windows: 8.3 short name)."
  (let ((client (or (seq-find #'file-executable-p
                              (mapcar (lambda (n) (expand-file-name n invocation-directory))
                                      '("emacsclient" "emacsclient.exe")))
                    (executable-find "emacsclient"))))
    (when client
      (if (fboundp 'w32-short-file-name)
          (or (w32-short-file-name client) client)
        client))))

(defun suhas/terminal--prepare-environment ()
  "Set `ghostel-environment' before a terminal starts.
Starts the Emacs server (once, under a name only this Emacs uses), so
programs in the terminal open files in THIS Emacs: EDITOR and VISUAL
point at emacsclient. Adds the short prompt when `suhas/terminal-prompt'
is set."
  (require 'server)
  (let ((env nil)
        (editor (suhas/terminal--editor)))
    (when editor
      (unless (process-live-p server-process)
        (setq server-name (format "semacs-%d" (emacs-pid)))
        (let ((inhibit-message t)) (server-start)))
      (when (process-live-p server-process)
        (push (concat "EDITOR=" editor) env)
        (push (concat "VISUAL=" editor) env)
        (push (if server-use-tcp
                  (concat "EMACS_SERVER_FILE="
                          (expand-file-name server-name server-auth-dir))
                (concat "EMACS_SOCKET_NAME="
                        (expand-file-name server-name server-socket-dir)))
              env)))
    (when suhas/terminal-prompt
      ;; Runs before every prompt (bash). The window title keeps the
      ;; context (Git Bash: MINGW64:/c/...; else user@host:dir); ghostel
      ;; shows it in the modeline.
      (push (format "PROMPT_COMMAND=PS1='\\[\\e]0;${TITLEPREFIX:-\\u@\\h}:$PWD\\a\\]%s'"
                    suhas/terminal-prompt)
            env))
    (setq ghostel-environment env)))

(defvar-local suhas/terminal--edit-origin nil
  "The terminal buffer that asked for this file to be edited (server).")

(defun suhas/terminal--edit-setup ()
  "A program in a terminal opened this file: C-c C-c finishes, C-c C-k aborts."
  (let ((origin (window-buffer (selected-window))))
    (when (suhas/terminal-buffer-p origin)
      (setq suhas/terminal--edit-origin origin)))
  (local-set-key (kbd "C-c C-c") #'suhas/terminal-edit-finish)
  (local-set-key (kbd "C-c C-k") #'suhas/terminal-edit-abort)
  (message "C-c C-c (or :wq) to finish, C-c C-k to abort"))

(defun suhas/terminal-edit-finish ()
  "Save and hand the file back to the program that asked for it."
  (interactive)
  (save-buffer)
  (server-edit))

(defun suhas/terminal-edit-abort ()
  "Discard the edit: the program gets an error, so nothing runs."
  (interactive)
  (let ((term suhas/terminal--edit-origin))
    (server-edit-abort)
    (when (buffer-live-p term)
      (run-at-time 0 nil #'suhas/terminal--show term))))

(defun suhas/terminal--edit-return ()
  "After a terminal program's file is done, go back to that terminal."
  (when (buffer-live-p suhas/terminal--edit-origin)
    (let ((term suhas/terminal--edit-origin))
      (run-at-time 0 nil #'suhas/terminal--show term))))

(add-hook 'server-visit-hook #'suhas/terminal--edit-setup)
(add-hook 'server-done-hook #'suhas/terminal--edit-return)

(defun suhas/terminal-edit-input ()
  "C-. e -- edit the shell's current command line in an Emacs buffer.
Sends bash's edit-and-execute key (C-x C-e). The shell runs the command
when you finish (C-c C-c), like bash does. In Claude Code use Ctrl+G."
  (interactive)
  (let ((term (or (suhas/terminal--target)
                  (user-error "No terminal in this workspace"))))
    (with-current-buffer term
      (ghostel--send-string "\C-x\C-e"))))

;;; ============================================================
;;; KEYS
;;; ============================================================

(defvar-keymap suhas/terminal-map
  :doc "Terminal commands: C-. anywhere, SPC t in Evil states."
  "t" #'suhas/terminal-toggle
  "n" #'suhas/terminal-new
  "s" #'suhas/terminal-switch
  "l" #'suhas/terminal-next
  "h" #'suhas/terminal-prev
  "r" #'suhas/terminal-rename
  "k" #'suhas/terminal-kill
  "K" #'suhas/terminal-kill-all
  "p" #'suhas/terminal-set-position
  "y" #'suhas/terminal-send
  "a" #'suhas/terminal-attention
  "e" #'suhas/terminal-edit-input)

(keymap-set suhas/leader-map "t" (cons "terminal" suhas/terminal-map))

;; Every state, also while typing in a terminal. (Terminal Emacs cannot
;; send C-. or C-`: use C-c t and C-c SPC t there.)
(keymap-global-set "C-." (cons "terminal" suhas/terminal-map))
(keymap-global-set "C-`" #'suhas/terminal-toggle)
(keymap-global-set "C-c t" #'suhas/terminal-toggle)

;;; terminal.el ends here

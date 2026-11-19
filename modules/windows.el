;;; windows.el --- Everything Windows-specific  -*- lexical-binding: t; -*-
;;;
;;; Loaded by init.el on native Windows only, between settings.el and
;;; local.el. No other module contains Windows code.
;;;
;;; TO DROP WINDOWS SUPPORT: delete this file and the one line in init.el
;;; that loads it. Nothing else changes.
;;;
;;; Two halves:
;;;   1. DEFAULTS    run now, so local.el can still override them.
;;;   2. SETUP       `suhas/windows-setup', run after local.el (through
;;;                  `suhas/platform-setup-hook'), so it sees your overrides.

;;; ============================================================
;;; 1. DEFAULTS
;;; ============================================================

(defvar suhas/git-for-windows-root
  (expand-file-name "Git" (or (getenv "ProgramFiles") "C:/Program Files"))
  "Where Git for Windows is installed.
Its bash is what the terminal and `compile' use.")

(defvar suhas/windows-use-git-bash t
  "Use Git Bash as `shell-file-name' (M-x compile, shell-command).")

(defvar suhas/clangd-query-driver
  (let ((p "C:/msys64/ucrt64/bin/g++.exe"))
    (and (file-exists-p p) p))
  "Compiler clangd may query for system include paths (MinGW/MSYS2).
nil = pass nothing. Auto-detected for a default MSYS2 UCRT64 install.")

(setq suhas/font-family "Iosevka NF"
      ;; Windows sends wheel clicks without pixel data: no pixel scrolling.
      suhas/pixel-scroll nil
      ;; Windows Emacs already has the real PATH. Importing one from a
      ;; (Git Bash) login shell would replace it with Unix-style paths and
      ;; git, rg and fd would no longer be found.
      suhas/shell-env-variables nil
      suhas/terminal-height-fraction 0.34
      ;; The gpg Emacs finds here (Git's MSYS gpg) mangles Windows keyring
      ;; paths, so verification can never succeed. Downloads still use HTTPS.
      suhas/package-check-signature nil)

;;; ============================================================
;;; 2. SETUP (after local.el)
;;; ============================================================

(defun suhas/windows--prepend-path (&rest dirs)
  "Put DIRS at the front of `exec-path' and PATH, without duplicates."
  (dolist (dir (reverse dirs))
    (setq exec-path (cons dir (delete dir exec-path))))
  (setenv "PATH"
          (mapconcat #'identity
                     (delete-dups
                      (append (mapcar (lambda (d) (subst-char-in-string ?/ ?\\ d)) dirs)
                              (split-string (or (getenv "PATH") "") ";" t)))
                     ";")))

(defun suhas/windows-scratch-to-home ()
  "Give *scratch* the home directory as `default-directory'."
  (when-let* ((scratch (get-buffer "*scratch*")))
    (with-current-buffer scratch
      (setq default-directory (file-name-as-directory (expand-file-name "~"))))))

(defun suhas/windows-setup ()
  "Apply the Windows-specific parts of the config."
  ;; A shortcut-launched Emacs starts in its installation directory.
  (when (string-prefix-p (expand-file-name invocation-directory) default-directory)
    (setq default-directory (file-name-as-directory (expand-file-name "~"))))
  (add-hook 'emacs-startup-hook #'suhas/windows-scratch-to-home)

  ;; A cache written before this was Windows-aware must never be read.
  (let ((cache (expand-file-name "env-cache.el" user-emacs-directory)))
    (when (file-exists-p cache) (delete-file cache)))

  (let* ((root suhas/git-for-windows-root)
         (bash (expand-file-name "usr/bin/bash.exe" root)))
    (when (file-directory-p root)
      ;; cmd         git itself (package.el needs it for :vc packages)
      ;; usr/bin     ls, grep, sed ...
      ;; mingw64/bin runtime DLLs
      (suhas/windows--prepend-path (expand-file-name "cmd" root)
                                   (expand-file-name "usr/bin" root)
                                   (expand-file-name "mingw64/bin" root))
      (when (file-exists-p bash)
        ;; Terminal: Git Bash as a login shell. Emacs starts bash directly,
        ;; so set what Git Bash's own launcher would have set.
        (setq ghostel-shell (list bash "--login" "-i"))
        (setenv "MSYSTEM" "MINGW64")
        (setenv "CHERE_INVOKING" "1")
        (when suhas/windows-use-git-bash
          (setq shell-file-name (expand-file-name "bin/bash.exe" root)
                shell-command-switch "-c")))))

  ;; New files get LF line endings.
  (prefer-coding-system 'utf-8-unix)

  ;; Pipes: the default buffer is tiny, and fd/rg restarted on every
  ;; keystroke pile up. Slow consult's async commands down a little.
  (setq w32-pipe-buffer-size (* 64 1024)
        consult-async-input-debounce 0.4
        consult-async-input-throttle 0.6)

  (when suhas/clangd-query-driver
    (add-to-list 'suhas/lsp-server-overrides
                 `((c-mode c-ts-mode c++-mode c++-ts-mode)
                   "clangd" ,(concat "--query-driver=" suhas/clangd-query-driver))
                 t)))

(add-hook 'suhas/platform-setup-hook #'suhas/windows-setup)

;;; windows.el ends here

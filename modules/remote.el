;;; remote.el --- Remote and container development (TRAMP)  -*- lexical-binding: t; -*-
;;;
;;; Open a remote file with C-x C-f /ssh:host:/path/file  (or SPC f f).
;;; Containers:  /docker:CONTAINER:/path   /podman:CONTAINER:/path
;;; As root:     /sudo::/etc/hosts
;;; magit, project.el and M-x compile work over TRAMP. Language servers are
;;; not started automatically on remote files; run M-x eglot when you want one.

;; Plain `setq's: TRAMP itself loads when you first open a remote file.
(setq tramp-default-method "ssh"
      ;; 1 = errors only; the default fills the echo area with progress.
      tramp-verbose 1
      ;; TRAMP asks the remote host constantly (does this file exist? is it
      ;; a repo?). A short cache removes most round trips.
      remote-file-name-inhibit-cache 10
      ;; Lock files and auto-save over the network are pure latency.
      remote-file-name-inhibit-locks t
      remote-file-name-inhibit-auto-save-visited t
      ;; Small files travel inline; bigger ones use scp.
      tramp-copy-size-limit (* 1024 1024))

;;; remote.el ends here

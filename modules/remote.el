;;; remote.el --- Remote and container development (TRAMP)  ... -*- lexical-binding: t; -*-
;;;
;;; Open a remote file with C-x C-f /ssh:host:/path/file  (or SPC f f).
;;; Containers:  /docker:CONTAINER:/path   /podman:CONTAINER:/path
;;; As root:     /sudo::/etc/hosts
;;; Eglot, magit, project.el and compile all work over TRAMP (a bit slower).

(use-package tramp
  :ensure nil
  :defer t
  :custom
  (tramp-default-method "ssh")
  ;; 1 = errors only; the default (3) fills the echo area with progress.
  (tramp-verbose 1))

;; TRAMP queries the remote host constantly (is this a git repo? does this
;; file exist?). A short cache removes most of that without staleness you
;; would notice. Lock files over the network are pure latency, so skipped.
(setq remote-file-name-inhibit-cache 10
      remote-file-name-inhibit-locks t)

;;; remote.el ends here

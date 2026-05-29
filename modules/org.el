;;; org.el --- Org-mode with task management

(use-package org
  :ensure nil  ; Built-in
  :custom
  (org-directory "~/org")
  (org-default-notes-file "~/org/notes.org")
  (org-agenda-files '("~/org"))
  (org-capture-templates
   '(("t" "Task" entry (file+headline "~/org/tasks.org" "Inbox")
      "* TODO %?\n  %i\n  %a")
     ("n" "Note" entry (file+headline "~/org/notes.org" "Notes")
      "* %?\n  %U\n  %i")))
  (org-todo-keywords
   '((sequence "TODO" "IN-PROGRESS" "|" "DONE" "CANCELLED")))
  (org-log-done 'time))

(add-hook 'org-mode-hook
          (lambda ()
            (org-indent-mode 1)
            (visual-line-mode 1)
            (display-line-numbers-mode 0)))

;;; org.el ends here

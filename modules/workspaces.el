;;; workspaces.el --- Workspaces via tab-bar + project.el
;;; Both are built into Emacs 27+. Zero extra packages needed.
;;;
;;; Mental model:
;;; tab-bar  = workspaces (one tab per project or context)
;;; project  = project awareness (root detection, file search, grep)
;;; Together: each tab is a workspace scoped to one project.

;;; ============================================================
;;; SECTION 1: TAB-BAR — WORKSPACES
;;; ============================================================

(use-package tab-bar
  :ensure nil                         ; Built-in
  :custom
  (tab-bar-show 1)                    ; Show tab bar only when >1 tab exists
  (tab-bar-close-button-show nil)     ; No X button on tabs — use keybinding
  (tab-bar-new-button-show nil)       ; No + button — use keybinding
  (tab-bar-tab-hints t)               ; Show tab numbers (1, 2, 3...)
  (tab-bar-format                     ; What each tab displays
   '(tab-bar-format-tabs              ; Tab names
     tab-bar-separator))

  :config
  (tab-bar-mode 1))

(setq tab-bar-format '(tab-bar-format-tabs))
(setq tab-bar-tab-name-truncated-max 15)  ; max chars in tab name
(setq tab-bar-tab-name-function #'tab-bar-tab-name-truncated)
(setq tab-bar-tab-hints nil) ; Optional: show numbers to save space
(setq tab-bar-separator " ")  ; minimal separator between tabs

;;; ============================================================
;;; SECTION 2: PROJECT.EL — PROJECT AWARENESS
;;; ============================================================

(use-package project
  :ensure nil                         ; Built-in
  :custom
  ;; project.el detects project root by looking for .git, .project etc.
  ;; Store project list so recently opened projects are remembered.
  (project-list-file
   (expand-file-name "projects" user-emacs-directory))

  :config
  ;; Open a new tab for each project automatically.
  ;; When you switch project, a dedicated tab opens for it.
  (defun suhas/project-open-in-tab (project)
    "Switch to or create a tab for PROJECT."
    (interactive (list (project-prompt-project-dir)))
    (let* ((name (file-name-nondirectory
                  (directory-file-name project)))
           (tab (seq-find (lambda (tab)
                            (equal (alist-get 'name tab) name))
                          (tab-bar-tabs))))
      (if tab
          (tab-bar-switch-to-tab name)   ; Tab exists — switch to it
        (tab-bar-new-tab)                ; New tab
        (tab-bar-rename-tab name)        ; Name it after the project
        (project-switch-project project)))))

;;; workspaces.el ends here

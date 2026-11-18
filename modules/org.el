;;; org.el --- Org: notes, TODOs, agenda, and the org-roam wiki  -*- lexical-binding: t; -*-
;;;
;;; Lean on purpose: org (built in) plus org-roam, nothing cosmetic.
;;; Neither loads at startup. Org loads with the first .org file or
;;; SPC o a / SPC o c; org-roam loads with its first command, or when you
;;; open a note inside the roam folder. A README.org in a work repo never
;;; touches org-roam or its database.
;;;
;;; Cheat sheet at the bottom of this file.

;;; ============================================================
;;; ORG
;;; ============================================================

(use-package org
  :ensure nil
  :custom
  (org-directory suhas/org-directory)
  (org-default-notes-file (expand-file-name "notes.org" suhas/org-directory))
  ;; The agenda (SPC o a) scans every .org file in the folder.
  (org-agenda-files (list suhas/org-directory))
  ;; "|" separates not-done states from done states.
  (org-todo-keywords '((sequence "TODO" "IN-PROGRESS" "|" "DONE" "CANCELLED")))
  (org-log-done 'time)
  ;; SPC o c, then t or n.
  (org-capture-templates
   `(("t" "Task" entry (file+headline ,(expand-file-name "tasks.org" suhas/org-directory) "Inbox")
      "* TODO %?\n  %i\n  %a")
     ("n" "Note" entry (file+headline ,(expand-file-name "notes.org" suhas/org-directory) "Notes")
      "* %?\n  %U\n  %i")))
  ;; Text under a heading is shown indented (display only, not in the file).
  (org-startup-indented t)
  (org-cycle-separator-lines 1)
  (org-ellipsis " …"))

(defun suhas/org-buffer-setup ()
  "Prose defaults for org buffers; load org-roam for notes in the roam folder."
  (display-line-numbers-mode 0)
  (when (and buffer-file-name
             (file-in-directory-p buffer-file-name suhas/org-roam-directory))
    (require 'org-roam nil t)))
(add-hook 'org-mode-hook #'suhas/org-buffer-setup)

;; Vim-style structure editing, and TAB for folding (Evil's normal state
;; claims TAB for jump-forward; inside org it folds again).
(with-eval-after-load 'evil
  (with-eval-after-load 'org
    (evil-define-key* '(normal insert) org-mode-map
      (kbd "M-h") #'org-metaleft
      (kbd "M-l") #'org-metaright
      (kbd "M-j") #'org-metadown
      (kbd "M-k") #'org-metaup
      (kbd "TAB") #'org-cycle
      (kbd "<tab>") #'org-cycle)))

;;; ============================================================
;;; ORG-ROAM — wiki-style notes with backlinks
;;; ============================================================

(defconst suhas/org-roam-directory
  (file-name-as-directory
   (file-truename (expand-file-name "roam" suhas/org-directory)))
  "Where org-roam notes live: the roam/ folder inside `suhas/org-directory'.")

(use-package org-roam
  :commands (org-roam-node-find org-roam-node-insert org-roam-buffer-toggle
             org-roam-capture org-roam-graph)
  :custom
  (org-roam-directory suhas/org-roam-directory)
  ;; One timestamped file per note; the title you typed becomes #+title.
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)))
  ;; No garbage collection in the middle of a database sync.
  (org-roam-db-gc-threshold most-positive-fixnum)
  :config
  (make-directory org-roam-directory t)
  ;; Keeps the index in step with the files; incremental after the first run.
  (org-roam-db-autosync-mode 1))

(suhas/leader
 "o"     "org"
 "o a"   #'org-agenda
 "o c"   #'org-capture
 "o l"   #'org-store-link
 "o i"   #'org-insert-link
 "o t"   #'org-todo
 "o s"   #'org-schedule
 "o d"   #'org-deadline
 "o o"   #'org-toggle-narrow-to-subtree
 "o r"   "roam"
 "o r f" #'org-roam-node-find
 "o r i" #'org-roam-node-insert
 "o r b" #'org-roam-buffer-toggle
 "o r c" #'org-roam-capture
 "o r g" #'org-roam-graph)

;;; ============================================================
;;; CHEAT SHEET
;;; ============================================================
;;
;; STRUCTURE
;;   TAB / S-TAB       fold heading at point / the whole buffer
;;   M-RET             new heading at the same level
;;   M-h / M-l         promote / demote      M-j / M-k   move down / up
;;
;; TODOS
;;   SPC o t           cycle TODO state      SPC o s / d  schedule / deadline
;;   SPC o a           agenda                SPC o c      capture a task or note
;;
;; LINKS
;;   SPC o l           store a link to where you are
;;   SPC o i           insert a stored link   gx  follow   C-c &  jump back
;;
;; ORG-ROAM (one small note per idea, linked together)
;;   SPC o r f         find a note by title, or create it
;;   SPC o r i         insert a link to another note (creates it if new)
;;   SPC o r b         backlinks side window: what links to this note
;;   SPC o r c         capture into a new note without leaving your place
;;   SPC o r g         link graph in the browser (needs graphviz `dot')
;;
;; MARKUP    *bold*  /italic/  _underline_  =verbatim=  ~code~  +strike+
;; TABLES    type | a | b | and press TAB
;; CODE      #+begin_src python ... #+end_src ; C-c C-c runs the block

;;; org.el ends here

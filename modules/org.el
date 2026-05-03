;;; org.el --- Org mode: notes, documents, and live code blocks
;;; Org is a superset of markdown with executable code blocks,
;;; task management, and export to HTML/PDF/LaTeX.

;;; ============================================================
;;; SECTION 1: ORG CORE
;;; ============================================================

(use-package org
  :ensure nil                         ; Built-in
  :hook
  (org-mode . org-indent-mode)        ; Indent content under headings
  (org-mode . visual-line-mode)       ; Wrap long lines visually
  (org-mode . (lambda ()
                (display-line-numbers-mode 0))) ; No line numbers in org

  :custom
  ;; Visual
  (org-ellipsis " ▾")                 ; Collapsed heading indicator
  (org-hide-emphasis-markers t)       ; Hide *bold* markers, show bold
  (org-pretty-entities t)             ; Render \alpha as α etc.
  (org-startup-folded 'content)       ; Open files showing headings only

  ;; Source blocks
  (org-src-fontify-natively t)        ; Syntax highlight code blocks
  (org-src-tab-acts-natively t)       ; TAB indents like the language would
  (org-src-window-setup 'current-window) ; Edit src block in same window
  (org-confirm-babel-evaluate nil)    ; Don't ask before running code blocks
  (org-edit-src-content-indentation 0); No extra indent inside src blocks

  ;; Export
  (org-export-with-smart-quotes t)
  (org-export-with-toc t)
  (org-export-with-section-numbers nil)

  ;; Misc
  (org-return-follows-link t)         ; RET follows links
  (org-image-actual-width '(400)))    ; Inline images max 400px wide

;;; ============================================================
;;; SECTION 2: ORG BABEL — RUNNING CODE BLOCKS
;;; ============================================================

;; Babel lets you execute code blocks inside org files.
;; #+begin_src python ... #+end_src → C-c C-c to run it.
;; Results appear inline below the block.

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (python     . t)
     (js         . t)
     (C          . t)           ; Covers both C and C++
     (java       . t)
     (shell      . t)           ; Bash/sh blocks
     (sql        . t)
     (org        . t))))

;; Python 3 for babel
(setq org-babel-python-command "python3")

;;; ============================================================
;;; SECTION 3: ORG MODERN — VISUAL POLISH
;;; ============================================================

;; org-modern replaces org's ASCII indicators with clean Unicode symbols.
;; * headings get bullets, TODO gets a pill badge, tables look cleaner.
;; Purely visual — doesn't change org files on disk.

(use-package org-modern
  :ensure t
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-star '("◉" "○" "✸" "✿")) ; Heading bullets per level
  (org-modern-table t)
  (org-modern-block-fringe nil))

;;; ============================================================
;;; SECTION 4: ORG TEMPO — QUICK BLOCK INSERTION
;;; ============================================================

;; Org-tempo lets you type <py TAB and get a Python src block.
;; Built-in to org — just needs requiring.

(with-eval-after-load 'org
  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("py"  . "src python"))
  (add-to-list 'org-structure-template-alist '("js"  . "src js"))
  (add-to-list 'org-structure-template-alist '("c"   . "src C"))
  (add-to-list 'org-structure-template-alist '("cpp" . "src C++ :includes <iostream>"))
  (add-to-list 'org-structure-template-alist '("sh"  . "src shell"))
  (add-to-list 'org-structure-template-alist '("el"  . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("jv"  . "src java")))

;;; ============================================================
;;; SECTION 5: EVIL IN ORG
;;; ============================================================

;; Org and Evil conflict on TAB and RET.
;; We fix these explicitly rather than using evil-collection.

(with-eval-after-load 'evil
  (evil-define-key 'normal org-mode-map
    (kbd "TAB")   #'org-cycle           ; Fold/unfold heading
    (kbd "RET")   #'org-open-at-point   ; Follow link or open
    (kbd "g h")   #'org-up-heading-safe ; Go to parent heading
    (kbd "g j")   #'org-next-visible-heading
    (kbd "g k")   #'org-previous-visible-heading
    (kbd "g l")   #'org-next-link       ; Jump to next link
    (kbd "t")     #'org-todo))          ; Cycle TODO state


;;; org.el ends here

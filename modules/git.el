;;; git.el --- Git workflow via Magit
;;; Magit is the best Git interface ever built, in any editor.
;;; You will stop using the terminal for git after a week of this.

;;; ============================================================
;;; SECTION 1: MAGIT
;;; ============================================================
;; Force elpaca to fetch transient from MELPA directly.
;; Magit requires transient >= 0.12, the default source is stale.
(use-package transient
  :ensure t)

(use-package magit
  :ensure t
  :commands magit-status
  :custom
  (magit-display-buffer-function
   #'magit-display-buffer-same-window-except-diff-v1)
  ;; Opens magit in the same window instead of splitting.
  ;; Diff still opens in a split — that's the exception.

  (git-commit-summary-max-length 72)  ; Git convention: 72 char limit
  (magit-save-repository-buffers nil) ; Don't ask to save before git ops

  :config
  ;; Show word-level diff highlighting inside hunks.
  ;; Makes it immediately obvious what changed within a line.
  (setq magit-diff-refine-hunk t))

;;; ============================================================
;;; SECTION 2: GIT-GUTTER — INLINE CHANGE INDICATORS
;;; ============================================================

;; Shows +/~/- in the fringe (left margin) for added/modified/deleted lines.
;; You see your changes live as you edit without opening magit.
;; Essential for knowing where you are in a diff while coding.

(use-package git-gutter
  :ensure t
  :hook (prog-mode . git-gutter-mode)
  :custom
  (git-gutter:update-interval 0.5)    ; Refresh every 500ms
  (git-gutter:added-sign "+")
  (git-gutter:modified-sign "~")
  (git-gutter:deleted-sign "-"))

;;; ============================================================
;;; SECTION 3: MAGIT KEYBINDINGS
;;; ============================================================

;; Core magit workflow — you only need these to start:
;;
;;   SPC g g    → open magit status (your git dashboard)
;;
;; Inside magit status:
;;   s          → stage file/hunk under cursor
;;   u          → unstage
;;   c c        → commit (opens commit message buffer)
;;   P p        → push
;;   F p        → pull
;;   b b        → switch branch
;;   b c        → create branch
;;   TAB        → expand/collapse diff hunk
;;   q          → quit magit


;;; git.el ends here

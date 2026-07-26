;;; org.el --- Org-mode: notes, TODOs, agenda, and wiki-style cross-linking
;;;
;;; This file is written to be READ, not just loaded. Every section explains
;;; the underlying Org concept before the code that implements it. If you
;;; forget a shortcut in six months, come back and reread this file — that's
;;; what it's for.
;;;
;;; TABLE OF CONTENTS
;;;   1. Core org settings (files, TODO states, capture, agenda)
;;;   2. Editing/writing quality-of-life (indent, visual-line, pretty bullets)
;;;   3. Evil + Org keybindings (leader-key map, "SPC o ...")
;;;   4. LINKING — org-store-link / org-insert-link (built-in, manual links)
;;;   5. ORG-ROAM — the actual Obsidian-style wiki (auto-linking, backlinks)
;;;   6. Cheat sheet (read this section whenever you forget a shortcut)
;;;
;;; ============================================================

;;; ============================================================
;;; 1. CORE ORG SETTINGS
;;; ============================================================

;; WHAT IS ORG-DIRECTORY?
;; It's just "the folder where your notes live." Nothing magic — org-mode
;; doesn't require a database or special file format. Every *.org file is a
;; plain text file you could open in any editor. Org just adds structure
;; on top of plain text (headings, lists, code blocks, tables, links).

(use-package org
  :ensure nil ; built-in, ships with Emacs
  :custom
  (org-directory "~/org")
  (org-default-notes-file "~/org/notes.org")

  ;; org-agenda-files tells the agenda view (SPC o a) which files to scan
  ;; for TODOs and scheduled/deadline items. Anything in ~/org will be
  ;; picked up automatically — you don't need to list files one by one.
  (org-agenda-files '("~/org"))

  ;; TODO KEYWORDS — the words that can appear after "* " in a headline.
  ;; The "|" separates "not-done" states (left) from "done" states (right).
  ;; Example headline using these:  * IN-PROGRESS Write org.el docs
  (org-todo-keywords
   '((sequence "TODO" "IN-PROGRESS" "|" "DONE" "CANCELLED")))

  ;; When you mark something DONE, stamp it with the current time.
  ;; Lets you later ask "when did I actually finish this?"
  (org-log-done 'time)

  ;; CAPTURE TEMPLATES — pre-defined "shapes" for quickly jotting something
  ;; down without leaving whatever you're doing. Triggered with SPC o c,
  ;; then you pick a template by its key ("t" or "n" below).
  (org-capture-templates
   '(("t" "Task" entry (file+headline "~/org/tasks.org" "Inbox")
      "* TODO %?\n  %i\n  %a")
     ("n" "Note" entry (file+headline "~/org/notes.org" "Notes")
      "* %?\n  %U\n  %i")))

  ;; When you press TAB on a heading with sub-items, cycle between
  ;; collapsed / children-visible / fully expanded. This is Org's
  ;; native "folding," similar to code folding in an IDE.
  (org-cycle-separator-lines 1))

(add-hook 'org-mode-hook
          (lambda ()
            (org-indent-mode 1)     ; indent text under headings visually
            (visual-line-mode 1)    ; wrap long lines instead of truncating
            (display-line-numbers-mode 0))) ; line numbers are noise in prose

;;; ============================================================
;;; 2. WRITING QUALITY-OF-LIFE
;;; ============================================================

;; org-appear: normally Org HIDES the markup characters for bold/italic/
;; links once your cursor leaves them (so *bold* renders as bold, not with
;; visible asterisks). org-appear reveals the raw markup again the moment
;; your cursor moves onto that text, so you can edit it. Without this,
;; editing a link's target is fiddly because you can't see the raw text.
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autoemphasis t)
  (org-appear-autosubmarkers t))

;; org-superstar: replaces the plain "*" heading stars with nicer looking
;; unicode bullets. Purely cosmetic, but it makes deeply nested notes much
;; easier to scan visually.
(use-package org-superstar
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("●" "◉" "◎" "○" "✸" " ▶")))

;;; ============================================================
;;; 3. EVIL + ORG KEYBINDINGS
;;; ============================================================

;; These extend the SPC leader map you already defined in evil.el.
;; Grouped under "o" for Org. Anything Org-specific lives here, not in
;; evil.el, so this file is self-contained and portable.

;; NOTE: this hooks on 'evil, not 'general. suhas/leader is defined inside
;; evil.el's (use-package general :config ...) block, and that whole block
;; runs as a single callback attached to 'evil loading. general itself
;; becomes "loaded" partway through that block (before suhas/leader is
;; actually defined), so hooking on 'general here would race and fail with
;; "void-function suhas/leader". Hooking on 'evil instead guarantees
;; evil.el's entire callback — including the definer — finishes first,
;; since this file loads after evil.el and callbacks run in registration order.
(with-eval-after-load 'evil
  (suhas/leader
    ;; ── Agenda / capture (already existed, kept here as one source of truth)
    "o a" #'org-agenda            ; SPC o a — open the agenda dashboard
    "o c" #'org-capture           ; SPC o c — capture a quick task/note

    ;; ── Linking (see section 4 below for what these actually do)
    "o l" #'org-store-link        ; SPC o l — remember current location as a link target
    "o i" #'org-insert-link       ; SPC o i — insert/paste a stored link here

    ;; ── TODO state / scheduling, used constantly while note-taking
    "o t" #'org-todo              ; SPC o t — cycle TODO -> IN-PROGRESS -> DONE
    "o s" #'org-schedule          ; SPC o s — attach a SCHEDULED date
    "o d" #'org-deadline          ; SPC o d — attach a DEADLINE date

    ;; ── Structure editing
    "o o" #'org-toggle-narrow-to-subtree)) ; zoom into just the current subtree

;; Evil already understands most Org motions well (gj/gk for visual lines,
;; TAB for folding), but a few Org-native bindings are worth remapping
;; explicitly to Vim-style h/j/k/l muscle memory instead of Org's default
;; arrow-key bindings.
;; Guard on BOTH packages: evil-define-key is defined by `evil`, and
;; org-mode-map is defined by `org`. org is built-in and loads immediately
;; during init (long before evil-mode is turned on from emacs-startup-hook),
;; so gating on 'org alone fires this before `evil` package ever exists —
;; that's what caused "void-function evil-define-key". Nesting both guards
;; means this only runs once both symbols genuinely exist, no matter which
;; package happens to load first.
(with-eval-after-load 'evil
  (with-eval-after-load 'org
    (evil-define-key '(normal insert) org-mode-map
      (kbd "M-h") #'org-metaleft   ; promote heading / move item left
      (kbd "M-l") #'org-metaright  ; demote heading / move item right
      (kbd "M-j") #'org-metadown   ; move heading/item down
      (kbd "M-k") #'org-metaup)    ; move heading/item up

    ;; TAB vs S-TAB asymmetry fix.
    ;; Evil implements vim states as MINOR modes, and minor-mode keymaps
    ;; are always checked before major-mode keymaps (org-mode-map is a
    ;; major-mode map). evil-normal-state-map claims plain TAB globally
    ;; for `evil-jump-forward` (vim's C-i jump-forward — historically the
    ;; same ASCII code as Tab, so vim binds them together). That claim
    ;; wins over Org's own TAB -> org-cycle binding, so folding breaks.
    ;; S-TAB is a distinct key event Evil never touches, which is why
    ;; org-shifttab (overview/contents/show-all) kept working fine.
    ;; Explicitly rebinding TAB here, inside org-mode-map, for evil's
    ;; normal/insert states restores org-cycle without breaking
    ;; evil-jump-forward anywhere else (it's untouched outside org-mode).
    (evil-define-key '(normal insert) org-mode-map
      (kbd "TAB")   #'org-cycle
      (kbd "<tab>") #'org-cycle)))

;;; ============================================================
;;; 4. LINKING (BUILT-IN) — how Org links actually work
;;; ============================================================

;; This is the mechanism UNDER org-roam (section 5). Understanding it first
;; will make org-roam feel obvious instead of magic.
;;
;; An Org link looks like this in the raw text:
;;     [[file:~/org/notes.org::*Some Heading][Some Heading]]
;;     [[id:9b1f2c3a-...][My Other Note]]
;;     [[https://example.com][Example]]
;;
;; The format is [[TARGET][DESCRIPTION]]. TARGET is where it goes,
;; DESCRIPTION is what you see rendered. Org hides the TARGET and brackets
;; visually and just shows DESCRIPTION as clickable-looking text.
;;
;; THE TWO-STEP WORKFLOW (manual linking, no org-roam needed):
;;   1. Go to the heading/file/line you want to link TO.
;;      Press SPC o l  (org-store-link). This doesn't insert anything —
;;      it just remembers "this place" on an internal stack.
;;   2. Go to where you want the link to APPEAR (could be a different file).
;;      Press SPC o i  (org-insert-link). It offers everything you've
;;      stored, plus lets you type a raw link manually.
;;
;; Following a link: put cursor on it and press "gx" (Evil) or C-c C-o
;; (default Org). Going back: "C-c &" (org-mark-ring-goto).
;;
;; This built-in system is enough for casual cross-referencing between a
;; handful of files. It gets tedious once you have 50+ notes because YOU
;; have to remember what to link to and where things are. That's the exact
;; problem org-roam solves — see section 5.

;;; ============================================================
;;; 5. ORG-ROAM — the Obsidian-style wiki
;;; ============================================================

;; WHAT ORG-ROAM ADDS ON TOP OF PLAIN ORG LINKS:
;;
;; 1. EVERY NOTE GETS A STABLE ID. Instead of linking to a filename (which
;;    breaks if you rename the file) you link to a permanent ID that
;;    survives renames.
;;
;; 2. BACKLINKS. This is the actual "wiki" feeling. If note B links to
;;    note A, then opening note A shows you "B links here" automatically,
;;    without you doing anything in A. Obsidian and Roam Research call
;;    this the "graph" — org-roam gives you the same thing as a plain
;;    text list at the bottom of the buffer (org-roam-buffer).
;;
;; 3. A SEARCHABLE INDEX (a local SQLite database) so "find the note about
;;    X" is instant even across thousands of files, instead of grepping.
;;
;; 4. FAST NOTE CREATION. org-roam-node-find lets you type a note title;
;;    if it exists you jump to it, if it doesn't you create it on the
;;    spot. This single command is 90% of the "just start writing and
;;    link as you go" workflow that makes wiki-style notes actually
;;    get used instead of abandoned.
;;
;; This needs sqlite (Emacs 29+ ships a built-in sqlite3 binding, so you
;; likely don't need to install anything extra).

(use-package org-roam
  :after org
  :custom
  ;; Where roam notes live. Can be the same as org-directory or a
  ;; subfolder — using a subfolder keeps roam notes separate from
  ;; tasks.org/notes.org above.
  (org-roam-directory (file-truename "~/org/roam"))

  ;; org-roam normally asks you to confirm the database sync on first
  ;; use of certain commands. This silences that one-time prompt.
  (org-roam-v2-ack t)

  :init
  ;; Make sure the roam directory actually exists before org-roam tries
  ;; to scan it — avoids a confusing error on a fresh machine.
  (make-directory (file-truename "~/org/roam") t)

  :config
  ;; Build/refresh the link database. Safe to call repeatedly; it's
  ;; incremental after the first run.
  (org-roam-db-autosync-mode 1)

  ;; CAPTURE TEMPLATE FOR NEW ROAM NOTES.
  ;; ${title} is filled in with whatever you typed when creating the note.
  ;; %<%Y%m%d%H%M%S> is a timestamp used as the filename, so two notes
  ;; with similar titles never collide.
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                               "#+title: ${title}\n#+filetags: :\n")
           :unnarrowed t))))

(with-eval-after-load 'evil
  (suhas/leader
    ;; ── Core org-roam workflow ──────────────────────────────────
    "o r f" #'org-roam-node-find     ; find-or-create a note by title
    "o r i" #'org-roam-node-insert   ; insert a [[wiki-link]] to another note
    "o r b" #'org-roam-buffer-toggle ; show/hide the backlinks sidebar
    "o r c" #'org-roam-capture       ; capture directly into a new roam note
    "o r g" #'org-roam-graph))       ; open an interactive visual graph in browser

;;; HOW TO ACTUALLY USE ORG-ROAM DAY TO DAY
;;;
;;; 1. SPC o r f, type a title. If it matches an existing note, Enter
;;;    jumps there. If it's new, Enter creates it using the capture
;;;    template above.
;;; 2. While writing any note, type [[ and org-roam will offer
;;;    autocompletion of existing note titles (the "type [[ and see
;;;    suggestions" Obsidian-style feel). Or explicitly run
;;;    SPC o r i to insert a link to another note by title.
;;; 3. Whenever you open a note, run SPC o r b once per session to pin
;;;    the backlinks buffer in a side window — it updates automatically
;;;    as you switch between notes, showing you what links to the note
;;;    you're currently viewing.
;;; 4. SPC o r g opens a zoomable node-and-edge graph of your whole
;;;    note collection in your default web browser (needs graphviz's
;;;    `dot` installed on your system — Arch: `sudo pacman -S graphviz`).
;;;
;;; A NOTE ON DISCIPLINE: org-roam does not organize your notes for you.
;;; It rewards SMALL, ATOMIC notes (one idea per file) that you link
;;; together liberally. If you write one giant note per topic, you get
;;; none of the backlink benefit. Habit to build: whenever a concept
;;; inside a note deserves its own explanation, make it its own node
;;; and link to it, rather than writing it inline.

;;; ============================================================
;;; 6. CHEAT SHEET — come back to this section, don't memorize it upfront
;;; ============================================================

;; STRUCTURE
;;   TAB               fold/unfold heading at point
;;   S-TAB             fold/unfold entire buffer
;;   M-RET             insert new heading at same level
;;   M-h / M-l         promote / demote heading   (this config's remap)
;;   M-j / M-k         move heading down / up      (this config's remap)
;;
;; TODOS & SCHEDULING
;;   SPC o t           cycle TODO state
;;   SPC o s           set SCHEDULED date
;;   SPC o d           set DEADLINE date
;;   SPC o a           open agenda (see everything scheduled/due, all files)
;;   SPC o c           capture a quick task or note from anywhere
;;
;; LINKS (built-in, manual)
;;   SPC o l           store link to place you're standing on
;;   SPC o i           insert a previously stored link here
;;   gx  (evil)        follow link under cursor
;;   C-c &             jump back after following a link
;;
;; ORG-ROAM (wiki-style, automatic backlinks)
;;   SPC o r f         find or create a note by title
;;   SPC o r i         insert a link to another note
;;   SPC o r b         toggle the backlinks sidebar
;;   SPC o r c         capture straight into a new roam note
;;   SPC o r g         open the visual link graph
;;
;; EMPHASIS (type these inline, Org renders them)
;;   *bold*   /italic/   _underline_   =verbatim=   ~code~   +strike+
;;
;; TABLES
;;   Just type | cell | cell | and TAB — Org auto-aligns the table for you.
;;
;; CODE BLOCKS (useful since you're a dev — syntax highlighted, executable)
;;   Type manually:
;;     #+begin_src python
;;     print("hello")
;;     #+end_src
;;   C-c C-c inside the block executes it (needs org-babel language enabled).

;;; org.el ends here

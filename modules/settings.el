;;; settings.el --- Every tunable knob, in ONE place  -*- lexical-binding: t; -*-
;;;
;;; This file only DEFINES variables and their defaults. Load order:
;;;
;;;     settings.el  (tracked, defaults)
;;;     windows.el   (tracked, Windows defaults; Windows only)
;;;     local.el     (untracked, YOURS)
;;;
;;; To change anything on one machine, `setq' it in local.el. You never edit
;;; a tracked file, so `git pull' never conflicts with your setup. See
;;; local.example.el for a template.
;;;
;;; These are plain variables on purpose, not `defcustom's: one mechanism only.

;;; ============================================================
;;; PLATFORM
;;; ============================================================

(defconst suhas/windows-p (eq system-type 'windows-nt)
  "Non-nil when running native Windows Emacs (not WSL).
Everything Windows-specific lives in modules/windows.el.")

(defvar suhas/platform-setup-hook nil
  "Functions run at the top of core.el, after local.el has been read.
A platform module (modules/windows.el) puts its setup here so it sees
your local.el overrides.")

;;; ============================================================
;;; WHICH MODULES LOAD
;;; ============================================================

(defvar suhas/modules
  '("ui" "completion" "search" "evil" "window-mgmt" "buffer-nav" "terminal"
    "lsp" "langs" "formatter" "devtools" "remote" "magit" "forge" "org"
    "doctor")
  "Modules loaded after `core', in this order (files in modules/).
Remove a name in local.el to switch a feature off entirely, e.g.
  (setq suhas/modules (delete \"org\" suhas/modules))
`forge' needs `magit'; nothing else depends on order.")

(defvar suhas/failed-modules nil
  "Modules that signalled an error while loading (filled by init.el).
Shown by `suhas/doctor'.")

;;; ============================================================
;;; PACKAGES
;;; ============================================================

(defvar suhas/package-archives
  '(("gnu"    . "https://elpa.gnu.org/packages/")
    ("nongnu" . "https://elpa.nongnu.org/nongnu/")
    ("melpa"  . "https://melpa.org/packages/"))
  "Where packages come from. Point these at an internal mirror if your
company has one. Released versions (gnu, nongnu) are preferred over MELPA
snapshots; MELPA is only used for packages nothing else has.")

(defvar suhas/package-check-signature 'allow-unsigned
  "Value for `package-check-signature'.
`allow-unsigned' verifies signed archives and tolerates unsigned MELPA.")

(defvar suhas/shell-env-variables
  '("PATH" "MANPATH" "GOPATH" "JAVA_HOME" "SSH_AUTH_SOCK"
    "http_proxy" "https_proxy" "no_proxy" "HTTP_PROXY" "HTTPS_PROXY" "NO_PROXY")
  "Variables copied from your login shell into GUI Emacs (not Windows).
Imported once and cached in env-cache.el; the cache refreshes by itself
when a shell startup file changes, or with M-x suhas/env-refresh.")

;;; ============================================================
;;; WHERE YOUR CODE LIVES
;;; ============================================================

(defvar suhas/repo-root-candidates
  '("~/.emacs.d" "~/code" "~/projects" "~/dev" "~/src" "~/repos" "~/work" "~/workspace"
    "~/git" "~/cpp")
  "Folders that CONTAIN your repos, or that are themselves a project.
Folders that don't exist are ignored, so one list can serve several machines.
Used by: SPC p p (project discovery), SPC s f, SPC s g/G, magit repo list.")

(defvar suhas/repo-root-depth 2
  "How many directory levels below each root to look for repos.
1 = repos directly inside the root (~/code/app). 2 also finds
~/work/team/app. A folder that is a project (has .git or .project) is never
searched further, so monorepos are not split.")

(defvar suhas/repo-scan-ignore
  '("node_modules" "target" "build" "dist" "vendor" "__pycache__" "venv")
  "Directory names never entered while looking for repos (dot-dirs always skipped).")

(defvar suhas/project-rescan-interval 30
  "Seconds before SPC p p rescans the repo roots again (0 = every time).")

(defvar suhas/org-directory "~/org"
  "Where your org notes, tasks and org-roam notes live.")

;;; ============================================================
;;; UI
;;; ============================================================

(defvar suhas/font-family "Iosevka Nerd Font"
  "Preferred font. Applied only when it is installed; otherwise the default stays.")

(defvar suhas/font-size 120 "Font height in 1/10 pt (120 = 12pt).")

(defvar suhas/themes
  '(modus-vivendi-tinted modus-vivendi modus-operandi-tinted modus-operandi
    misterioso tango-dark wombat deeper-blue wheatgrass
    gruber-darker chyla-dark inkpot haki)
  "Themes offered by the theme menu. Ones not installed on a machine are skipped.")

(defvar suhas/default-theme 'modus-vivendi-tinted
  "Theme used on a fresh machine (before any theme has been saved).")

(defvar suhas/frame-padding 8
  "Pixels of empty space between the frame edge and the text (0 = none).")

(defvar suhas/pixel-scroll t
  "Pixel-smooth scrolling for touchpads (Linux X11/Wayland, macOS).
Windows sends no pixel data, so windows.el turns it off.")

(defvar suhas/vim-mode-enabled t
  "Start with Evil (Vim keys) on. Toggle at runtime with SPC c v or C-c v.")

;;; ============================================================
;;; TERMINAL
;;; ============================================================

(defvar suhas/terminal-position 'below
  "Where the terminal window goes: `below' or `right' (SPC t p changes it live).")

(defvar suhas/terminal-height-fraction 0.32
  "Fraction of the frame height the terminal gets when it is below.")

(defvar suhas/terminal-width-fraction 0.40
  "Fraction of the frame width the terminal gets when it is on the right.")

(defvar suhas/terminal-escape 'terminal
  "Where ESC goes while you type in a terminal.
`terminal'  always to the program, like any other terminal emulator. This
            is what coding agents and other TUIs (Claude Code, vim, lazygit)
            expect. Leave the terminal's insert state with C-c ESC or C-x ESC.
`auto'      to full-screen programs (vim, less); Evil's normal state at a
            shell prompt.
`evil'      always Evil's normal state.
C-c C-r changes it for one terminal buffer.")

;;; ============================================================
;;; LANGUAGES / LSP / TREE-SITTER
;;; ============================================================

(defvar suhas/treesit-modes
  '((python-ts-mode     python)
    (js-ts-mode         javascript jsdoc)
    (typescript-ts-mode typescript)
    (tsx-ts-mode        tsx)
    (json-ts-mode       json)
    (css-ts-mode        css)
    (c-ts-mode          c)
    (c++-ts-mode        cpp)
    (c-or-c++-ts-mode   c cpp)
    (java-ts-mode       java)
    (rust-ts-mode       rust)
    (go-ts-mode         go)
    (go-mod-ts-mode     gomod)
    (bash-ts-mode       bash)
    (yaml-ts-mode       yaml)
    (toml-ts-mode       toml)
    (dockerfile-ts-mode dockerfile))
  "Tree-sitter modes this config uses: (MODE GRAMMAR...).
A mode is switched on only when ALL its grammars are installed in
tree-sitter/ (M-x suhas/treesit-install builds them). Until then the
classic mode is used where Emacs has one (python, js, c, c++, java, sh,
css, json). Remove an entry to keep the classic mode for that language.")

(defvar suhas/lsp-auto-start t
  "Start a language server automatically when you open a file it handles.
Only for local files, and only when the server is installed. nil = start
one yourself with M-x eglot.")

(defvar suhas/lsp-confirm-edits 'summary
  "Value for `eglot-confirm-server-edits'.
`summary' asks before a language server edits files (rename, code actions
that touch other files). Set nil in local.el if you trust your servers.")

(defvar suhas/python-lsp-command '("pyright-langserver" "--stdio")
  "Python language server command. e.g. (\"basedpyright-langserver\" \"--stdio\").
nil = let Eglot pick the first one it finds (pylsp, basedpyright, pyright, ruff...).")

(defvar suhas/lsp-server-overrides nil
  "Extra `eglot-server-programs' entries, added in front of the defaults.
e.g. ((go-ts-mode . (\"gopls\" \"-remote=auto\"))), quoted.")

(defvar suhas/format-on-save-modes nil
  "Major modes whose buffers are formatted on save.
e.g. (go-ts-mode rust-ts-mode), quoted. Empty by default: reformatting a file
you do not own creates noisy diffs, so opt in per language.")

;;; settings.el ends here

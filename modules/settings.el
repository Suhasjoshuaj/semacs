;;; settings.el --- Every tunable knob, in ONE place  -*- lexical-binding: t; -*-
;;;
;;; This file only DEFINES variables and their defaults. It is loaded first
;;; (before any other module), and then `local.el' is loaded right after it:
;;;
;;;     settings.el  (tracked, defaults)  ->  local.el  (untracked, YOURS)
;;;
;;; So to change anything on one machine you `setq' it in local.el. You never
;;; edit a tracked file, which means `git pull' never conflicts with your
;;; setup. See local.example.el for a template.
;;;
;;; These are plain variables on purpose, not `defcustom's: values saved by
;;; M-x customize land in custom.el, which loads LAST and would silently
;;; override local.el. One mechanism only.

;;; ============================================================
;;; PLATFORM
;;; ============================================================

(defconst suhas/windows-p (eq system-type 'windows-nt)
  "Non-nil when running native Windows Emacs (not WSL).")

(defvar suhas/git-for-windows-root
  (when suhas/windows-p
    (expand-file-name "Git" (or (getenv "ProgramFiles") "C:/Program Files")))
  "Where Git for Windows is installed (Windows only; ignored elsewhere).
Its bash is what the terminal and `compile' use on Windows.")

(defvar suhas/windows-use-git-bash t
  "On Windows: use Git Bash as `shell-file-name' (compile, shell-command).")

;;; ============================================================
;;; WHICH MODULES LOAD
;;; ============================================================

(defvar suhas/modules
  '("ui" "completion" "search" "evil" "terminal" "lsp" "langs"
    "buffer-nav" "window-mgmt" "compile" "formatter" "devtools" "remote"
    "magit" "forge" "org" "claude" "doctor")
  "Modules loaded after `core', in this order (files in modules/).
ORDER MATTERS: `search' needs `completion'; everything that defines SPC
keys needs `evil'; `forge' needs `magit'. Remove a name in local.el to
switch a feature off entirely, e.g.
  (setq suhas/modules (delete \"org\" suhas/modules))")

(defvar suhas/failed-modules nil
  "Modules that signalled an error while loading (filled by init.el).
Shown by `suhas/doctor'.")

;;; ============================================================
;;; PACKAGES
;;; ============================================================

(defvar suhas/package-check-signature
  (if suhas/windows-p nil 'allow-unsigned)
  "Value for `package-check-signature'.
Windows: nil, because the gpg that Emacs finds there (Git's MSYS gpg) mangles
Windows keyring paths and verification can never succeed; downloads still go
over HTTPS. Elsewhere `allow-unsigned' (verifies signed archives, tolerates
unsigned MELPA). On a locked-down work machine you may want to run
`gnu-elpa-keyring-update' once and keep verification on.")

(defvar suhas/shell-env-variables
  '("PATH" "MANPATH" "GOPATH" "JAVA_HOME" "SSH_AUTH_SOCK"
    "http_proxy" "https_proxy" "no_proxy" "HTTP_PROXY" "HTTPS_PROXY" "NO_PROXY")
  "Variables copied from your login shell into GUI Emacs (not Windows).
The proxy variables matter at companies: without them package.el, forge and
language servers started from a GUI Emacs cannot reach the network.")

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

(defvar suhas/font-family
  (pcase system-type
    ('windows-nt "Iosevka NF")
    ('gnu/linux "Iosevka Nerd Font")
    (_ "Monospace"))
  "Preferred font. Applied only when it is installed; otherwise the default stays.")

(defvar suhas/font-size 120 "Font height in 1/10 pt (120 = 12pt).")

(defvar suhas/themes
  '(misterioso modus-vivendi modus-operandi tango-dark wombat
    deeper-blue wheatgrass gruber-darker modus-vivendi-tinted chyla-dark inkpot haki)
  "Themes offered by the theme menu. Ones not installed on a machine are skipped.")

(defvar suhas/default-theme 'modus-vivendi
  "Theme used on a fresh machine (before any theme has been saved).")

(defvar suhas/vim-mode-enabled t
  "Start with Evil (Vim keys) on. Toggle at runtime with SPC c v or C-c v.")

;;; ============================================================
;;; TERMINAL
;;; ============================================================

(defvar suhas/terminal-position 'below
  "Where the terminal window goes: `below' or `right' (SPC t p changes it live).")

(defvar suhas/terminal-height-fraction (if suhas/windows-p 0.28 0.32)
  "Fraction of the frame height the terminal gets when split below.")

(defvar suhas/terminal-width-fraction 0.35
  "Fraction of the frame width the terminal gets when split right.")

;;; ============================================================
;;; LANGUAGES / LSP
;;; ============================================================

(defvar suhas/lsp-confirm-edits 'summary
  "Value for `eglot-confirm-server-edits'.
`summary' asks before a language server edits files (rename, code actions
that touch other files). On a work codebase that is the safe default;
set nil in local.el if you trust your servers.")

(defvar suhas/python-lsp-command '("pyright-langserver" "--stdio")
  "Python language server command. e.g. (\"basedpyright-langserver\" \"--stdio\").")

(defvar suhas/clangd-query-driver
  (let ((p "C:/msys64/ucrt64/bin/g++.exe"))
    (and suhas/windows-p (file-exists-p p) p))
  "Compiler clangd may query for system include paths (needed with MinGW/MSYS2).
nil = pass nothing. Auto-detected for a default MSYS2 UCRT64 install.")

(defvar suhas/lsp-server-overrides nil
  "Extra `eglot-server-programs' entries, added in front of the defaults.
e.g. ((go-mode . (\"gopls\")) (rust-mode . (\"rust-analyzer\"))), quoted.")

(defvar suhas/python-command (if suhas/windows-p "python" "python3")
  "Interpreter used by `suhas/run-current-file'.")

(defvar suhas/c-run-with-makefile nil
  "When non-nil and a Makefile sits next to a C/C++ file, SPC m b runs
`make src=FILE' instead of calling gcc/g++ directly.")

(defvar suhas/format-on-save-modes nil
  "Major modes whose buffers are formatted (format-all) on save.
e.g. (go-mode rust-mode), quoted. Empty by default: reformatting a file you do not
own creates noisy diffs, so opt in per language.")

;;; ============================================================
;;; CLAUDE CODE
;;; ============================================================

(defvar suhas/claude-command "claude"
  "Command run by SPC a c (the Claude Code CLI). Flags are fine:
\"claude --model opus\".")

(defvar suhas/claude-integration nil
  "Optional Emacs-side integration with Claude Code. nil or `claude-code-ide'.
nil = just run the CLI in a ghostel buffer (SPC a c), no extra packages.
`claude-code-ide' = also install manzaltu/claude-code-ide.el (MCP bridge:
Claude sees your selection, diagnostics, open buffers). Needs Emacs 30+.")

(provide 'settings)
;;; settings.el ends here

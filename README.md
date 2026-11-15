# semacs — Suhas' Emacs config

Lean, fast, and *readable*. An Evil (Vim) layer on a small, deliberate set of
packages. Works on **Windows and Linux** with the same config and the same
terminal (ghostel).

**Requires Emacs 29.1+** (30+ recommended: `which-key` and EditorConfig are
built in there). Needs `git`, `fd` and `ripgrep` on your PATH.
Run `M-x suhas/doctor` (`SPC c h`) any time to see what is installed and what
is missing.

**Verification status (be honest about it):** this version was loaded and its
logic (repo discovery, run commands, doctor, snapshot, reload) tested in batch
Emacs **31.1** with third-party packages stubbed out. It has **not** been run
with the real packages, ghostel, or on Windows. Treat the first launch on a new
machine as the real test, and use `SPC c h` and `*Messages*` to read the result.

---

## Quick Start

1. **Back up any old config:** `mv ~/.config/emacs ~/.config/emacs.bak`
2. **Put this repo at `~/.config/emacs`.**
3. **Install the external tools**
   ```bash
   # Arch
   sudo pacman -S fd ripgrep
   # Debian / Ubuntu  (the fd binary is `fdfind`; the config handles that)
   sudo apt install fd-find ripgrep
   # Windows
   scoop install fd ripgrep     # or: winget install sharkdp.fd BurntSushi.ripgrep.MSVC
   ```
4. **Start Emacs.** The first run downloads packages (1–2 min). Watch `*Messages*`.
5. **Tell it about this machine** in `local.el` (the one place for
   machine-specific settings; press `SPC c o` and it is created from
   `local.example.el`):
   ```elisp
   (setq suhas/repo-root-candidates '("~/work" "~/code"))
   ```
   Folders that don't exist are ignored. Repos are found up to
   `suhas/repo-root-depth` (default 2) levels below each root, so
   `~/work/team/app` works. See "Settings and local.el" below.
6. **Terminal, first use only:** press `SPC t t`. Ghostel offers to download a
   prebuilt native module; answer **yes**. It needs an Emacs built with dynamic
   modules: `M-: (featurep 'modules)` must return `t`. If nothing happens after
   "downloading native module…", see Troubleshooting (manual download).

If a module fails to load, Emacs keeps going and shows a warning naming that
module. Fix it, then `SPC c r`. `SPC c h` lists failed modules too.

---

## Settings and local.el (the single place for machine setup)

```
modules/settings.el    every knob with its default and an explanation  (tracked)
local.el               YOUR overrides, loaded right after settings.el   (gitignored)
local.example.el       a template to copy                               (tracked)
```

`local.el` is plain Emacs Lisp loaded **before** the other modules, so a `setq`
there wins. Because it is gitignored, `git pull` never conflicts with your
setup, and two people can share one repo with different machines.

Common things to set there:

```elisp
(setq suhas/repo-root-candidates '("~/work" "~/code"))      ; where repos live
(setq suhas/modules (delete "org" suhas/modules))            ; switch a feature off
(setq suhas/font-family "JetBrains Mono")
(setq suhas/python-lsp-command '("basedpyright-langserver" "--stdio"))
(setq suhas/format-on-save-modes '(go-mode rust-mode))        ; opt-in
(setq suhas/claude-integration 'claude-code-ide)              ; optional, Emacs 30+
```

Use `local.el`, not `M-x customize`: Customize writes `custom.el`, which loads
last and would override `local.el`. (Customize is still used for the saved
theme only.)

### Using this config on a work machine (checklist)

1. Install Emacs 30+ with dynamic modules and sqlite (`SPC c h` checks both).
2. Install `git`, `ripgrep`, `fd`, and the language servers you use.
3. First start needs network access to MELPA/GNU ELPA (set `HTTPS_PROXY` in
   your shell if behind a proxy; GUI Emacs copies it in, see
   `suhas/shell-env-variables`).
4. `SPC t t` once: ghostel downloads a **prebuilt native module** and loads it
   into Emacs. If your company restricts that, confirm it is allowed; the rest
   of the config does not depend on it.
5. Create `local.el` (`SPC c o`): repo roots, and drop `"org"` if you do not
   want personal notes tooling.
6. Run `SPC c h` until nothing important says `[FAIL]`.
7. Language servers ask before editing files across the project
   (`suhas/lsp-confirm-edits`); format-on-save is off until you opt in.
8. Once it works, run `SPC c s` and commit `package-versions.eld`. It records
   exact package versions; `SPC c d` on another machine shows what drifted.
   (Packages are not pinned: this is a record, not a lockfile. To clone a
   working setup exactly, copy the whole `elpa/` directory for the same Emacs
   version and OS.)

---

## The one idea to learn first: how finding things works

Two tools, two clear jobs. They no longer overlap.

| Job | Tool | Keys |
|-----|------|------|
| *Which project am I in, and which file inside it?* | **project.el** | `SPC p p`, `SPC p f` |
| *Search across many files, or inside files* | **consult** (fd / ripgrep) | `SPC s …` |

**A "project" is any folder containing `.git` or an empty file named
`.project`.** `SPC p n` creates the marker for a folder that isn't a git repo
(for example a flat `~/cpp` practice folder).

### "I just opened Emacs and want a file"

| You want to… | Press | What happens |
|---|---|---|
| reopen something you edited before | `SPC SPC`, type part of the name | open buffers **and recent files** (last 500) in one list |
| open any file in any repo, by name | `SPC s f` (or `C-c f`) | fd across **all** repo roots; type 2+ characters |
| jump into a project, pick a file | `SPC p p` | project list (new repos found automatically), then a fuzzy file list |
| find a file inside the current project | `SPC p f` | fuzzy on the **path** (`srcmn` finds `src/main.c`) |
| find text in the current project | `SPC s g` (or `C-c g`) | ripgrep with live preview |
| find text in **all** repos | `SPC s G` | ripgrep across all roots |
| find text in this file | `SPC s s` | consult-line |
| jump to a function/class in this file | `SPC s i` | imenu |
| edit any file of this config | `SPC c e` | fuzzy list of the config's files |

Good to know:

- `SPC s f` matches **file names only**, not folders. Words are ANDed: `two sum`
  finds `two_sum.cpp`. To match on a path (`src main`), use `SPC p f` inside the
  project. (This is deliberate: matching the full path made a query like `cpp`
  match *every* file inside a folder called `cpp`.)
- In `SPC s g` / `SPC s G` you type a regex. Text after a second `#` filters the
  *results*: `foo#bar#baz` searches `bar`, then narrows by `baz`.
- ripgrep also reads dotfiles (`.github`, `.env`) but never `.git`;
  `.gitignore` is respected.
- Results start after about 0.2 s of typing (Windows: 0.4 s, a deliberate pipe
  workaround).

### Moving to a definition

| Key | Action |
|---|---|
| `gd` or `M-.` | jump to definition (`M-.` works in every state now) |
| `M-,` | jump back |
| `M-?` | references: one Vertico list with live preview |
| `SPC e r` / `SPC e a` | rename / code actions |

Definitions and references no longer open an `*xref*` buffer; consult shows
them with a preview.

### Completion styles (so every list behaves the same)

- Words in any order, as text or regex: `foo bar`, `^main`.
- `abc` also matches initials (`a…b…c`).
- End a word with `~` for fuzzy-subsequence on demand: `cvf~`.
- The **project file list** (`SPC p f`, `SPC p p`) is fuzzy by default.
- `SPC SPC`, `M-x`, etc. use the strict styles (flex everywhere turned `M-x`
  into noise).

---

## Key Bindings

### Leader: `SPC` (normal / visual state)

Press `SPC` and wait half a second: **which-key** shows what can follow.

#### Files & buffers
| Key | Action |
|---|---|
| `SPC f f` | find file (classic) |
| `SPC f r` | recent files |
| `SPC f s` | save |
| `SPC f d` | dired |
| `SPC SPC` | buffers + recent files |
| `SPC k` | kill buffer |
| `SPC b i` | ibuffer |
| `C-;` / `C-'` | next / previous **code** buffer |
| `C-,` | toggle between the last two buffers |
| `C-c n` / `C-c p` / `C-c b` | the same three, for terminal Emacs (`emacs -nw`) where `C-;` etc. don't exist (also `SPC b n/p/b`) |
| `C-x l` | speedbar (file tree); press again to jump in/out |

#### Search & projects
| Key | Action |
|---|---|
| `SPC s f` | file by name, all repos |
| `SPC s g` / `SPC s G` | text in project / in all repos |
| `SPC s s` / `SPC s i` | text in buffer / symbols in file |
| `SPC p p` | switch project (rescans first; also switches perspective) |
| `SPC p f` | file in project |
| `SPC p n` | mark a folder as a project (`.project`) |
| `SPC p b` `p d` `p k` `p r` | project buffer / dired / kill buffers / query-replace |
| `C-c f` / `C-c g` | same as `s f` / `s g`; work where `SPC` doesn't |

#### Git (magit)
| Key | Action |
|---|---|
| `SPC g s` | status (from anywhere; asks for a repo if you're not in one) |
| `SPC g l` / `SPC g b` | log / blame |
| `SPC g r` | list all your repos |
| `SPC g f` | forge menu: pull requests and issues (needs a token, see `modules/forge.el`) |

#### Windows, workspaces, perspectives
| Key | Action |
|---|---|
| `SPC w h/j/k/l` | move between windows |
| `SPC w s` / `w v` | split / vsplit |
| `SPC w q` / `w o` / `w =` / `w r` | close / only this / balance / rotate |
| `SPC v n/k/r/l/h/b/a` | perspectives: switch-or-create / kill / rename / next / prev / buffer list / add buffer |
| `M-1` … `M-9` | jump to perspective by number (creation order) |

Perspective is the **only** workspace system (tab-bar was removed: same job,
and perspective also isolates buffers per project).

#### Terminal (ghostel)
| Key | Action |
|---|---|
| `SPC t t` | show this perspective's terminal (creates one if needed) |
| `SPC t e` / `C-c e` | where ESC goes in this terminal: auto / always the program / always Evil |
| `SPC t n` | new named terminal |
| `SPC t s` | pick a terminal |
| `SPC t l` / `SPC t h` | next / previous terminal |
| `SPC t r` | rename |
| `SPC t k` | kill the current terminal (window closes if it was the last) |
| `SPC t K` | kill all terminals in this perspective |
| `SPC t p` | position: below / right |

In the terminal, `ESC` goes to normal state at a prompt and is passed through to
programs like vim/htop. `C-c C-t` or `C-x C-q` freezes the view so you can
select and copy.

**Multi-line input (pasted commands):** paste with `p` (normal state) or `C-y`
(insert state); ghostel sends it as a bracketed paste, so the shell receives the
whole block. In live mode Vim editing only reaches the line the cursor is on
(on other lines Up/Down mean shell history). To edit a multi-line command
properly, press `C-c v` to switch Vim mode off (plain Emacs keys), edit, and
`C-c v` again to switch it back on.

#### Code
| Key | Action |
|---|---|
| `SPC e n` / `SPC e p` | next / previous diagnostic |
| `SPC e l` | diagnostics list (jumpable, with preview) |
| `SPC e a` / `SPC e r` / `SPC e f` | code action / rename / LSP format |
| `SPC e o` | format-all (non-LSP formatter) |
| `SPC m b` | build/run **this file**, by language (C, C++, Rust, Go, Python, JS) |
| `SPC m c` / `m r` | compile / recompile |
| `SPC m n` / `m p` / `m g` / `m k` | next error / previous / first / stop build |
| `SPC d d` / `b` / `c` / `n` / `i` / `o` / `r` / `q` | debugger (dape): start / breakpoint / continue / next / step in / out / restart / quit |

#### Claude Code
| Key | Action |
|---|---|
| `SPC a c` | open Claude Code in a new terminal at the project root |
| `SPC a r` | same, resuming a previous conversation (`--resume`) |
| `SPC a m` | menu of claude-code-ide (only if enabled in `local.el`) |

See "Claude Code" below.

#### Org: `SPC o …` (cheat sheet at the bottom of `modules/org.el`)

#### Config
| Key | Action |
|---|---|
| `SPC c e` | open a config file (fuzzy) |
| `SPC c o` | open `local.el` (created from the template if missing) |
| `SPC c r` | reload config (only a restart is a fully clean slate) |
| `SPC c h` | doctor: what is installed / missing / broken |
| `SPC c s` / `SPC c d` | snapshot package versions / show drift from the snapshot |
| `SPC c v` / `C-c v` | toggle Vim mode (all buffers) |
| `SPC c l` | toggle Vim mode in this buffer only |
| `SPC u t` / `u n` / `u p` | theme menu / next / previous theme |
| `SPC l w` | toggle line wrap |

---

## Magit

Every magit buffer (status, log, diff, revision, process, refs, stash, repo
list...) runs in plain **Emacs state** with magit's own native keys; press `?`
in any of them for the full list. Evil's vim-style magit layer is not used, so
nothing is remapped. The commit-message buffer is the exception: it is a text
editor, so it keeps Vim keys (see below).

| Key | Action |
|---|---|
| `n` / `p` | next / previous line (section-aware) |
| `TAB` | fold / unfold section |
| `s` / `u` | stage / unstage (file, hunk, or a region) |
| `k` | **discard** |
| `c` | commit menu (`c c` to commit) |
| `P` / `F` / `f` | push / pull / fetch menus |
| `b` / `l` / `d` / `z` / `r` | branch / log / diff / stash / rebase menus |
| `g` | refresh |
| `q` | quit **and restore your previous window layout** |
| `SPC k` | **kill** this magit buffer (and restore the layout) |
| `SPC SPC` | `consult-buffer` |
| `SPC r` / `f` / `g` / `G` / `p` | recent files / find file / grep project / grep everywhere / switch project |
| `C-v` / `M-v` | scroll down / up (`SPC` is the leader now; `DEL` still scrolls up) |
| `C-,` `C-;` `C-'` | last buffer / next / previous code buffer (global) |

**Commit message buffer:** `:wq` / `:x` / `ZZ` / `C-c C-c` = commit, `:q` / `ZQ` /
`C-c C-k` = abort, `:w` = only save the draft (git keeps waiting; finish later
with `:wq`).

To go back to the vim-style magit (evil-collection-magit): in `modules/evil.el`
add `magit` to the `evil-collection-init` list and delete the two
`evil-set-initial-state 'magit-...` lines and the `magit-*-hook` entries in the
`dolist` of the "SPECIAL BUFFER STATES" section.

---

## Vim mode

On by default (Evil). Toggle with `SPC c v` / `C-c v`; off gives normal Emacs
keys (`C-n/p`, `C-a/e`, …).

- ibuffer, compile, xref and speedbar get full Vim-style bindings from
  evil-collection. **dired and Info stay in Emacs state** with their native
  keys (dired: `i` insert subdirectory, `a` open in this buffer, `o` sort,
  `m`/`u`/`d` mark, `C-x C-q` editable dired).
- dired has its own small leader: `SPC` then `SPC` (buffers) / `k` (kill
  buffer) / `r` (recent) / `f` (find file everywhere) / `g` `G` (grep project /
  all repos) / `p` (switch project). Buffer cycling `C-;` `C-'` `C-,` and
  `C-c f` / `C-c g` are global and work there too.
- `ESC` quits the minibuffer, region, or running command. It **never closes
  windows** (the old `keyboard-escape-quit` did, in any non-normal state).
- `C-u` scrolls up; `C-r` redoes.

---

## Languages, servers and project tooling

**Python, JS/TS/TSX, Rust, Go, C/C++, Java, YAML** via Eglot, plus Markdown and
Dockerfile modes. If a server isn't found:
```bash
npm install -g pyright typescript-language-server typescript yaml-language-server
rustup component add rust-analyzer          # Rust
go install golang.org/x/tools/gopls@latest # Go
sudo pacman -S clangd                       # Arch;  Debian: sudo apt install clangd
# Java: jdtls (https://github.com/eclipse/eclipse.jdt.ls/releases)
```
The completion popup (Corfu) appears after 2 characters. **TAB** inserts;
`RET` always means newline.

What the work-oriented pieces do (`modules/devtools.el`):

- **EditorConfig:** a project's `.editorconfig` overrides the default 4/2-space
  indentation. (Built into Emacs 30+.)
- **direnv (`envrc`):** if `direnv` is installed, each buffer gets the
  environment of its project's `.envrc`. This is how Pyright finds a project's
  virtualenv and `node` resolves to the project's version. Without direnv,
  Python completion uses whatever `python` is on PATH.
- **Spellcheck** for commit messages, Markdown and Org (needs `aspell` or
  `hunspell`).
- **Language-server edits ask first** (`suhas/lsp-confirm-edits`).
- **Remote / containers (`modules/remote.el`):** `/ssh:host:/path`,
  `/docker:container:/path`, `/sudo::/etc/hosts` work with eglot, magit and
  compile.

**TSX:** without tree-sitter, `.tsx` files use `web-mode` (typescript-mode has
no JSX support). It is a best-effort setup and untested on real React code;
the proper fix is `tsx-ts-mode` when you decide to adopt tree-sitter.

## Claude Code

`SPC a c` runs the `claude` CLI in a ghostel terminal at the project root,
inside the current perspective. When Claude exits, its terminal closes. Nothing
extra is installed. What makes it work well:

- Files Claude edits **reload in your buffers** automatically (auto-revert), and
  `SPC g s` (magit) plus the diff-hl gutter show exactly what changed.
- **ESC goes to Claude**, not to Evil. Claude Code uses ESC to interrupt and
  (twice) to rewind, and evil-ghostel's default only forwards ESC for
  full-screen programs such as vim. These buffers pin ESC to the program. Press
  `C-c e` to cycle to "Evil" when you want normal state in the terminal.
- If the buffer opens your normal shell instead of Claude, ghostel read its
  shell setting later than expected: open `SPC t t` and type `claude` once, and
  tell whoever maintains this config (the launcher is `suhas/claude` in
  `modules/claude.el`).
- Optional MCP bridge (Claude can see your selection, buffers and Flymake
  diagnostics): put `(setq suhas/claude-integration 'claude-code-ide)` in
  `local.el` (Emacs 30+; it installs `manzaltu/claude-code-ide.el` from GitHub).
  Another option is `stevemolitor/claude-code.el`; neither is configured here
  beyond the first.

---

## File organization

```
~/.config/emacs/
├── early-init.el      startup performance; package.el activated once
├── init.el            table of contents: loads settings, local.el, then modules
├── local.example.el   template for your machine settings (copy to local.el)
├── local.el           YOURS (gitignored)
├── package-versions.eld   package snapshot (commit it; made by SPC c s)
└── modules/
    ├── settings.el    every knob and its default            (not removable)
    ├── core.el        packages, defaults, environment, shared helpers (always loads)
    ├── ui.el          theme, font, line numbers, modeline
    ├── completion.el  Vertico, Orderless, Marginalia, Consult, Corfu, Cape
    ├── search.el      repo roots, projects, find-anywhere, grep, recentf, speedbar
    ├── evil.el        Vim layer, leader keys, which-key
    ├── terminal.el    ghostel (Windows + Linux), multi-terminal layer
    ├── lsp.el         Eglot
    ├── langs.el       per-language modes
    ├── buffer-nav.el  code-buffer rotation / toggle
    ├── window-mgmt.el perspective (the workspace system), window helpers
    ├── compile.el     compile settings, SPC m b run-this-file
    ├── formatter.el   format-all, opt-in format-on-save
    ├── devtools.el    editorconfig, direnv, spellcheck, debugger
    ├── remote.el      TRAMP (ssh / docker)
    ├── magit.el       magit + diff-hl
    ├── forge.el       pull requests / issues in magit
    ├── org.el         org + org-roam (loaded lazily)
    ├── claude.el      Claude Code launcher (+ optional integration)
    └── doctor.el      health check, package snapshot/drift
```

Modules load in the order of `suhas/modules` (settings.el). Remove a name in
`local.el` to switch a module off. Order matters: `search` needs `completion`,
modules defining `SPC` keys need `evil`, `forge` needs `magit`.

Files Emacs writes (all gitignored): `custom.el` (saved theme), `projects`,
`recentf`, `places` (cursor positions), `history`, `forge-database.sqlite`,
`elpa/`, `eln-cache/`.

---

## Customization

Everything below is a variable in `modules/settings.el`; override it in
`local.el`.

- **Repo locations:** `suhas/repo-root-candidates`, `suhas/repo-root-depth`.
- **Font:** `suhas/font-family` / `suhas/font-size` (applied only if installed).
- **Recent files in `SPC SPC`:** shown by default (so typing a name finds
  files from last week). To hide them until you press `f`, add to
  `completion.el`: `(consult-customize consult-source-recent-file :hidden t :default nil)`.
  The "Perspective" group (this perspective's buffers) was always visible;
  `s` only narrows to it.
- **Themes:** `suhas/themes`; the menu lists only themes available on that
  machine.
- **Terminal size/position:** `suhas/terminal-height-fraction`,
  `suhas/terminal-width-fraction`, `suhas/terminal-position`, or `SPC t p`.
- **Project root rule:** `project-vc-extra-root-markers` in `search.el`. It is
  deliberately just `.project`: adding `package.json` or `Makefile` would split
  a monorepo into one project per service.

---

## Troubleshooting

**`SPC p p` doesn't list my new repo.** It must sit inside one of the
`suhas/repo-root-candidates` folders, no deeper than `suhas/repo-root-depth`
levels (default 2), and contain `.git` (or `.project`). The scan runs at most
every 30 s; `M-x suhas/project-rescan` forces it. Folders named `node_modules`,
`build`, `dist`, … and dot-folders are skipped. A folder that is itself a repo is
never searched further (so submodules inside a monorepo are not separate
projects). Otherwise open any file in the repo; project.el finds it from the file.

**`SPC s f` finds nothing.** Type at least 2 characters. Check
`M-: (executable-find "fd")` (Debian: `"fdfind"`). It matches file *names*.

**A key does nothing in some buffer.** Check the state (`C-z` toggles Emacs
state). `C-h k <key>` shows what it is bound to.

**Terminal won't start / `ghostel--new` is void.** The native module isn't loaded.
Install ghostel the normal way (MELPA, as `terminal.el` does), never with
`:vc`/package-vc, and never set `ghostel-module-directory`. Answer `d` to the
download prompt on the first `SPC t t`. If it still fails: delete
`elpa/ghostel-*` (and any stray `~/.emacs.d/ghostel/` folder), restart, retry.
`M-: (featurep 'modules)` must be `t`.

**`(void-variable evil-mode-buffers)` after every command.** Evil 1.15 on
Emacs 31 reads a variable Emacs 31 no longer defines. `evil.el` defines it
(one `defvar`, near the top); nothing else to do.

**Error in `:` (ex) prompt from Corfu.** Corfu is switched off in evil's `:`
prompt and in terminals (`completion.el`); `TAB` completion of `:` commands is
still evil's own.

**Startup is slow.** `M-x emacs-init-time`, then read `*Messages*` (every
package prints its load time). Usual suspects: the PATH import from your login
shell (`exec-path-from-shell` in `core.el`), and background native compilation
right after package updates (uses CPU but doesn't block).

**"Failed to verify signature … No public key".** On Windows, signature checking
is off on purpose (see `suhas/package-check-signature` in `settings.el`: Git's
MSYS gpg can't use Windows paths, so it can never verify). On Linux it is on; if
you see this there, set `(setq suhas/package-check-signature nil)` in `local.el`
once, run `M-x package-install RET gnu-elpa-keyring-update`, then remove the
line.

---

## What changed in 3.0 (from the 2.0 audit)

- **One place for machine setup:** `settings.el` (defaults) + `local.el`
  (yours). Nothing machine-specific is hardcoded in tracked modules any more
  (the MSYS2 clangd path, the Git-for-Windows path, repo roots, org directory).
- **Modules can be switched off** via `suhas/modules`; load failures are
  tracked and shown by `SPC c h`.
- **Tab-bar removed;** perspective is the only workspace system (`M-1..9` now
  switch perspectives).
- **Dead code resolved:** the five broken compile helpers became one working
  `SPC m b`; `next-theme`/`prev-theme` and `evil-local-mode-toggle` now have
  keys; the unused `smart-window-split-*` and ~50 lines of commented modeline
  code were deleted.
- **Safer defaults:** server edits ask first; no format-on-save unless opted in.
- **Reload is clean:** every hook and advice is a named function, so
  `SPC c r` no longer stacks duplicates.
- **Work tooling added:** Go, Markdown, Dockerfile, TSX (web-mode),
  EditorConfig, direnv, spellcheck, debugger, forge, TRAMP, Claude Code
  launcher, doctor, package snapshot, proxy variables copied into GUI Emacs,
  recentf made TRAMP-safe, backups made hard-link-safe.
- **Repo discovery** now searches `suhas/repo-root-depth` levels (default 2),
  stops at project roots, skips build/vendor folders, and is throttled.
- **Terminal Emacs:** `C-c n/p/b` replace `C-;`/`C-'`/`C-,` where those chords
  do not exist. The `C-;` family is unchanged in GUI Emacs.
- Small: a column number in the modeline and `require-final-newline`.

**Still deliberately not done:** tree-sitter (TSX is best-effort), exact
version pinning (only a snapshot), DAP adapters (install per language), and
runtime testing on real packages, ghostel and Windows.

---

## Learning path

1. **Week 1:** Vim motions (`hjkl`, `w b e`, `i a`, `v`, `d y p`, `ciw`).
2. **Week 2:** the finding model above: `SPC SPC`, `SPC p p`, `SPC s f`,
   `SPC s g`. Stop using `C-x C-f`.
3. **Week 3:** magit daily: `SPC g s`, `s`, `c c`, `P` (press `?` for the rest).
4. **Week 4:** code navigation: `gd`, `M-,`, `M-?`, `SPC e a`, `SPC s i`.
5. **Then:** read one module per weekend. Every file is commented.

Help: `C-h k` (key), `C-h f` (function), `C-h v` (variable), `C-h m` (modes).

---

**Config version**: 3.0 (Nov 2026) · **Emacs required**: 29.1+

# semacs — Suhas' Emacs config

Lean, fast, and *readable*. An Evil (Vim) layer on a small, deliberate set of
packages. Works on **Windows and Linux** with the same config and the same
terminal (ghostel).

**Requires Emacs 29.1+** (30+ recommended: `which-key` is built in there).
Needs `fd` and `ripgrep` on your PATH.

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
5. **Tell it where your repos live** (one list, `modules/search.el`):
   ```elisp
   (defvar suhas/repo-root-candidates
     '("~/code" "~/projects" "~/cpp" "~/org" "~/.config/emacs" ...))
   ```
   Folders that don't exist on a machine are ignored, so one list serves both
   of your computers.
6. **Terminal, first use only:** press `SPC t t`. Ghostel offers to download a
   prebuilt native module; answer **yes**. It needs an Emacs built with dynamic
   modules: `M-: (featurep 'modules)` must return `t`.

If a module fails to load, Emacs keeps going and shows a warning naming that
module (it used to stop silently half-way). Fix it, then `SPC c r`.

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

#### Windows, workspaces, perspectives
| Key | Action |
|---|---|
| `SPC w h/j/k/l` | move between windows |
| `SPC w s` / `w v` | split / vsplit |
| `SPC w q` / `w o` / `w =` / `w r` | close / only this / balance / rotate |
| `SPC a n/k/r/l/h` | tab-bar: new / close / rename / next / prev (`M-1..9` jump) |
| `SPC v n/k/r/l/h/b/a` | perspectives: switch-or-create / kill / rename / next / prev / buffer list / add buffer |

#### Terminal (ghostel)
| Key | Action |
|---|---|
| `SPC t t` | show this perspective's terminal (creates one if needed) |
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

#### Code
| Key | Action |
|---|---|
| `SPC e n` / `SPC e p` | next / previous diagnostic |
| `SPC e l` | diagnostics list (jumpable, with preview) |
| `SPC e a` / `SPC e r` / `SPC e f` | code action / rename / LSP format |
| `SPC e o` | format-all (non-LSP formatter) |
| `SPC m c` / `m r` | compile / recompile |
| `SPC m n` / `m p` / `m g` / `m k` | next error / previous / first / stop build |

#### Org: `SPC o …` (cheat sheet at the bottom of `modules/org.el`)

#### Config
| Key | Action |
|---|---|
| `SPC c e` | open a config file (fuzzy) |
| `SPC c r` | reload config (only a restart is a fully clean slate) |
| `SPC c v` / `C-c v` | toggle Vim mode |
| `SPC u t` | theme menu (lists only installed themes) |
| `SPC l w` | toggle line wrap |

---

## Magit, the Vim way

Magit buffers now start in **normal state** (evil-collection-magit), so `j/k`
move. Most keys are unchanged; the ones that moved:

| Key | Action |
|---|---|
| `j` / `k` | down / up by line |
| `C-j` / `C-k` | next / previous **section** (was `n` / `p`) |
| `gj` / `gk` | next / previous sibling section |
| `TAB` | fold / unfold section |
| `s` / `u` | stage / unstage (file, hunk, or a `v` selection) |
| `x` | **discard** (was `k`) |
| `c` | commit menu (`c c` to commit) |
| `P` / `F` / `f` | push / pull / fetch menus |
| `b` / `l` / `d` / `z` / `r` | branch / log / diff / stash / rebase menus |
| `gr` | refresh (was `g`) |
| `-` | revert (was `v`) |
| `?` | help popup listing everything |
| `q` / `ESC` | quit **and restore your previous window layout** |
| `C-t` | toggle text mode (select/copy arbitrary text) |
| `C-z` | flip this buffer to **plain Emacs state** (magit's native keys) |

To go back to stock magit everywhere, remove `magit` from the
`evil-collection-init` list in `modules/evil.el`.

---

## Vim mode

On by default (Evil). Toggle with `SPC c v` / `C-c v`; off gives normal Emacs
keys (`C-n/p`, `C-a/e`, …).

- dired, ibuffer, compile, magit, xref and speedbar get full Vim-style
  bindings from evil-collection. Help and Info keep their own keys (Info stays
  in Emacs state: `n` `p` `l` `u` `SPC`).
- `ESC` quits the minibuffer, region, or running command. It **never closes
  windows** (the old `keyboard-escape-quit` did, in any non-normal state).
- `C-u` scrolls up; `C-r` redoes.

---

## Language servers

**Python, JS/TS, Rust, C/C++, Java** via Eglot. If a server isn't found:
```bash
npm install -g pyright typescript-language-server typescript
rustup component add rust-analyzer          # Rust
sudo pacman -S clangd                       # Arch;  Debian: sudo apt install clangd
# Java: jdtls (https://github.com/eclipse/eclipse.jdt.ls/releases)
```
The completion popup (Corfu) appears after 2 characters. **TAB** inserts;
`RET` always means newline.

---

## File organization

```
~/.config/emacs/
├── early-init.el      startup performance; package.el activated once
├── init.el            entry point; a failing module only warns
└── modules/
    ├── core.el        packages, defaults, environment, utilities
    ├── ui.el          theme, font, line numbers, modeline
    ├── completion.el  Vertico, Orderless, Marginalia, Consult, Corfu, Cape
    ├── search.el      repo roots, projects, find-anywhere, grep, recentf, speedbar
    ├── evil.el        Vim layer, leader keys, which-key
    ├── terminal.el    ghostel (Windows + Linux), multi-terminal layer
    ├── lsp.el         Eglot
    ├── langs.el       per-language modes
    ├── buffer-nav.el  code-buffer rotation / toggle
    ├── window-mgmt.el tab-bar, perspective
    ├── compile.el     compile settings
    ├── formatter.el   format-all
    ├── magit.el       magit + diff-hl
    └── org.el         org + org-roam (loaded lazily)
```

Files Emacs writes (all gitignored): `custom.el` (saved theme), `projects`,
`recentf`, `places` (cursor positions), `history`, `ghostel/` (terminal native
module), `elpa/`, `eln-cache/`.

---

## Customization

- **Repo locations:** `suhas/repo-root-candidates` in `modules/search.el`.
- **Font:** `suhas/font-family` / `suhas/font-size` in `modules/ui.el`
  (applied only if the font is installed).
- **Themes:** add to `suhas/themes` in `modules/ui.el`; the menu lists only
  themes available on that machine.
- **Terminal size/position:** `suhas/terminal-height-fraction`,
  `suhas/terminal-width-fraction`, `SPC t p`.
- **Project root rule:** `project-vc-extra-root-markers` in `search.el`. It is
  deliberately just `.project`: adding `package.json` or `Makefile` would split
  a monorepo into one project per service.

---

## Troubleshooting

**`SPC p p` doesn't list my new repo.** It must sit *directly inside* one of the
`suhas/repo-root-candidates` folders and contain `.git` (or `.project`).
Otherwise open any file in it; project.el finds it from the file.

**`SPC s f` finds nothing.** Type at least 2 characters. Check
`M-: (executable-find "fd")` (Debian: `"fdfind"`). It matches file *names*.

**A key does nothing in some buffer.** Check the state (`C-z` toggles Emacs
state). `C-h k <key>` shows what it is bound to.

**Terminal won't start.** `M-: (featurep 'modules)` must be `t`. If the native
module download failed, run `M-x ghostel-download-module`. On Windows, Git for
Windows must be at `C:/Program Files/Git` (see `terminal.el`).

**Startup is slow.** `M-x emacs-init-time`, then read `*Messages*` (every
package prints its load time). Usual suspects: the PATH import from your login
shell (`exec-path-from-shell` in `core.el`), and background native compilation
right after package updates (uses CPU but doesn't block).

**Fresh machine: "Failed to verify signature".** `core.el` uses
`package-check-signature 'allow-unsigned`. With an old keyring: set it to `nil`
once, run `M-x package-install RET gnu-elpa-keyring-update`, then remove the
line.

---

## Things that exist but you may not be using

(Audit, Nov 2026. Decide per item: use it or delete it.)

- **Unbound commands:** `suhas/compile-c`, `-cpp`, `-rust`, `suhas/run-python`,
  `suhas/run-js` (and they are buggy: `'./%s'` with an absolute path becomes
  `.//home/…`), `suhas/next-theme`, `suhas/prev-theme`,
  `suhas/smart-window-split-below/right`, `suhas/evil-local-mode-toggle`.
- **Two workspace systems:** tab-bar tabs (`SPC a`, `M-1..9`) *and*
  perspectives (`SPC v`; `SPC p p` also switches to one). They don't talk to
  each other. Pick one as your primary.
- **ibuffer / dired:** fine, but with `SPC SPC`, `SPC s f` and `SPC p p` you may
  rarely need them.
- **org-roam:** lazy now. If you don't use it, delete its block in `org.el`.

---

## Learning path

1. **Week 1:** Vim motions (`hjkl`, `w b e`, `i a`, `v`, `d y p`, `ciw`).
2. **Week 2:** the finding model above: `SPC SPC`, `SPC p p`, `SPC s f`,
   `SPC s g`. Stop using `C-x C-f`.
3. **Week 3:** magit daily: `SPC g s`, `s`, `c c`, `P`. Learn `C-j` / `C-k`.
4. **Week 4:** code navigation: `gd`, `M-,`, `M-?`, `SPC e a`, `SPC s i`.
5. **Then:** read one module per weekend. Every file is commented.

Help: `C-h k` (key), `C-h f` (function), `C-h v` (variable), `C-h m` (modes).

---

**Config version**: 2.0 (Nov 2026) · **Emacs required**: 29.1+

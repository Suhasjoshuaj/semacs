# semacs

A fast, small, readable Emacs config for daily professional development: Vim
keys (Evil), a real terminal (ghostel), tree-sitter, LSP, magit. Linux first;
Windows is supported from one removable file.

**Requires Emacs 31.1+** built with dynamic modules, tree-sitter and sqlite,
plus `git`, `ripgrep` and `fd` on your PATH. `SPC c h` (the doctor) tells you
what is present and what is missing.

**What was actually tested (version 4.0):** every command described here was
run on Emacs 31.1 on Linux with the real packages, in terminal Emacs
(`emacs -nw`). A graphical frame was smoke-tested (start, theme, font,
modeline, terminal panel, `` C-` ``, which-key). Not tested: Windows and
native compilation. Treat the first Windows start as the remaining test.

---

## Quick start

1. Put this folder at `~/.config/emacs` (back up an old one first).
2. Install the tools:
   ```bash
   sudo pacman -S fd ripgrep            # Arch
   sudo apt install fd-find ripgrep     # Debian/Ubuntu (binary is fdfind; handled)
   scoop install fd ripgrep             # Windows
   ```
3. Start Emacs. The first start downloads packages (a few minutes). Without
   network it gives up after one attempt and still starts; restart later.
4. `SPC c o` creates `local.el`, the one place for machine-specific settings:
   ```elisp
   (setq suhas/repo-root-candidates '("~/work" "~/code"))
   ```
5. `SPC c g` builds the tree-sitter grammars (needs `git` and a C compiler).
6. `SPC t t` (or `` C-` ``): the first time, ghostel offers to download its
   native module. Answer `d`.
7. `SPC c h` until nothing important says `[FAIL]`.

---

## Layout

```
early-init.el        GC, package quickstart, frame chrome
init.el              loader only: settings -> (windows) -> local.el -> core -> modules
local.example.el     template for local.el (yours, gitignored)
KEYS.org             every key (SPC c k)
modules/
  settings.el        every knob and its default
  windows.el         ALL Windows-specific code (loaded on Windows only)
  core.el            packages, defaults, the leader keymap, shared helpers
  ui.el              theme, font, modeline (no UI packages)
  completion.el      vertico, orderless, marginalia, consult, corfu, cape
  search.el          projects, find-anywhere, grep, recent files, speedbar
  evil.el            Vim layer, general key bindings
  window-mgmt.el     workspaces (perspective)
  buffer-nav.el      buffer cycling and toggle
  terminal.el        ghostel terminal panel
  lsp.el             eglot, flymake
  langs.el           tree-sitter modes, per-language settings
  formatter.el       SPC e f, opt-in format on save
  devtools.el        editorconfig, direnv, spellcheck, debugger
  remote.el          TRAMP
  magit.el           magit, diff-hl
  forge.el           pull requests and issues
  org.el             org + org-roam
  doctor.el          health check, package snapshot
```

Switch a module off in `local.el`: `(setq suhas/modules (delete "org" suhas/modules))`.

**Dropping Windows later:** delete `modules/windows.el` and the single line in
`init.el` that loads it. No other file contains Windows code.

---

## Why it starts fast

- `package-quickstart`: one autoload file, and `package.el` itself is not
  loaded on a normal start.
- Nothing loads until it is needed. The completion UI, which-key, auto-revert,
  recent files and history switch on at the first keypress (or after half a
  second of idle time). Consult, magit, org, eglot, the terminal and the
  formatter load on first use.
- The login-shell PATH import is cached in `env-cache.el` and only repeated
  when a shell startup file changes (`M-x suhas/env-refresh` forces it).
- `*scratch*` starts in fundamental-mode, so no programming-mode machinery
  loads before you open a file.

Measured on the same machine and Emacs 31.1 (terminal frame, byte-compiled
packages, no native compilation), time until Evil is on and the editor is
ready: **about 0.50 s before, about 0.20 s now**. What remains is mostly Evil
(~0.08 s) and the theme (~0.03 s).

For large files and long lines: bidirectional text scanning is off,
`so-long` is on, fontification is skipped while you type, and only Git is
probed as a version control system.

---

## Keys

**Every key, stock Emacs and Vim included, is in `KEYS.org` (`SPC c k`).**
The essentials:

`SPC` is the leader in normal/visual state, and also in dired and magit
buffers. **`C-c SPC` is the same leader everywhere else** (insert state, the
terminal, Vim mode off). Press it and wait: which-key lists what follows.

| Key | Action |
|---|---|
| `C-c ESC` / `C-x ESC` | Vim normal state from anywhere, also from a terminal's insert state |
| `C-c o` / `C-x o` | next window |
| `C-.` | terminal commands (see Terminal) |

### Files, buffers, search
| Key | Action |
|---|---|
| `SPC SPC` | this workspace's buffers + recent files (`t` + space: terminals, `b` + space: all buffers) |
| `SPC f f` / `f s` / `f r` / `f d` | find file / save / recent / dired |
| `SPC f y` | copy `path:line` of point (or `path:from-to` of the region) |
| `SPC k` | kill buffer |
| `C-;` / `C-'` | next / previous file or dired buffer of this workspace (stable order, like tabs) |
| `C-,` | the buffer this window showed before |
| `C-c n` / `p` / `b` | the same three in terminal Emacs |
| `SPC s s` / `s i` | search this buffer / symbols in this file |
| `SPC s g` / `s G` | ripgrep in the project / in all repos |
| `SPC s f` | file by name in all repos (fd) |
| `C-x l` | speedbar |

### Projects and workspaces
A project is a folder with `.git`, or with an empty `.project` file
(`SPC p n` creates it). Repos under `suhas/repo-root-candidates` are found
automatically.

| Key | Action |
|---|---|
| `SPC p p` | switch project (opens its own workspace) |
| `SPC p f` / `p b` / `p d` / `p k` / `p r` | file / buffer / dired / kill buffers / query-replace in project |
| `SPC v n` / `v k` / `v r` | switch-or-create / kill / rename workspace |
| `SPC v l` / `v h` / `M-1`..`M-9` | next / previous / by number (creation order) |
| `SPC v b` / `v a` | buffers of this workspace / pull a buffer in |

### Windows
`SPC w h/j/k/l` move, `w s` / `w v` split, `w q` close, `w o` only this,
`w =` balance, `w r` rotate. Pop-up buffers (help, results) reuse another
existing window instead of splitting again.

### Code
| Key | Action |
|---|---|
| `gd` / `M-.`, `M-,`, `M-?` | definition, back, references (with preview) |
| `SPC e a` / `e r` | code action / rename |
| `SPC e f` | format (language server if it can, else black/prettier/clang-format/...) |
| `SPC e n` / `e p` / `e l` | next / previous diagnostic / list |
| `SPC d d` `b` `c` `n` `i` `o` `r` `q` | debugger (dape) |
| `M-x compile` | builds; output is coloured and jumps to the first error |

### Git
| Key | Action |
|---|---|
| `SPC g s` / `g l` / `g b` / `g r` | status / log / blame / all repos |
| `]c` / `[c` | next / previous changed hunk |
| `SPC g h` / `g x` | show hunk diff / revert hunk |
| `SPC g f` | forge (PRs, issues; needs a token, see `modules/forge.el`) |

Magit buffers use magit's own keys (`s` stage, `u` unstage, `c c` commit,
`P` push, `F` pull, `q` quit and restore the layout, `?` for everything).
In the commit message buffer `:wq` commits and `:q` aborts.

### Config
| Key | Action |
|---|---|
| `SPC c k` | the key cheat sheet (`KEYS.org`) |
| `SPC c o` / `c e` / `c r` | open `local.el` / any config file / reload |
| `SPC c h` | doctor |
| `SPC c g` | build missing tree-sitter grammars |
| `SPC c s` / `c d` | snapshot package versions / show drift from the snapshot |
| `SPC c v` / `C-c v`, `SPC c l` | Vim keys on/off globally, in this buffer |
| `SPC u t` / `u n` / `u p` | theme menu / next / previous (remembered) |
| `SPC l w` | toggle line wrap |

Org: `SPC o ...` (in `KEYS.org`).

---

## Terminal

One panel, below or on the right. Every terminal buffer appears there, no
matter how it is shown. Each workspace has its own terminals; a new one starts
in the project root as `*term:PROJECT*`. The prompt is just the path; the
environment (`MINGW64:/c/...`, or `user@host:dir`) is in the modeline.

`C-.` works in every state, inside terminals too (`SPC t` is the same map;
terminal Emacs: `C-c SPC t`):

| Key | Action |
|---|---|
| `` C-` `` / `C-c t` / `C-. t` | go to the terminal; from the terminal, hide the panel |
| `C-. n` | new terminal (asks for a name) |
| `C-. l` / `C-. h` / `C-. s` | next / previous / pick by name |
| `C-. r` / `C-. k` / `C-. K` | rename / kill / kill all in this workspace |
| `C-. p` | panel below or right |
| `C-. y` | paste the region (or `path:line`) into the terminal and go there |
| `C-. a` | jump to the terminal that asked for attention |
| `C-. e` | edit bash's command line in a buffer |

Inside the terminal **every key goes to the program, ESC included**, as in
any terminal emulator. So Claude Code, other coding agents, vim, lazygit and
the rest work without special handling.

| Key (while typing in the terminal) | Action |
|---|---|
| `C-c ESC` / `C-x ESC` | Vim normal state: move, search, yank; `i` / `a` to type again |
| `C-c SPC` | the leader |
| `C-y` / `M-y` | paste from your kill ring / an older kill |
| click | moves the cursor there (on the line you are typing) |
| mouse drag | selects and copies |
| `C-c C-t` | copy mode (frozen view) |
| `C-c C-c` | send Ctrl-C |
| `M-1`..`M-9` | switch workspace |
| `C-c C-r` | change where ESC goes in this one terminal |

**Editing what you type.** The shell owns its command line and edits one
line at a time: to it, Up/Down mean history. So the cursor never moves across
lines (that is what used to drop pastes into a history entry). For long or
multi-line input, edit it in a real buffer: `C-. e` in bash, `Ctrl+G` in
Claude Code. `C-c C-c` (or `:wq`) sends it back, `C-c C-k` aborts. Anything a
program opens with `$EDITOR` (`git commit` and the like) opens in this Emacs
the same way.

Prefer ESC to mean "Evil normal state" at a shell prompt? Set
`(setq suhas/terminal-escape 'auto)` in `local.el`. Want your own prompt back?
`(setq suhas/terminal-prompt nil)`.

A file opened while you stand in the panel appears in an editing window; the
panel is never replaced. When a shell exits, its buffer and the panel close.

### Working with coding agents

Nothing is specific to one agent; it is the terminal plus a few editor habits:

- Run the agent in a terminal (`C-. n`, name it, start the CLI).
- Files it edits **reload in your buffers** by themselves.
- Review: fringe marks show what changed; `]c` / `[c` walk the hunks,
  `SPC g h` shows one, `SPC g x` reverts one, `SPC g s` is the whole picture.
- Give it context: `C-. y` pastes the selected code or the `path:line`
  under the cursor into its prompt. `SPC f y` copies the reference instead.
- Know when it needs you: a bell from a terminal you are not looking at shows
  a message, and programs that report their status (blocked, done, failed)
  show an indicator in the modeline. `C-. a` jumps there.
- Long prompts: `Ctrl+G` opens Claude Code's input in an Emacs buffer.
- Several agents at once: one workspace per git worktree (`SPC p p` on each).

---

## Languages

Tree-sitter modes for Python, JS, TS, TSX, JSON, CSS, C, C++, Java, Rust, Go,
Bash, YAML, TOML and Dockerfile; markdown-mode for Markdown. LSP through
Eglot, which already knows each language's usual server: install the server
and it starts when you open a file (local files only; it never complains
more than once per language when a server is missing).

```bash
npm i -g pyright typescript-language-server typescript yaml-language-server bash-language-server
rustup component add rust-analyzer
go install golang.org/x/tools/gopls@latest
sudo pacman -S clang        # clangd
```

### Tree-sitter and ABI versions

A tree-sitter mode needs a compiled grammar, and a grammar only loads if its
ABI version is one your Emacs's tree-sitter library accepts. Fetching "the
latest" grammar is how this goes wrong. This config:

- builds only the revisions **Emacs 31 itself pins** for its modes
  (`SPC c g`), which already account for older libraries;
- **loads every grammar after building it**, and deletes one that the library
  rejects;
- switches a tree-sitter mode on **only when its grammar file exists**, so
  the worst case is the classic mode, never a broken buffer.

`SPC c h` prints the ABI range your Emacs loads and each grammar's ABI. All 17
grammars were built and loaded this way against an old library (ABI 13-14).
Go, Rust, TypeScript, YAML, TOML and Dockerfile have no classic mode in
Emacs: until their grammar is built those files open as plain text, with a
hint. To keep the classic mode for a language, remove its entry from
`suhas/treesit-modes` in `local.el`.

Also in place: EditorConfig, direnv (`envrc`, when `direnv` is installed),
spellcheck in commit messages and prose (needs `aspell`), TRAMP for
`/ssh:host:/path` and `/docker:container:/path`.

---

## Modeline

Left: Emacs's status block, then Vim state, buffer, line:column, git branch.
Right: workspace, clock, 1-minute system load, diagnostics, major mode.

The status block reads like `U:**-`: `U` = UTF-8 (`-` plain ASCII, `1`
Latin-1 ...), `:` / `\` / `/` = Unix / DOS / old-Mac line endings, `**`
modified, `%%` read-only, `--` unchanged, last `-` local or `@` remote file.
Hover over any part for a description.

---

## Settings

Everything tunable is a variable in `modules/settings.el`; override it in
`local.el` (see `local.example.el`). The common ones: repo roots, font and
size, default theme, frame padding, terminal position and ESC routing, Python
server, format-on-save modes, package archives (for a company mirror).

Use `local.el` rather than `M-x customize`; `custom.el` only holds the saved
theme.

---

## Troubleshooting

**Packages did not install on the first start.** No network or a proxy. Emacs
still starts; fix the network (or set `suhas/package-archives` to a mirror)
and restart.

**A file opens as plain text.** Its grammar is missing: `SPC c g`. If the
doctor says a grammar `DOES NOT LOAD`, rebuild it with `C-u SPC c g`.

**Terminal will not start.** `SPC c h` must show dynamic modules available.
Answer `d` at the download prompt. If it still fails, delete `elpa/ghostel-*`
and restart.

**GUI Emacs cannot find a program your shell finds.** `M-x suhas/env-refresh`.

**`SPC p p` does not list a new repo.** It must be inside a repo root, at most
`suhas/repo-root-depth` levels down. `M-x suhas/project-rescan` forces a scan.

**Something behaves oddly after a package upgrade.**
`M-x package-quickstart-refresh`, restart. `SPC c d` shows what changed
against your snapshot.

**A key does nothing.** `C-h k <key>` shows what it runs in this buffer.

---

**Version 4.1** (November 2026) · Emacs 31.1+

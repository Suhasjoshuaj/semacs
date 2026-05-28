;;; README.md --- Quick start guide

# Suhas' Minimal Emacs Config

Lean, fast, and *readable*. No boilerplate. Every line has a purpose.

## Quick Start

1. **Backup your old config** (if you have one):
   ```bash
   mv ~/.config/emacs ~/.config/emacs.bak
   ```

2. **Clone/copy this config**:
   ```bash
   mkdir -p ~/.config/emacs
   # Copy files here
   ```

3. **Start Emacs**:
   ```bash
   emacs
   ```
   On first run, Emacs will download missing packages from MELPA. This takes 1-2 minutes. Be patient.

4. **Open a code file** (e.g., a Python script).
   Emacs will start the language server automatically. You should see completions after typing 2+ characters.

## Key Bindings

### Leader Key: SPACE

All leader bindings start with `SPC` (spacebar).

#### File Operations
| Key        | Action                    |
|-----------|---------------------------|
| `SPC f f` | Find file                 |
| `SPC f s` | Save current buffer       |
| `SPC f r` | Open recent file          |
| `SPC f d` | Open dired (file browser) |

#### Buffer Navigation
| Key        | Action                        |
|-----------|-------------------------------|
| `SPC SPC` | Fuzzy buffer search           |
| `SPC k`   | Kill current buffer           |
| `C-,`     | Previous buffer (smart)       |
| `C-;`     | Next buffer (smart)           |
| `M-1..9`  | Jump to workspace 1-9         |

#### Window Management
| Key       | Action              |
|-----------|-------------------|
| `SPC w h` | Move to left       |
| `SPC w j` | Move down          |
| `SPC w k` | Move up            |
| `SPC w l` | Move right         |
| `SPC w s` | Split horizontally |
| `SPC w v` | Split vertically   |
| `SPC w q` | Close window       |
| `SPC w o` | Close other windows|

#### Search & Replace
| Key       | Action              |
|-----------|-------------------|
| `SPC s s` | Search in buffer    |
| `SPC s g` | Grep project files  |
| `SPC s f` | Find file by name   |

#### Development
| Key       | Action                          |
|-----------|--------------------------------|
| `SPC e n` | Next error                      |
| `SPC e p` | Previous error                  |
| `SPC e l` | List all errors/warnings        |
| `SPC e a` | Code actions (refactor, fix)    |
| `SPC e r` | Rename symbol                   |
| `SPC e f` | Format buffer                   |
| `SPC m c` | Compile / Run build command     |

#### Workspace Management
| Key       | Action           |
|-----------|-----------------|
| `SPC a n` | New workspace    |
| `SPC a k` | Close workspace  |
| `SPC a r` | Rename workspace |
| `SPC a l` | Next workspace   |
| `SPC a h` | Prev workspace   |

#### Config
| Key       | Action                 |
|-----------|------------------------|
| `SPC c e` | Open init.el           |
| `SPC c r` | Reload config          |
| `SPC c v` | Toggle Vim mode        |
| `SPC u t` | Theme selector         |

### Vim Mode

By default, **Vim mode is enabled**. You get Evil bindings:
- `j/k/h/l` to move
- `i` to insert
- `v` for visual selection
- `d`, `y`, `p` to delete/yank/paste
- `gg`, `G` to jump to start/end

**Toggle Vim mode**: `SPC c v`

When Vim mode is **OFF**, Emacs defaults apply:
- `C-n/p` to move
- `C-a/e` for line start/end
- Standard Emacs bindings

### Terminal

- `SPC t t`: Open terminal in a split at the bottom
- `SPC t t` again: Close the terminal
- Inside terminal: `C-c C-j` to switch between char mode and line mode

If terminal gets stuck:
1. Try `C-c C-c` (send interrupt)
2. Try `C-c C-d` (send EOF)
3. Last resort: Close and reopen with `SPC t t`

## Language Servers

Supported languages: **Python, JavaScript/TypeScript, Rust, C/C++, Java**

On first use, Emacs will try to auto-find language servers. If not found:
```bash
# Python
npm install -g pyright

# JavaScript/TypeScript
npm install -g typescript-language-server

# Rust
cargo install rust-analyzer

# C/C++
apt-get install clangd  # or: brew install llvm

# Java
apt-get install jdtls  # or: download from https://github.com/eclipse/eclipse.jdt.ls/releases
```

### Code Completion
1. Start typing in a code file
2. Wait 200ms
3. A popup appears with suggestions
4. Use `C-n/p` (or `j/k` in vim) to navigate
5. Press `RET` or `TAB` to insert

### Go-to-Definition
- `M-.`: Jump to definition
- `M-*`: Jump back

### Rename Symbol
- `SPC e r`: Rename all occurrences in the file

## File Organization

```
~/.config/emacs/
├── init.el           (Entry point — loads modules)
├── early-init.el     (Startup tweaks)
└── modules/
    ├── core.el       (Package manager + defaults)
    ├── ui.el         (Theme, fonts, modeline)
    ├── completion.el (Vertico, Marginalia, Consult, Corfu)
    ├── evil.el       (Vim layer + keybindings)
    ├── terminal.el   (eat terminal)
    ├── lsp.el        (Eglot language servers)
    ├── langs.el      (Per-language config)
    ├── buffer-nav.el (Smart buffer cycling)
    ├── window-mgmt.el (Workspaces and window sizing)
    └── compile.el    (Build commands)
```

## Customization

### Change Theme
`SPC u t` opens a menu to choose from installed themes.

To add more themes, install them via `M-x package-install`, then add to `suhas/themes` in `modules/ui.el`:
```elisp
(defvar suhas/themes
  '(misterioso
    modus-vivendi
    your-new-theme))  ;; Add here
```

### Change Font
Edit `modules/ui.el`:
```elisp
(defvar suhas/font-default "Your Font Name")
(defvar suhas/font-size 110)  ;; 11pt
```

### Add Language Support
1. Install the language's major mode: `M-x package-install <lang>-mode`
2. Add config to `modules/langs.el`
3. Install the language server (see "Language Servers" section above)

### Adjust Indentation
Edit `modules/langs.el` and change `*-indent-offset` for your language.

## Troubleshooting

### Emacs is slow
1. Check if a language server is eating CPU: `M-x ps aux | grep pyright`
2. Disable slow LSP features (already done in `lsp.el`)
3. Close unused buffers: `SPC k`

### Completions don't show
1. Verify the language server is installed: `which pyright-langserver`
2. Reopen the file: `C-x C-f <file>`
3. Check M-x eglot says "connected"

### Terminal is broken
1. Try `stty sane` in the terminal
2. Or close with `SPC k` and reopen

### Theme doesn't apply
1. Make sure the theme is installed: `M-x package-list-packages`
2. Try reloading config: `SPC c r`
3. Or restart Emacs

### Vim mode feels weird
1. It's a learning curve. Give it a day.
2. Press `SPC c v` to toggle back to Emacs mode if you get stuck
3. Reference: https://vim.fandom.com/wiki/Vim_Tips_Wiki

## Performance Tips

1. **Kill unused buffers**: `SPC k` closes the current buffer. Use C-; to cycle and clean up.
2. **Use workspaces**: `SPC a n` creates a new workspace. Keeps clutter isolated.
3. **Disable LSP for large files**: If a file has 50K+ lines, LSP might lag.
4. **Check Language Server output**: `M-x eglot-show-workspace-configuration`

## Keyboard Habits

**Good vim habits for Emacs:**
- `12j` = jump 12 lines down (much faster than repeated `j`)
- `:set` = `M-x` in Emacs
- `/pattern` = `SPC s s` (search in buffer)
- `:w` = `SPC f s` (save)
- `:q` = `SPC k` (kill buffer)

**Don't break Emacs muscle memory:**
- `C-x C-f` = find file (still works!)
- `C-x C-s` = save
- `C-x C-c` = quit Emacs
- `C-_` = undo

## Learning Path

1. **Week 1**: Get comfortable with vim motions (`hjkl`, `i`, `v`, `d`, `y`, `p`)
2. **Week 2**: Learn leader bindings (`SPC` + key)
3. **Week 3**: Master search (`SPC s s`, `SPC s g`)
4. **Week 4**: Code navigation (`M-.`, `SPC e n`, `SPC e a`)

## Questions?

- Each module file is heavily commented. Read them!
- Emacs built-in help: `C-h f` (function), `C-h k` (key), `C-h m` (mode)
- https://www.gnu.org/software/emacs/manual/

---

**Config version**: 1.0 (May 2026)
**Emacs version required**: 27.1+ (29+ recommended for tree-sitter)

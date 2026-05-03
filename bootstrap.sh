#!/usr/bin/env bash
# bootstrap.sh — Fresh machine setup for suhas.emacs
# Run this once after cloning your config repo.
# Works on: Arch, Ubuntu/Debian, Fedora, macOS (brew)
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh

set -e  # Exit on any error

echo "==> Detecting OS..."

if command -v pacman &>/dev/null; then
    OS="arch"
elif command -v apt &>/dev/null; then
    OS="debian"
elif command -v dnf &>/dev/null; then
    OS="fedora"
elif command -v brew &>/dev/null; then
    OS="macos"
else
    echo "ERROR: Unknown OS. Install dependencies manually."
    exit 1
fi

echo "    OS: $OS"

# ── Package install helper ─────────────────────────────────────
install_pkg() {
    case $OS in
        arch)    sudo pacman -S --noconfirm "$@" ;;
        debian)  sudo apt install -y "$@" ;;
        fedora)  sudo dnf install -y "$@" ;;
        macos)   brew install "$@" ;;
    esac
}

# ── Emacs ──────────────────────────────────────────────────────
echo "==> Checking Emacs..."
if ! command -v emacs &>/dev/null; then
    echo "    Installing Emacs..."
    case $OS in
        arch)   install_pkg emacs ;;
        debian) install_pkg emacs ;;
        fedora) install_pkg emacs ;;
        macos)  brew install --cask emacs ;;
    esac
else
    echo "    Emacs already installed: $(emacs --version | head -1)"
fi

# ── Nerd Fonts ─────────────────────────────────────────────────
echo "==> Installing JetBrains Mono Nerd Font..."
case $OS in
    arch)
        if ! fc-list | grep -qi "JetBrainsMono"; then
            install_pkg ttf-jetbrains-mono-nerd
        else
            echo "    Font already installed."
        fi
        ;;
    debian|fedora)
        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"
        if ! fc-list | grep -qi "JetBrainsMono"; then
            echo "    Downloading JetBrains Mono Nerd Font..."
            curl -fLo "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" \
                "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Menlo/Regular/JetBrainsMonoNerdFontMono-Regular.ttf"
            fc-cache -fv "$FONT_DIR"
        else
            echo "    Font already installed."
        fi
        ;;
    macos)
        brew tap homebrew/cask-fonts
        brew install --cask font-jetbrains-mono-nerd-font
        ;;
esac

# ── Core tools ─────────────────────────────────────────────────
echo "==> Installing core tools..."
case $OS in
    arch)   install_pkg git curl ripgrep fd fzf ;;
    debian) install_pkg git curl ripgrep fd-find fzf ;;
    fedora) install_pkg git curl ripgrep fd-find fzf ;;
    macos)  install_pkg git curl ripgrep fd fzf ;;
esac

# ── Language Servers ───────────────────────────────────────────
echo "==> Installing language servers..."

# Node.js (needed for most LSP servers)
if ! command -v node &>/dev/null; then
    echo "    Installing Node.js via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
else
    echo "    Node already installed: $(node --version)"
fi

# TypeScript language server (JS + TS)
echo "    Installing typescript-language-server..."
npm install -g typescript typescript-language-server

# Pyright (Python)
echo "    Installing pyright..."
npm install -g pyright

# clangd (C/C++) — comes with clang/llvm
if ! command -v clangd &>/dev/null; then
    echo "    Installing clangd..."
    case $OS in
        arch)   install_pkg clang ;;
        debian) install_pkg clangd ;;
        fedora) install_pkg clang-tools-extra ;;
        macos)  install_pkg llvm ;;
    esac
else
    echo "    clangd already installed."
fi

# jdtls (Java) — requires Java 17+
if command -v java &>/dev/null; then
    echo "    Installing jdtls via npm..."
    npm install -g @angular/language-server  # pulls jdtls dep
else
    echo "    WARNING: Java not found. Install JDK 17+ manually for Java LSP."
    echo "    Arch: sudo pacman -S jdk17-openjdk"
    echo "    Debian: sudo apt install openjdk-17-jdk"
fi

# ── Python tools ───────────────────────────────────────────────
echo "==> Installing Python tools..."
pip3 install --user black   # formatter used in langs.el

# ── File viewer tools (used in dired.el) ──────────────────────
echo "==> Installing file viewer tools..."
case $OS in
    arch)
        install_pkg feh mpv zathura zathura-pdf-mupdf
        ;;
    debian)
        install_pkg feh mpv zathura
        ;;
    fedora)
        install_pkg feh mpv zathura
        ;;
    macos)
        echo "    Skipping feh/zathura on macOS. Update dired-open-extensions manually."
        ;;
esac

# ── Pandoc (markdown export) ───────────────────────────────────
if ! command -v pandoc &>/dev/null; then
    install_pkg pandoc
fi

# ── Done ───────────────────────────────────────────────────────
echo ""
echo "✓ Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Start Emacs — elpaca will install packages on first launch"
echo "  2. Wait for elpaca to finish (watch the *Messages* buffer)"
echo "  3. Restart Emacs once after first install"
echo ""
echo "  If treesitter grammars are missing, run:"
echo "  M-x treesit-install-language-grammar"
echo ""

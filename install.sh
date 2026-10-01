u#!/bin/sh
# Bootstrap Neovim + your LazyVim config under a custom NVIM_APPNAME.
# Usage: curl -fsSL https://nvim.yourdomain.com | sh
#        curl -fsSL https://nvim.yourdomain.com | NVIM_APPNAME=work sh
set -eu

APP="${NVIM_APPNAME:-lazyvim}"
REPO="${NVIM_REPO:-https://github.com/euick0/nvim-config.git}" # <- change this
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/$APP"
BIN="$HOME/.local/bin"
export PATH="$BIN:$PATH"

say() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

install_deps() {
  say "Installing dependencies"
  if has brew; then
    brew install git ripgrep fd neovim
  elif has apt-get; then
    $SUDO apt-get update
    $SUDO apt-get install -y git curl ripgrep fd-find build-essential unzip
  elif has dnf; then
    $SUDO dnf install -y git curl ripgrep fd-find gcc make unzip
  elif has pacman; then
    $SUDO pacman -Sy --needed --noconfirm git curl ripgrep fd base-devel unzip neovim
  else
    echo "Unknown package manager: install git, ripgrep, fd and a C compiler manually."
  fi
  # Debian/Ubuntu ship fd as 'fdfind'
  if has fdfind && ! has fd; then
    mkdir -p "$BIN"
    ln -sf "$(command -v fdfind)" "$BIN/fd"
  fi
}

install_nvim() {
  if has nvim && nvim --headless -u NONE -c 'if has("nvim-0.11.2")|qa|else|cq|endif' 2>/dev/null; then
    say "Neovim is recent enough"
    return
  fi
  if [ "$(uname -s)" != "Linux" ]; then
    echo "Please install Neovim 0.11.2+ manually."
    exit 1
  fi
  case "$(uname -m)" in
  x86_64) ARCH=x86_64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *)
    echo "Unsupported architecture: $(uname -m)"
    exit 1
    ;;
  esac
  say "Installing latest Neovim into ~/.local"
  mkdir -p "$HOME/.local" "$BIN"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$ARCH.tar.gz" |
    tar -xz -C "$HOME/.local"
  ln -sf "$HOME/.local/nvim-linux-$ARCH/bin/nvim" "$BIN/nvim"
}

clone_config() {
  if [ -d "$CONFIG/.git" ]; then
    say "Updating config in $CONFIG"
    git -C "$CONFIG" pull --ff-only
  elif [ -e "$CONFIG" ]; then
    echo "$CONFIG exists and is not a git repo; move it away first."
    exit 1
  else
    say "Cloning config into $CONFIG"
    git clone "$REPO" "$CONFIG"
  fi
}

setup_shell() {
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ]; then
      if ! grep -qF 'HOME/.local/bin' "$rc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$rc"
      fi
      if ! grep -qF "alias lv=" "$rc"; then
        echo "alias lv='NVIM_APPNAME=$APP nvim'" >>"$rc"
      fi
    fi
  done
}

install_plugins() {
  say "Installing plugins (first run)"
  NVIM_APPNAME="$APP" nvim --headless "+Lazy! sync" +qa || true
}

install_deps
install_nvim
clone_config
setup_shell
install_plugins
say "Done. Open a new shell and run: lv"

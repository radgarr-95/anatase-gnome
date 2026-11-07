FROM i.anatase.org/base:stable

# NOTE: every generated file below uses  printf '%s\n' 'line' 'line' > file
# Each line is its own single-quoted argument, so $, \, " and % stay literal.
# Lines that need a single quote use a double-quoted argument instead.

# ============================================================
# REPOSITORIES
# ============================================================

# Terra (Ghostty, CoolerControl, Zen Browser, Mission Center, etc.)
RUN curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
    -o /etc/yum.repos.d/terra.repo

# RPM Fusion (Steam/VLC)
RUN dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ============================================================
# SYSTEM PACKAGES
# ============================================================

RUN dnf -y --setopt=install_weak_deps=False install \
    # GNOME desktop & extensions app
    dconf \
    gdm \
    gnome-control-center \
    gnome-initial-setup \
    gnome-session-wayland-session \
    gnome-settings-daemon \
    gnome-shell \
    gnome-extensions-app \
    nautilus \
    totem \
    # GNOME core apps
    gnome-text-editor \
    baobab \
    loupe \
    # Terminal and shell
    ghostty \
    fish \
    # CLI utilities
    neovim \
    oh-my-posh \
    eza \
    fzf \
    ripgrep \
    zoxide \
    uv \
    # System utilities & downloaders
    procps-ng \
    curl \
    wget \
    git \
    gcc \
    make \
    file \
    bzip2 \
    unzip \
    glib2-devel \
    # Media Writer
    mediawriter \
    # Hardware and device support
    liquidctl \
    fprintd-pam \
    gnome-bluetooth \
    # Authentication and portals
    oo7-daemon \
    oo7-portal \
    pam_oo7 \
    gnome-user-share \
    # GVFS support
    gvfs-afc \
    gvfs-fuse \
    gvfs-goa \
    gvfs-gphoto2 \
    gvfs-mtp \
    gvfs-smb \
    # GNOME integration
    localsearch \
    NetworkManager-libreswan-gnome \
    NetworkManager-openconnect-gnome \
    NetworkManager-openvpn-gnome \
    NetworkManager-ppp \
    NetworkManager-ssh-gnome \
    sushi \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    xdg-user-dirs-gtk \
    glycin-thumbnailer \
    gnome-backgrounds \
    gnome-browser-connector \
    gnome-clocks \
    gnome-color-manager \
    gnome-disk-utility \
    gnome-epub-thumbnailer \
    gnome-logs \
    # GNOME extensions and themes
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-user-theme \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-gsconnect \
    gnome-shell-extension-logo-menu \
    adw-gtk3-theme \
    # Phosh mobile desktop
    phosh \
    phoc \
    phosh-mobile-settings \
    # Applications (Terra / base / RPM Fusion)
    coolercontrol \
    mission-center \
    zen-browser \
    heroic-games-launcher \
    qbittorrent \
    libreoffice \
    vlc \
    g4music \
    peazip \
    # Build dependencies
    meson \
    ninja-build \
    nodejs \
    npm \
    # Video playback support
    gstreamer1-plugin-gtk4 \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugin-libav \
    && dnf clean all

# Optional: remove other terminals so nothing falls back to them
# RUN dnf -y remove ptyxis gnome-terminal gnome-console || true

# ============================================================
# GHOSTTY (DEFAULT TERMINAL)
# ============================================================

# Plain config: Ghostty opens your shell (fish), not nvim
RUN mkdir -p /etc/skel/.config/ghostty && \
    printf '%s\n' 'command = /usr/bin/fish' 'shell-integration = fish' > /etc/skel/.config/ghostty/config

# xdg-terminal-exec list (used by newer apps/portals)
RUN printf '%s\n' 'com.mitchellh.ghostty.desktop' > /etc/xdg/xdg-terminals.list

# Fail the build early if the Ghostty desktop file is not where we expect
RUN ls /usr/share/applications | grep -i ghostty

# ============================================================
# FISH (oh-my-posh prompt + Homebrew)
# System-wide files in /etc/fish/conf.d apply to every user, including
# ones created before this image, and load before ~/.config/fish/config.fish
# so users can still override them.
# ============================================================

# Ship the if_tea theme inside the image (no network needed at shell start)
RUN mkdir -p /usr/share/oh-my-posh/themes && \
    curl -fsSL https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/if_tea.omp.json \
        -o /usr/share/oh-my-posh/themes/if_tea.omp.json

RUN mkdir -p /etc/fish/conf.d && \
    printf '%s\n' \
        'if status is-interactive; and command -q oh-my-posh' \
        '    oh-my-posh init fish --config /usr/share/oh-my-posh/themes/if_tea.omp.json | source' \
        'end' \
        > /etc/fish/conf.d/10-oh-my-posh.fish && \
    printf '%s\n' \
        '# Checked on every shell start, so Homebrew is picked up as soon as Complete Setup has installed it' \
        'if test -x /home/linuxbrew/.linuxbrew/bin/brew' \
        '    /home/linuxbrew/.linuxbrew/bin/brew shellenv fish | source' \
        'end' \
        > /etc/fish/conf.d/20-homebrew.fish

# ============================================================
# DESKTOP ENTRIES
# ============================================================

# Manual first-boot setup launcher (runs inside Ghostty, asks for sudo password)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Complete Setup' \
    'GenericName=System Setup' \
    'Comment=Install Homebrew, Flatpaks and LazyVim, then switch to the fish shell' \
    'Exec=ghostty -e /bootstrap/complete-setup.sh' \
    'Icon=system-software-install' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;Settings;' \
    'StartupNotify=true' \
    > /usr/share/applications/completesetup.desktop

# Neovim launcher (runs inside Ghostty)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Neovim' \
    'GenericName=Text Editor' \
    'Comment=Edit text files in Ghostty' \
    'Icon=nvim' \
    'Exec=ghostty -e nvim %F' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=Utility;TextEditor;' \
    'MimeType=text/plain;' \
    'StartupNotify=true' \
    > /usr/share/applications/nvim.desktop

# Decky Loader installer (runs inside Ghostty)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Install Decky Loader' \
    'GenericName=Plugin Loader' \
    'Comment=Install the official Decky plugin loader' \
    'Icon=applications-games' \
    'Exec=ghostty -e bash -c "curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | bash; echo Press Enter to close; read"' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;' \
    > /usr/share/applications/install-decky.desktop

# Punktfunk server (for using the OS as a headless gaming server); runs inside Ghostty
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Install Punktfunk Server' \
    'GenericName=Game Streaming Server' \
    'Comment=Install the punktfunk server system extension (headless gaming server use)' \
    'Icon=network-server' \
    'Exec=ghostty -e /bootstrap/install-punktfunk-sysext.sh --pause' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;' \
    > /usr/share/applications/install-punktfunk-server.desktop

# Bold Brew menu entry (shipped in the image; the binary arrives after Complete Setup)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Bold Brew' \
    'GenericName=Package Manager TUI' \
    'Comment=Modern Terminal UI for managing Homebrew packages' \
    'Icon=package-x-generic' \
    'Exec=ghostty -e /home/linuxbrew/.linuxbrew/bin/bbrew' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;Settings;PackageManager;' \
    'StartupNotify=true' \
    > /usr/share/applications/bold-brew.desktop

# ============================================================
# GNOME EXTENSIONS
# Folder name MUST equal the uuid in metadata.json, so we read it
# from each zip instead of guessing.
# ============================================================

RUN set -eux; \
    EXT=/usr/share/gnome-shell/extensions; \
    install_ext() { \
        tmp=$(mktemp -d); \
        unzip -q "$1" -d "$tmp"; \
        uuid=$(sed -n 's/.*"uuid"[^"]*"\([^"]*\)".*/\1/p' "$tmp/metadata.json" | head -n1); \
        test -n "$uuid"; \
        mkdir -p "$EXT/$uuid"; \
        cp -r "$tmp"/. "$EXT/$uuid/"; \
        if [ -d "$EXT/$uuid/schemas" ] && [ ! -f "$EXT/$uuid/schemas/gschemas.compiled" ]; then \
            glib-compile-schemas "$EXT/$uuid/schemas"; \
        fi; \
        chmod -R u+rwX,go+rX,go-w "$EXT/$uuid"; \
        echo "installed $uuid: $(tr -d ' \n' < "$EXT/$uuid/metadata.json" | grep -o '"shell-version":\[[^]]*\]' || echo 'no shell-version field')"; \
        rm -rf "$tmp"; \
    }; \
    wget -q -O /tmp/bmw.zip "https://github.com/Schneegans/Burn-My-Windows/releases/latest/download/burn-my-windows@schneegans.github.com.zip"; \
    install_ext /tmp/bmw.zip; \
    # Dynamically fetch the correct versioned zip URL for o-tiling using GitHub API with a User-Agent
    url=$(curl -sSL -H "User-Agent: containerfile-builder" https://api.github.com/repos/oliwebd/o-tiling/releases/latest | grep -o '"browser_download_url": *"[^"]*o-tiling[^"]*\.zip"' | head -n1 | cut -d'"' -f4); \
    test -n "$url"; \
    wget -q -O /tmp/otiling.zip "$url"; \
    install_ext /tmp/otiling.zip; \
    rm -f /tmp/*.zip; \
    echo "Installed extensions:"; ls -l "$EXT"

# ============================================================
# DCONF DEFAULTS (extensions enabled + Ghostty default terminal)
# ============================================================

RUN mkdir -p /etc/dconf/profile /etc/dconf/db/local.d && \
    printf '%s\n' 'user-db:user' 'system-db:local' > /etc/dconf/profile/user && \
    printf '%s\n' \
        '[org/gnome/desktop/applications/terminal]' \
        "exec='ghostty'" \
        "exec-arg='-e'" \
        '' \
        '[org/gnome/settings-daemon/plugins/media-keys]' \
        "terminal=['<Primary><Alt>t']" \
        > /etc/dconf/db/local.d/01-terminal

# Enable every extension installed in the image, then compile the dconf db
RUN exts=$(ls /usr/share/gnome-shell/extensions | sed "s/.*/'&'/" | paste -sd,) && \
    printf '%s\n' '[org/gnome/shell]' "enabled-extensions=[$exts]" > /etc/dconf/db/local.d/00-extensions && \
    dconf update

# ============================================================
# SETUP SCRIPT: HOMEBREW + BOLD BREW (run from Complete Setup)
# ============================================================

RUN mkdir -p /bootstrap

# Part that runs as the unprivileged user who started Complete Setup
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'export PATH=/home/linuxbrew/bin:$PATH' \
    'export NONINTERACTIVE=1' \
    '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
    'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' \
    'brew tap Valkyrie00/homebrew-bbrew' \
    'brew trust Valkyrie00/bbrew' \
    'brew install bbrew' \
    > /bootstrap/brew-as-user.sh

# Part that runs as root (via sudo): Homebrew ends up owned by the user who ran it
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'exec > >(tee -a /var/log/install-brew.log) 2>&1' \
    'USER_NAME="${SUDO_USER:-}"' \
    'if [ -z "$USER_NAME" ] || [ "$USER_NAME" = root ]; then echo "Run this with sudo from your normal user account."; exit 1; fi' \
    'GROUP_NAME="$(id -gn "$USER_NAME")"' \
    'mkdir -p /home/linuxbrew/bin /home/linuxbrew/.linuxbrew' \
    'printf "#!/bin/bash\nexec \"\$@\"\n" > /home/linuxbrew/bin/sudo' \
    'chmod +x /home/linuxbrew/bin/sudo' \
    'chown -R "$USER_NAME:$GROUP_NAME" /home/linuxbrew' \
    'if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then echo "Homebrew already installed; ownership set to $USER_NAME."; exit 0; fi' \
    'su - "$USER_NAME" -c "bash /bootstrap/brew-as-user.sh"' \
    > /bootstrap/install-brew.sh && \
    chmod +x /bootstrap/install-brew.sh

# ============================================================
# SETUP SCRIPT: FLATPAKS (run from Complete Setup)
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'exec > >(tee -a /var/log/install-flatpaks.log) 2>&1' \
    'flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' \
    'flatpak install --system --assumeyes flathub org.localsend.localsend_app io.github.swordpuffin.rewaita com.mattjakeman.ExtensionManager io.github.flattool.Warehouse io.ente.auth com.github.vladimiry.ElectronMail io.github.kolunmi.Bazaar com.github.tchx84.Flatseal it.mijorus.gearlever io.freetubeapp.FreeTube org.signal.Signal io.github.Foldex.AdwSteamGtk page.codeberg.libre_menu_editor.LibreMenuEditor org.jellyfin.JellyfinDesktop io.github.ilya_zlobintsev.LACT net.jami.Jami page.tesk.Refine org.gnome.Characters org.gnome.font-viewer io.github.flattool.Ignition' \
    'flatpak install --system --assumeyes https://flatpak.unom.io/io.unom.punktfunk.flatpakref' \
    > /bootstrap/install-flatpaks.sh && \
    chmod +x /bootstrap/install-flatpaks.sh

# ============================================================
# SETUP SCRIPT: LAZYVIM (runs as your user, from Complete Setup)
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'if [ -n "$(ls -A "$HOME/.config/nvim" 2>/dev/null)" ]; then' \
    '    echo "Existing Neovim config found in ~/.config/nvim, leaving it alone."' \
    '    exit 0' \
    'fi' \
    'git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"' \
    'rm -rf "$HOME/.config/nvim/.git"' \
    'nvim --headless "+Lazy! sync" +qa || true' \
    'echo "LazyVim installed."' \
    > /bootstrap/install-lazyvim.sh && \
    chmod +x /bootstrap/install-lazyvim.sh

# ============================================================
# SETUP SCRIPT: SWITCH LOGIN SHELL TO FISH (runs as your user)
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'if [ "$(getent passwd "$(id -un)" | cut -d: -f7)" = /usr/bin/fish ]; then' \
    '    echo "Already using fish."' \
    '    exit 0' \
    'fi' \
    'chsh -s /usr/bin/fish' \
    'echo "Login shell changed to fish. Log out and back in to apply it."' \
    > /bootstrap/set-fish-shell.sh && \
    chmod +x /bootstrap/set-fish-shell.sh

# ============================================================
# SETUP SCRIPT: GNOME EXTENSIONS FROM extensions.gnome.org (runs as your user)
# 6281 Wallpaper Slideshow, 10372 System Monitor, 8102 TouchUp
# Installs to ~/.local/share/gnome-shell/extensions and adds them to the
# enabled list; they load after the next log out / log in.
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'q=$(printf "\047")' \
    'ver=$(gnome-shell --version)' \
    'ver=${ver##* }' \
    'shellver=${ver%%.*}' \
    'echo "GNOME Shell major version: $shellver"' \
    'tmp=$(mktemp -d)' \
    'for pk in 6281 10372 8102; do' \
    '    info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?pk=$pk&shell_version=$shellver")' \
    '    path=$(printf "%s" "$info" | grep -o "\"download_url\": *\"[^\"]*\"" | head -n1 | cut -d"\"" -f4)' \
    '    if [ -z "$path" ]; then echo "No build of extension $pk for GNOME Shell $shellver, skipping."; continue; fi' \
    '    curl -fsSL -o "$tmp/$pk.zip" "https://extensions.gnome.org$path"' \
    '    uuid=$(unzip -p "$tmp/$pk.zip" metadata.json | sed -n "s/.*\"uuid\"[^\"]*\"\([^\"]*\)\".*/\1/p" | head -n1)' \
    '    test -n "$uuid"' \
    '    dest="$HOME/.local/share/gnome-shell/extensions/$uuid"' \
    '    mkdir -p "$dest"' \
    '    unzip -oq "$tmp/$pk.zip" -d "$dest"' \
    '    if [ -d "$dest/schemas" ] && [ ! -f "$dest/schemas/gschemas.compiled" ]; then glib-compile-schemas "$dest/schemas"; fi' \
    '    cur=$(gsettings get org.gnome.shell enabled-extensions)' \
    '    cur=${cur#@as }' \
    '    case "$cur" in' \
    '        *"$q$uuid$q"*) ;;' \
    '        "[]") gsettings set org.gnome.shell enabled-extensions "[$q$uuid$q]" ;;' \
    '        *) gsettings set org.gnome.shell enabled-extensions "${cur%]}, $q$uuid$q]" ;;' \
    '    esac' \
    '    echo "Installed $uuid (supports: $(tr -d " \n" < "$dest/metadata.json" | grep -o "\"shell-version\":\[[^]]*\]" || echo unknown))"' \
    'done' \
    'rm -rf "$tmp"' \
    'echo "Extensions installed. Log out and back in to load them."' \
    > /bootstrap/install-extensions.sh && \
    chmod +x /bootstrap/install-extensions.sh

# ============================================================
# OPTIONAL: PUNKTFUNK SERVER (systemd sysext) for headless gaming servers
# Not part of Complete Setup. Run it from the "Install Punktfunk Server"
# menu entry, or over SSH with:  /bootstrap/install-punktfunk-sysext.sh
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'tmp=$(mktemp -d)' \
    'cd "$tmp"' \
    'if curl -fsSLO https://git.unom.io/unom/punktfunk/raw/branch/main/packaging/bazzite/punktfunk-sysext.sh && sudo bash punktfunk-sysext.sh install; then' \
    '    echo "Punktfunk server installed."' \
    'else' \
    '    echo "Punktfunk server install failed."' \
    'fi' \
    'cd /' \
    'rm -rf "$tmp"' \
    'if [ "${1:-}" = "--pause" ]; then echo; echo "Press Enter to close."; read -r _; fi' \
    > /bootstrap/install-punktfunk-sysext.sh && \
    chmod +x /bootstrap/install-punktfunk-sysext.sh

# ============================================================
# COMPLETE SETUP WRAPPER (launched by the Complete Setup desktop entry)
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'echo "=== Running Homebrew Setup ==="' \
    'sudo /bootstrap/install-brew.sh' \
    'echo "=== Running Flatpak Setup ==="' \
    'sudo /bootstrap/install-flatpaks.sh' \
    'echo "=== Installing GNOME extensions ==="' \
    '/bootstrap/install-extensions.sh' \
    'echo "=== Setting up LazyVim ==="' \
    '/bootstrap/install-lazyvim.sh' \
    'echo "=== Switching login shell to fish ==="' \
    '/bootstrap/set-fish-shell.sh' \
    'echo' \
    'echo "Setup complete! Log out and back in for extensions and the shell change. Press Enter to close."' \
    'read -r _' \
    > /bootstrap/complete-setup.sh && \
    chmod +x /bootstrap/complete-setup.sh

# ============================================================
# DEFAULT SHELL & BOOT TARGET
# ============================================================

# fish for newly created users (chsh only affects root inside the image)
RUN sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    chsh -s /usr/bin/fish

RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target

# ============================================================
# CLEANUP (LEAVE THIS HERE)
# ============================================================

RUN rm -rf /var/ && \
    mkdir -p /var/tmp /var/log /var/lib /var

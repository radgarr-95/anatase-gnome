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
    gnome-characters \
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
    printf '%s\n' 'shell-integration = fish' > /etc/skel/.config/ghostty/config

# xdg-terminal-exec list (used by newer apps/portals)
RUN printf '%s\n' 'com.mitchellh.ghostty.desktop' > /etc/xdg/xdg-terminals.list

# Fail the build early if the Ghostty desktop file is not where we expect
RUN ls /usr/share/applications | grep -i ghostty

# LAZYVIM STARTER CONFIGURATION
# ============================================================

# Clone the LazyVim starter template into /etc/skel so every new user gets it
RUN git clone https://github.com/LazyVim/starter /etc/skel/.config/nvim && \
    # Remove the .git folder so users can track their own config changes later if desired
    rm -rf /etc/skel/.config/nvim/.git


# ============================================================
# DESKTOP ENTRIES
# ============================================================

# Manual First-Boot Setup Launcher (Runs inside Ghostty with sudo password prompt)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Complete Setup' \
    'GenericName=System Setup' \
    'Comment=Manually run Homebrew and Flatpak first-boot installation scripts' \
    'Exec=ghostty -e bash -c "echo \"=== Running Homebrew Setup ===\"; sudo /bootstrap/install-brew.sh; echo \"=== Running Flatpak Setup ===\"; sudo /bootstrap/install-flatpaks.sh; echo \"\nSetup complete! Press Enter to close.\"; read"' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;Settings;' \
    'StartupNotify=true' \
    > /usr/share/applications/complete-setup.desktop

# Neovim launcher (runs inside Ghostty)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Neovim' \
    'GenericName=Text Editor' \
    'Comment=Edit text files in Ghostty' \
    'Exec=ghostty -e nvim %F' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=Utility;TextEditor;' \
    'MimeType=text/plain;' \
    'StartupNotify=true' \
    > /usr/share/applications/nvim.desktop

# Decky Loader installer (Runs inside Ghostty)

RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Install Decky Loader' \
    'GenericName=Plugin Loader' \
    'Comment=Install the official Decky plugin loader' \
    'Exec=ghostty -e bash -c "curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | bash; echo Press Enter to close; read"' \
    'Terminal=false' \
    'Type=Application' \
    'Categories=System;' \
    > /usr/share/applications/install-decky.desktop

# Bold Brew menu entry (shipped in the image; the binary arrives at first boot)
RUN printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Bold Brew' \
    'GenericName=Package Manager TUI' \
    'Comment=Modern Terminal UI for managing Homebrew packages' \
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
    echo "Installed extensions:"; ls "$EXT"

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
# FIRST-BOOT: HOMEBREW + BOLD BREW (root systemd oneshot)
# ============================================================

RUN mkdir -p /bootstrap

# Part that runs as the unprivileged linuxbrew user
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

# Part that runs as root
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'exec > >(tee -a /var/log/install-brew.log) 2>&1' \
    'if [ -d /home/linuxbrew/.linuxbrew ]; then exit 0; fi' \
    'id linuxbrew &>/dev/null || useradd -m -s /bin/bash linuxbrew' \
    'mkdir -p /home/linuxbrew/bin' \
    'printf "#!/bin/bash\nexec \"\$@\"\n" > /home/linuxbrew/bin/sudo' \
    'chmod +x /home/linuxbrew/bin/sudo' \
    'chown -R linuxbrew:linuxbrew /home/linuxbrew' \
    'su - linuxbrew -c "bash /bootstrap/brew-as-user.sh"' \
    > /bootstrap/install-brew.sh && \
    chmod +x /bootstrap/install-brew.sh

RUN printf '%s\n' \
    '[Unit]' \
    'Description=Install Homebrew and Bold Brew (first boot)' \
    'After=network-online.target' \
    'Wants=network-online.target' \
    'ConditionPathExists=!/home/linuxbrew/.linuxbrew' \
    '' \
    '[Service]' \
    'Type=oneshot' \
    'ExecStart=/bootstrap/install-brew.sh' \
    'TimeoutStartSec=infinity' \
    '' \
    '[Install]' \
    'WantedBy=multi-user.target' \
    > /etc/systemd/system/install-brew.service

# ============================================================
# FIRST-BOOT: FLATPAKS (root systemd oneshot)
# ============================================================

RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -euo pipefail' \
    'exec > >(tee -a /var/log/install-flatpaks.log) 2>&1' \
    'flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' \
    'flatpak install --system --assumeyes flathub org.localsend.localsend_app io.github.swordpuffin.rewaita com.mattjakeman.ExtensionManager io.github.flattool.Warehouse io.ente.auth com.github.vladimiry.ElectronMail io.github.kolunmi.Bazaar com.github.tchx84.Flatseal it.mijorus.gearlever io.freetubeapp.FreeTube org.signal.Signal io.github.Foldex.AdwSteamGtk page.codeberg.libre_menu_editor.LibreMenuEditor com.github.iwalton3.jellyfin-media-player io.github.ilya_zlobintsev.LACT net.jami.Jami page.tesk.Refine ' \
    'flatpak install --system --assumeyes https://flatpak.unom.io/io.unom.punktfunk.flatpakref' \
    > /bootstrap/install-flatpaks.sh && \
    chmod +x /bootstrap/install-flatpaks.sh

RUN printf '%s\n' \
    '[Unit]' \
    'Description=Install default Flatpaks (first boot)' \
    'After=network-online.target' \
    'Wants=network-online.target' \
    'ConditionPathExists=!/var/lib/flatpaks-installed' \
    '' \
    '[Service]' \
    'Type=oneshot' \
    'ExecStart=/bootstrap/install-flatpaks.sh' \
    'ExecStartPost=/usr/bin/touch /var/lib/flatpaks-installed' \
    'TimeoutStartSec=infinity' \
    '' \
    '[Install]' \
    'WantedBy=multi-user.target' \
    > /etc/systemd/system/install-flatpaks.service

RUN systemctl enable install-brew.service install-flatpaks.service

# ============================================================
# DEFAULT SHELL & BOOT TARGET
# ============================================================

# fish for newly created users (chsh only affects root inside the image)
RUN sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd && \
    chsh -s /usr/bin/fish

RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target

#============================================================
#CLEANUP (LEAVE THIS HERE)
#============================================================

RUN rm -rf /var/ && \
mkdir -p /var/tmp /var/log /var/lib /var



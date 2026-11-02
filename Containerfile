FROM i.anatase.org/base:stable

# ============================================================
# REPOSITORIES
# ============================================================

# Add Terra repository (provides Ghostty, CoolerControl, Zen Browser, Mission Center, etc.)
RUN curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
    -o /etc/yum.repos.d/terra.repo

# Enable RPM Fusion repositories for Steam
RUN dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ============================================================
# SYSTEM PACKAGES
# ============================================================

RUN dnf -y --setopt=install_weak_deps=False install \
    # GNOME desktop
    dconf \
    gdm \
    gnome-control-center \
    gnome-initial-setup \
    gnome-session-wayland-session \
    gnome-settings-daemon \
    gnome-shell \
    nautilus \
    # Terminal and shell
    ghostty \
    fish \
    # System utilities
    procps-ng \
    curl \
    git \
    gcc \
    make \
    file \
    bzip2 \
    unzip \
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
    # Additional applications (from Terra / base)
    coolercontrol \
    mission-center \
    zen-browser \
    heroic-games-launcher \
    # Hanabi build dependencies
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


# ============================================================
# HOMEBREW, BOLD BREW & CLI UTILS
# ============================================================

# Install using a dedicated non-root user (Homebrew requirement)
RUN useradd -m -s /bin/bash linuxbrew

USER linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/linuxbrew/bin:${PATH}"

# Create a mock 'sudo' in user space so installer scripts don't crash on sudo checks
RUN mkdir -p /home/linuxbrew/bin && \
    printf '#!/bin/bash\n"$@"\n' > /home/linuxbrew/bin/sudo && \
    chmod +x /home/linuxbrew/bin/sudo

# 1. Install official Homebrew non-interactively
RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Bold Brew using its official installer script
RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Valkyrie00/bold-brew/main/install.sh)"

# 3. Install Neovim and requested CLI utilities via standard brew
RUN brew install \
    neovim \
    oh-my-posh \
    eza \
    fzf \
    ripgrep \
    zoxide \
    yazi \
    uv

# 4. Clone LazyVim starter template directly into Homebrew's config path
RUN mkdir -p ~/.config && \
    git clone https://github.com/LazyVim/starter ~/.config/nvim && \
    rm -rf ~/.config/nvim/.git

USER root

# Expose Homebrew globally
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Create desktop entries for Neovim and Bold Brew using safe printf strings
RUN mkdir -p /usr/share/applications && \
    printf '[Desktop Entry]\nName=Neovim\nGenericName=Text Editor\nComment=Edit text files using Neovim\nExec=ghostty -e nvim %%F\nTerminal=false\nType=Application\nCategories=Utility;TextEditor;Development;\nStartupNotify=true\nMimeType=text/plain;inode/directory;\n' > /usr/share/applications/nvim.desktop

RUN printf '[Desktop Entry]\nName=Bold Brew\nGenericName=Package Manager TUI\nComment=Modern Terminal UI for managing Homebrew packages\nExec=ghostty -e bbrew\nTerminal=false\nType=Application\nCategories=System;Settings;PackageManager;\nStartupNotify=true\n' > /usr/share/applications/bold-brew.desktop


# ============================================================
# HANABI GNOME LIVE WALLPAPER EXTENSION
# ============================================================

RUN git clone --depth 1 \
    https://github.com/jeffshee/gnome-ext-hanabi.git \
    /tmp/hanabi && \
    mkdir -p /tmp/hanabi-home /tmp/hanabi-npm-cache && \
    HOME=/tmp/hanabi-home \
    npm_config_cache=/tmp/hanabi-npm-cache \
    make -C /tmp/hanabi install && \
    install -d /usr/share/gnome-shell/extensions && \
    test -d /tmp/hanabi-home/.local/share/gnome-shell/extensions/hanabi-extension@jeffshee.github.io && \
    cp -a \
        /tmp/hanabi-home/.local/share/gnome-shell/extensions/hanabi-extension@jeffshee.github.io \
        /usr/share/gnome-shell/extensions/ && \
    rm -rf /tmp/hanabi /tmp/hanabi-home /tmp/hanabi-npm-cache


# ============================================================
# DEFAULT SHELL
# ============================================================

RUN chsh -s /usr/bin/fish


# ============================================================
# DISPLAY MANAGER AND BOOT
# ============================================================

RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target


# ============================================================
# CLEANUP (LEAVE THIS HERE)
# ============================================================

RUN rm -rf /var && \
    mkdir -p /var/tmp 


# ============================================================
# FLATPAK APPLICATIONS
# ============================================================

RUN flatpak remote-add --system --if-not-exists \
    flathub https://dl.flathub.org/repo/flathub.flatpakrepo

RUN flatpak install --system --assumeyes flathub \
    com.mattjakeman.ExtensionManager \
    io.github.kolunmi.Bazaar \
    com.github.tchx84.Flatseal \
    io.github.flattool.Warehouse \
    io.github.swordpuffin.rewaita \
    org.qbittorrent.qBittorrent \
    it.mijorus.gearlever \
    org.libreoffice.LibreOffice \
    io.ente.auth \
    io.freetubeapp.FreeTube \
    org.videolan.VLC \
    com.github.neithern.g4music \
    org.signal.Signal \
    io.github.Foldex.AdwSteamGtk \
    org.localsend.localsend_app \
    io.github.peazip.PeaZip \
    com.github.vladimiry.ElectronMail \
    page.codeberg.libre_menu_editor.LibreMenuEditor

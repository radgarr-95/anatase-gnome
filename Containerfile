FROM i.anatase.org/base:stable

# ============================================================
# REPOSITORIES
# ============================================================

# Add Ghostty Copr repo manually
RUN printf '[copr-scottames-ghostty]\n\
name=Copr repo for ghostty\n\
baseurl=https://download.copr.fedorainfracloud.org/results/scottames/ghostty/fedora-45-$basearch/\n\
type=rpm-md\n\
skip_if_unavailable=1\n\
gpgcheck=1\n\
gpgkey=https://download.copr.fedorainfracloud.org/results/scottames/ghostty/pubkey.gpg\n\
repo_gpgcheck=0\n\
enabled=1\n' > /etc/yum.repos.d/scottames-ghostty.repo

# Add CoolerControl Copr repo manually
RUN printf '[copr-codifryed-coolercontrol]\n\
name=Copr repo for coolercontrol\n\
baseurl=https://download.copr.fedorainfracloud.org/results/codifryed/coolercontrol/fedora-45-$basearch/\n\
type=rpm-md\n\
skip_if_unavailable=1\n\
gpgcheck=1\n\
gpgkey=https://download.copr.fedorainfracloud.org/results/codifryed/coolercontrol/pubkey.gpg\n\
repo_gpgcheck=0\n\
enabled=1\n' > /etc/yum.repos.d/codifryed-coolercontrol.repo

# Add Zen Browser Copr repo manually
RUN printf '[copr-zen-browser]\n\
name=Copr repo for zen browser\n\
baseurl=https://download.copr.fedorainfracloud.org/results/rmnscnc/zen-browser/fedora-45-$basearch/\n\
type=rpm-md\n\
skip_if_unavailable=1\n\
gpgcheck=1\n\
gpgkey=https://download.copr.fedorainfracloud.org/results/rmnscnc/zen-browser/pubkey.gpg\n\
repo_gpgcheck=0\n\
enabled=1\n' > /etc/yum.repos.d/zen-browser.repo

# Add Terra repository for Mission Center
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
    neovim \
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
    # Additional applications
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
# NEOVIM & LAZYVIM SETUP
# ============================================================

# 1. Clone LazyVim starter template into the default root/user configuration path
RUN git clone https://github.com/LazyVim/starter /root/.config/nvim && \
    rm -rf /root/.config/nvim/.git

# 2. Create a desktop entry so Neovim shows up in your GNOME application launcher
RUN mkdir -p /usr/share/applications && \
    cat << 'EOF' > /usr/share/applications/nvim.desktop
[Desktop Entry]
Name=Neovim
GenericName=Text Editor
Comment=Edit text files using Neovim
Exec=ghostty -e nvim %F
Terminal=false
Type=Application
Categories=Utility;TextEditor;Development;
StartupNotify=true
MimeType=text/plain;inode/directory;
EOF


# ============================================================
# BOLD BREW (TUI PACKAGE MANAGER)
# ============================================================

# Install using a temporary non-root user (Homebrew requirement)
RUN useradd -m -s /bin/bash linuxbrew

USER linuxbrew

RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Valkyrie00/bold-brew/main/install.sh)"

USER root

# Expose Bold Brew and Homebrew globally in the system PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Create a desktop entry to launch Bold Brew inside Ghostty
RUN mkdir -p /usr/share/applications && \
    cat << 'EOF' > /usr/share/applications/bold-brew.desktop
[Desktop Entry]
Name=Bold Brew
GenericName=Package Manager TUI
Comment=Modern Terminal UI for managing Homebrew packages
Exec=ghostty -e bbrew
Terminal=false
Type=Application
Categories=System;Settings;PackageManager;
StartupNotify=true
EOF


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

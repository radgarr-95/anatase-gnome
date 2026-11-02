FROM i.anatase.org/base:stable

# ============================================================
# REPOSITORIES
# ============================================================

# Add Terra repository (provides Ghostty, CoolerControl, Zen Browser, Mission Center, etc.)
RUN curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
    -o /etc/yum.repos.d/terra.repo

# Enable RPM Fusion repositories for Steam/VLC
RUN dnf -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ============================================================
# SYSTEM PACKAGES (INCLUDING ALL AVAILABLE NATIVE APPS)
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
    # CLI Utilities
    neovim \
    oh-my-posh \
    eza \
    fzf \
    ripgrep \
    zoxide \
    uv \
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
    # System Applications (from Terra / base / RPM Fusion)
    coolercontrol \
    mission-center \
    zen-browser \
    heroic-games-launcher \
    qbittorrent \
    libreoffice \
    vlc \
    g4music \
    peazip \
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
# DESKTOP ENTRIES
# ============================================================

RUN mkdir -p /usr/share/applications && \
    printf '[Desktop Entry]\nName=Bold Brew\nGenericName=Package Manager TUI\nComment=Modern Terminal UI for managing Homebrew packages\nExec=ghostty -e bbrew\nTerminal=false\nType=Application\nCategories=System;Settings;PackageManager;\nStartupNotify=true\n' > /usr/share/applications/bold-brew.desktop


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
# FIRST-BOOT HOMEBREW & BOLD BREW INSTALLER SETUP (/bootstrap)
# ============================================================

RUN mkdir -p /bootstrap /etc/xdg/autostart

RUN cat << 'EOF' > /bootstrap/install-brew.sh
#!/bin/bash
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    exit 0
fi
useradd -m -s /bin/bash linuxbrew
mkdir -p /home/linuxbrew/bin
printf '#!/bin/bash\n"$@"\n' > /home/linuxbrew/bin/sudo
chmod +x /home/linuxbrew/bin/sudo
chown -R linuxbrew:linuxbrew /home/linuxbrew
su - linuxbrew -c '
export PATH="/home/linuxbrew/bin:$PATH"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &&
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Valkyrie00/bold-brew/main/install.sh)"
'
rm -f /etc/xdg/autostart/install-brew.desktop
EOF

RUN chmod +x /bootstrap/install-brew.sh

RUN cat << 'EOF' > /etc/xdg/autostart/install-brew.desktop
[Desktop Entry]
Type=Application
Name=Install Homebrew
Exec=/bootstrap/install-brew.sh
Terminal=false
NoDisplay=true
EOF


# ============================================================
# FIRST-BOOT FLATPAK INSTALLER SETUP (/bootstrap)
# ============================================================

RUN cat << 'EOF' > /bootstrap/install-flatpaks.sh
#!/bin/bash
flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system --assumeyes flathub \
    org.localsend.localsend_app \
    io.github.swordpuffin.rewaita \
    com.mattjakeman.ExtensionManager \
    io.github.flattool.Warehouse \
    io.ente.auth \
    com.github.vladimiry.ElectronMail \
    io.github.kolunmi.Bazaar \
    com.github.tchx84.Flatseal \
    it.mijorus.gearlever \
    io.freetubeapp.FreeTube \
    org.signal.Signal \
    io.github.Foldex.AdwSteamGtk \
    page.codeberg.libre_menu_editor.LibreMenuEditor \
    io.unom.punktfunk
rm -f /etc/xdg/autostart/install-flatpaks.desktop
EOF

RUN chmod +x /bootstrap/install-flatpaks.sh

RUN cat << 'EOF' > /etc/xdg/autostart/install-flatpaks.desktop
[Desktop Entry]
Type=Application
Name=Install Missing Flatpaks
Exec=/bootstrap/install-flatpaks.sh
Terminal=false
NoDisplay=true
EOF


# ============================================================
# DEFAULT SHELL & BOOT TARGET
# ============================================================

RUN chsh -s /usr/bin/fish

RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target


# ===========================================================
# CLEANUP (LEAVE THIS HERE)
# ============================================================

RUN rm -rf /var && \
    mkdir -p /var/tmp 


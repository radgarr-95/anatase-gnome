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
# GHOSTTY CONFIGURATION (DEFAULT TO NEOVIM)
# ============================================================

RUN mkdir -p /etc/skel/.config/ghostty && \
    printf 'command = nvim\n' > /etc/skel/.config/ghostty/config


# ============================================================
# DESKTOP ENTRIES (BOLD BREW & NEOVIM OVERRIDE)
# ============================================================

RUN mkdir -p /usr/share/applications && \
    printf '[Desktop Entry]\nName=Bold Brew\nGenericName=Package Manager TUI\nComment=Modern Terminal UI for managing Homebrew packages\nExec=ghostty -e bbrew\nTerminal=false\nType=Application\nCategories=System;Settings;PackageManager;\nStartupNotify=true\n' > /usr/share/applications/bold-brew.desktop

RUN printf '[Desktop Entry]\nName=Neovim\nGenericName=Text Editor\nComment=Edit text files in Ghostty\nExec=ghostty -e nvim\nTerminal=false\nType=Application\nCategories=Utility;TextEditor;\nStartupNotify=true\n' > /usr/share/applications/nvim.desktop


# ============================================================
# HANABI EXTENSION BUILD SCRIPT (EXECUTED DURING BUILD)
# ============================================================

RUN printf '#!/bin/bash\n' > /tmp/build-hanabi.sh && \
    printf 'set -euo pipefail\n' >> /tmp/build-hanabi.sh && \
    printf 'git clone --depth 1 https://github.com/jeffshee/gnome-ext-hanabi.git /tmp/hanabi\n' >> /tmp/build-hanabi.sh && \
    printf 'mkdir -p /tmp/hanabi-home /tmp/hanabi-npm-cache\n' >> /tmp/build-hanabi.sh && \
    printf 'HOME=/tmp/hanabi-home npm_config_cache=/tmp/hanabi-npm-cache make -C /tmp/hanabi install\n' >> /tmp/build-hanabi.sh && \
    printf 'install -d /usr/share/gnome-shell/extensions\n' >> /tmp/build-hanabi.sh && \
    printf 'cp -a /tmp/hanabi-home/.local/share/gnome-shell/extensions/hanabi-extension@jeffshee.github.io /usr/share/gnome-shell/extensions/\n' >> /tmp/build-hanabi.sh && \
    printf 'rm -rf /tmp/hanabi /tmp/hanabi-home /tmp/hanabi-npm-cache\n' >> /tmp/build-hanabi.sh

RUN chmod +x /tmp/build-hanabi.sh && /tmp/build-hanabi.sh && rm -f /tmp/build-hanabi.sh


# ============================================================
# FIRST-BOOT HOMEBREW & BOLD BREW INSTALLER SETUP (/bootstrap)
# ============================================================

RUN mkdir -p /bootstrap /etc/xdg/autostart

RUN printf '#!/bin/bash\n' > /bootstrap/install-brew.sh && \
    printf 'set -euo pipefail\n' >> /bootstrap/install-brew.sh && \
    printf 'exec > >(tee -a /tmp/install-brew.log) 2>&1\n' >> /bootstrap/install-brew.sh && \
    printf 'if [ -d "/home/linuxbrew/.linuxbrew" ]; then exit 0; fi\n' >> /bootstrap/install-brew.sh && \
    printf 'useradd -m -s /bin/bash linuxbrew\n' >> /bootstrap/install-brew.sh && \
    printf 'mkdir -p /home/linuxbrew/bin\n' >> /bootstrap/install-brew.sh && \
    printf 'printf "#!/bin/bash\\n\\"\\$@\\"\\n" > /home/linuxbrew/bin/sudo\n' >> /bootstrap/install-brew.sh && \
    printf 'chmod +x /home/linuxbrew/bin/sudo\n' >> /bootstrap/install-brew.sh && \
    printf 'chown -R linuxbrew:linuxbrew /home/linuxbrew\n' >> /bootstrap/install-brew.sh && \
    printf 'su - linuxbrew -c "export PATH=\\"/home/linuxbrew/bin:\\$PATH\\"; NONINTERACTIVE=1 /bin/bash -c \\"\\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\" && NONINTERACTIVE=1 /bin/bash -c \\"\\$(curl -fsSL https://raw.githubusercontent.com/Valkyrie00/bold-brew/main/install.sh)\\""\n' >> /bootstrap/install-brew.sh && \
    printf 'rm -f /etc/xdg/autostart/install-brew.desktop\n' >> /bootstrap/install-brew.sh

RUN chmod +x /bootstrap/install-brew.sh

RUN printf '[Desktop Entry]\nType=Application\nName=Install Homebrew\nExec=/bootstrap/install-brew.sh\nTerminal=false\nNoDisplay=true\n' > /etc/xdg/autostart/install-brew.desktop


# ============================================================
# FIRST-BOOT FLATPAK INSTALLER SETUP (/bootstrap)
# ============================================================

RUN printf '#!/bin/bash\n' > /bootstrap/install-flatpaks.sh && \
    printf 'set -euo pipefail\n' >> /bootstrap/install-flatpaks.sh && \
    printf 'exec > >(tee -a /tmp/install-flatpaks.log) 2>&1\n' >> /bootstrap/install-flatpaks.sh && \
    printf 'flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo\n' >> /bootstrap/install-flatpaks.sh && \
    printf 'flatpak install --system --assumeyes flathub \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    org.localsend.localsend_app \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.github.swordpuffin.rewaita \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    com.mattjakeman.ExtensionManager \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.github.flattool.Warehouse \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.ente.auth \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    com.github.vladimiry.ElectronMail \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.github.kolunmi.Bazaar \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    com.github.tchx84.Flatseal \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    it.mijorus.gearlever \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.freetubeapp.FreeTube \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    org.signal.Signal \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    io.github.Foldex.AdwSteamGtk \\\n' >> /bootstrap/install-flatpaks.sh && \
    printf '    page.codeberg.libre_menu_editor.LibreMenuEditor\n' >> /bootstrap/install-flatpaks.sh && \
    printf 'rm -f /etc/xdg/autostart/install-flatpaks.desktop\n' >> /bootstrap/install-flatpaks.sh

RUN chmod +x /bootstrap/install-flatpaks.sh

RUN printf '[Desktop Entry]\nType=Application\nName=Install Missing Flatpaks\nExec=/bootstrap/install-flatpaks.sh\nTerminal=false\nNoDisplay=true\n' > /etc/xdg/autostart/install-flatpaks.desktop


# ============================================================
# DEFAULT SHELL & BOOT TARGET
# ============================================================

RUN chsh -s /usr/bin/fish

RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target


# ============================================================
# CLEANUP (LEAVE THIS HERE)
# ============================================================

RUN rm -rf /var && \
    mkdir -p /var/tmp 


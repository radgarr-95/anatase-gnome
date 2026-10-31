FROM i.anatase.org/base:stable

# Enable necessary COPR repositories for Ghostty and CoolerControl
RUN dnf -y install dnf-plugins-core && \
    dnf -y copr enable scottames/ghostty && \
    dnf -y copr enable codifryed/CoolerControl

# Fedora 45 GNOME desktop packages with custom apps, hardware tools, fish shell, and full extension set
RUN dnf -y --setopt=install_weak_deps=False install \
    dconf \
    gdm \
    gnome-control-center \
    gnome-initial-setup \
    gnome-session-wayland-session \
    gnome-settings-daemon \
    gnome-shell \
    nautilus \
    ghostty \
    fish \
    procps-ng \
    curl \
    git \
    gcc \
    liquidctl \
    coolercontrol \
    fprintd-pam \
    gnome-bluetooth \
    oo7-daemon \
    oo7-portal \
    pam_oo7 \
    gnome-user-share \
    gvfs-afc \
    gvfs-fuse \
    gvfs-goa \
    gvfs-gphoto2 \
    gvfs-mtp \
    gvfs-smb \
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
    mission-center \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-burn-my-windows \
    gnome-shell-extension-o-tiling \
    gnome-shell-extension-user-theme \
    gnome-shell-extension-wallpaper-slideshow \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-gsconnect \
    gnome-shell-extension-logo-menu \
    gnome-shell-extension-add-to-steam \
    bazaar-companion \
    && dnf clean all

# Set Fish as the default shell globally for new users
RUN chsh -s /usr/bin/fish

# Provide a graphical login, enable the CoolerControl daemon, and set graphical target.
RUN systemctl enable gdm.service && \
    systemctl enable coolercontrold.service && \
    systemctl set-default graphical.target

# Cleanup (leave this here).
RUN rm -rf /var && \
    mkdir -p /var/tmp

FROM i.anatase.org/base:stable

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
RUN printf '[copr-codifryed-CoolerControl]\n\
name=Copr repo for CoolerControl\n\
baseurl=https://download.copr.fedorainfracloud.org/results/codifryed/CoolerControl/fedora-45-$basearch/\n\
type=rpm-md\n\
skip_if_unavailable=1\n\
gpgcheck=1\n\
gpgkey=https://download.copr.fedorainfracloud.org/results/codifryed/CoolerControl/pubkey.gpg\n\
repo_gpgcheck=0\n\
enabled=1\n' > /etc/yum.repos.d/codifryed-CoolerControl.repo

# Fedora 45 GNOME desktop packages with validated available packages
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
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-user-theme \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-gsconnect \
    gnome-shell-extension-logo-menu \
    && dnf clean all

# Set Fish as the default shell globally for new users
RUN chsh -s /usr/bin/fish

# Provide a graphical login, enable the CoolerControl daemon, and set graphical target.
RUN systemctl enable gdm.service && \
    systemctl enable coolercontrol.service && \
    systemctl set-default graphical.target

# Cleanup (leave this here).
RUN rm -rf /var && \
    mkdir -p /var/tmp

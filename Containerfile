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
RUN curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo -o /etc/yum.repos.d/terra.repo

# Fedora 45 GNOME desktop packages, apps, and Homebrew prerequisites (gcc, make, file, etc.)
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
    make \
    file \
    bzip2 \
    unzip \
    liquidctl \
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
    adw-gtk3-theme \
    coolercontrol \
    mission-center \
    zen-browser \
    heroic-games-launcher \
    && dnf clean all

# Install Homebrew using a temporary non-root user (required by Homebrew)
RUN useradd -m -s /bin/bash linuxbrew
USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
USER root

# Expose Homebrew globally in the system PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Set Fish as the default shell globally for new users
RUN chsh -s /usr/bin/fish

# Provide a graphical login and set graphical target.
RUN systemctl enable gdm.service && \
    systemctl set-default graphical.target

# Cleanup (leave this here).
RUN rm -rf /var && \
    mkdir -p /var/tmp

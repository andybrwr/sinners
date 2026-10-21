FROM quay.io/fedora-ostree-desktops/kinoite:44

RUN dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-release-extras terra-release-mesa

RUN     dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

RUN dnf -y install --allowerasing fuse fuse-libs steam tailscale \
				   neovim obs-studio steam-devices \
				   wl-clipboard ffmpeg gstreamer1 \
				   gstreamer1-vaapi intel-media-driver

COPY etc/ /etc/
COPY usr/ /usr/

RUN systemctl enable bootc-fetch-apply-updates.timer

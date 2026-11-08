FROM quay.io/fedora-ostree-desktops/kinoite:44 AS sinners

RUN dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

RUN dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release terra-release-extras terra-release-mesa

RUN dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

RUN dnf -y install --allowerasing fuse fuse-libs steam tailscale \
				   neovim obs-studio steam-devices \
				   wl-clipboard ffmpeg gstreamer1 \
				   intel-media-driver fastfetch ladspa-caps-plugins \
                   ladspa-swh-plugins lsp-plugins-ladspa neovim \
                   qv4l2 intel-compute-runtime ocl-icd \
				   apr apr-util zlib-ng zlib-ng-compat

COPY etc/ /etc/
COPY usr/ /usr/

RUN systemctl enable bootc-fetch-apply-updates.timer

RUN dnf clean all && rm -rf /var/cache/libdnf5 /var/log/dnf5.log* && bootc container lint

FROM quay.io/fedora/fedora:44 AS xrizer
ARG XRIZER_VERSION=v0.6
ADD --checksum=sha256:9b2105433e48a20f789e20a14113dbd98650afd116bd232419725a4438dd2149 \
    https://github.com/Supreeeme/xrizer/releases/download/${XRIZER_VERSION}/xrizer-${XRIZER_VERSION}.zip /tmp/xrizer.zip
RUN dnf -y install unzip && unzip -q /tmp/xrizer.zip -d /tmp/out && mv /tmp/out/xrizer-${XRIZER_VERSION} /xrizer

# Gaming variant: everything above plus extras.
# Build with --target sinners-gaming (CI publishes it as sinners-gaming-bootc).
FROM sinners AS sinners-gaming

RUN dnf -y install gamescope mangohud gamemode wivrn

# xrizer (OpenVR -> OpenXR) isn't packaged for Fedora; use the pinned upstream build.
COPY --from=xrizer /xrizer /usr/lib/xrizer

RUN dnf clean all && rm -rf /var/cache/libdnf5 /var/log/dnf5.log* && bootc container lint

# Keep the base image as the default when no --target is given.
FROM sinners

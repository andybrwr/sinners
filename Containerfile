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

# Custom image name for fetch tools. Only touch display fields; ID/VERSION_ID/etc. must stay Fedora's.
RUN sed -i \
      -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Sinners $(rpm -E %fedora))\"/" \
      -e 's/^VARIANT=.*/VARIANT="Sinners"/' \
      /usr/lib/os-release && \
    echo 'IMAGE_ID="sinners"' >> /usr/lib/os-release

RUN systemctl enable bootc-fetch-apply-updates.timer

RUN dnf clean all && rm -rf /var/cache/libdnf5 /var/log/dnf5.log* && bootc container lint

FROM quay.io/fedora/fedora:44 AS xrizer
# Nightly: artifact from the latest successful CI run on xrizer's main branch.
# The GitHub API gives the run and the artifact's sha256; nightly.link serves the
# artifact without auth, and the download is checked against GitHub's digest.
RUN dnf -y install jq unzip && \
    api=https://api.github.com/repos/Supreeeme/xrizer/actions && \
    run=$(curl -fsSL "$api/workflows/ci.yml/runs?branch=main&event=push&status=success&per_page=1" | jq -er '.workflow_runs[0].id') && \
    artifact=$(curl -fsSL "$api/runs/$run/artifacts?name=xrizer-nightly-release" | jq -ec '.artifacts[0]') && \
    sha=$(jq -er '.workflow_run.head_sha' <<<"$artifact") && \
    digest=$(jq -er '.digest | sub("^sha256:"; "")' <<<"$artifact") && \
    echo "xrizer nightly: run $run, commit $sha" && \
    curl -fsSL -o /tmp/xrizer.zip "https://nightly.link/Supreeeme/xrizer/actions/runs/$run/xrizer-nightly-release.zip" && \
    echo "$digest  /tmp/xrizer.zip" | sha256sum -c - && \
    unzip -q /tmp/xrizer.zip -d /tmp/out && mv /tmp/out/xrizer /xrizer && \
    echo "nightly-$sha" > /xrizer/bin/version.txt

# Gaming variant: everything above plus extras.
# Build with --target sinners-gaming (CI publishes it as sinners-gaming-bootc).
FROM sinners AS sinners-gaming

RUN dnf -y install gamescope mangohud gamemode wivrn

RUN sed -i \
      -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Sinners $(rpm -E %fedora) (Gaming Build)\"/" \
      -e 's/^VARIANT=.*/VARIANT="Sinners Gaming"/' \
      -e 's/^IMAGE_ID=.*/IMAGE_ID="sinners-gaming"/' \
      /usr/lib/os-release

# xrizer (OpenVR -> OpenXR) isn't packaged for Fedora; use the upstream nightly build.
COPY --from=xrizer /xrizer /usr/lib/xrizer

RUN dnf clean all && rm -rf /var/cache/libdnf5 /var/log/dnf5.log* && bootc container lint

# Keep the base image as the default when no --target is given.
FROM sinners

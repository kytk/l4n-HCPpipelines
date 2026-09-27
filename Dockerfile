# syntax=docker/dockerfile:1

# Dockerfile for kytk/l4n-HCPpipeline with Multi-Stage Build
# Author: K. Nemoto
# Date: 27 Sep 2026
# Description: This Dockerfile uses a multi-stage build to create a smaller,
#              optimized container image for HCP Pipelines 6.x.

# Ver.260927
#   - HCPpipelines: pinned to v6.0.0 (FreeSurfer stays at 6.0.1, which
#     HCP Pipelines requires; 7.x is not supported)
#     and cloned only once, shallow, into ~/projects (the extra copy in ~/git
#     is gone)
#   - Image size: all pruning now happens in the builder stages BEFORE the
#     COPY --from steps. Deleting files in a later layer never shrinks a
#     Docker image, so the old Part 4/5 cleanup had no effect. Pruned:
#     FSL conda package cache (pkgs/), FSL headers and compiler
#     sysroot, NVIDIA/CUDA libraries of the MATLAB runtime (2.7 GB, no GPU)
#   - Ownership: brain is created first and files that must belong to it are
#     copied with --chown. The old recursive chown over /home/brain made
#     overlayfs copy HCPpipelines into a new 2.76 GB layer
#   - libpng12: installed in the final stage (it was only in the builder, so
#     FreeSurfer's Qt GUI libraries could not load it)
#   - MSM and libpng12 are taken from build/packages instead of the network
#   - AlizaMS removed
#   - Shared folder: always /home/brain/share (Windows needs an NTFS drive;
#     --privileged and the /root/share bind-mount workaround are gone), and
#     /etc/gitconfig sets safe.directory='*' and core.fileMode=false
#   - FSL: 6.0.7.18 -> 6.0.7.23 (eddy, fugue, melodic, pyfix 0.10.0, ...)
#   - Python: one venv at /opt/venv on Python 3.12 (deadsnakes) holds every
#     pip package, for HCP Pipelines and for the user alike. jammy's own
#     Python 3.10 is left to apt; pcntoolkit 1.x does not run on 3.10
#   - Build cache: every RUN bind-mounts only the files it needs, and the
#     builder is split into independent stages per tool, so that replacing one
#     archive rebuilds one stage. BuildKit also builds them in parallel.

#------------------------------------------------------------------------------
# Stage 1: The "Builder" Stages
# - base-builder installs the build-time tools shared by all builders.
# - tools-builder / fs-builder / mcr-builder / fsl-builder / hcp-builder each
#   install one group of software, independently of the others.
# - Each stage prunes everything that is not needed at runtime (this MUST
#   happen here: files deleted in the final stage still occupy space in
#   earlier layers).
# - These stages are large, but they are discarded after the build.
#------------------------------------------------------------------------------
FROM ubuntu:22.04 AS base-builder

# Set non-interactive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo

# Install build-time dependencies and essential tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential ca-certificates dkms \
      curl wget git gnupg \
      unzip zip p7zip-full pigz file

#------------------------------------------------------------------------------
# tools-builder: MRIcroGL, dcm2niix
#------------------------------------------------------------------------------
FROM base-builder AS tools-builder

RUN --mount=type=bind,source=build/packages/MRIcroGL_linux.zip,target=/tmp/packages/MRIcroGL_linux.zip \
    --mount=type=bind,source=build/packages/dcm2niix_lnx.zip,target=/tmp/packages/dcm2niix_lnx.zip \
    set -ex && \
    # MRIcroGL
    unzip /tmp/packages/MRIcroGL_linux.zip -d /usr/local/ && \
    # dcm2niix
    mkdir -p /usr/local/dcm2niix && \
    unzip /tmp/packages/dcm2niix_lnx.zip -d /usr/local/dcm2niix

#------------------------------------------------------------------------------
# fs-builder: FreeSurfer 6.0.1
#------------------------------------------------------------------------------
FROM base-builder AS fs-builder

RUN --mount=type=bind,source=build/packages/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz,target=/tmp/packages/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz \
    set -ex && \
    # FreeSurfer 6.0.1 under /usr/local/freesurfer/6.0.1
    mkdir -p /usr/local/freesurfer/ && \
    tar -xf /tmp/packages/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.1.tar.gz -C /usr/local/freesurfer && \
    mv /usr/local/freesurfer/freesurfer /usr/local/freesurfer/6.0.1 && \
    # Prepare FreeSurfer subjects directory for the user
    mkdir -p /home/brain/freesurfer/6.0.1 && \
    ln -s /usr/local/freesurfer/6.0.1/subjects /home/brain/freesurfer/6.0.1/

#------------------------------------------------------------------------------
# mcr-builder: MATLAB Runtime R2022b
# HCP Pipelines' compiled MATLAB binaries are built with R2022b; a newer
# runtime cannot run them.
#------------------------------------------------------------------------------
FROM base-builder AS mcr-builder

RUN --mount=type=bind,source=build/packages/MATLAB_Runtime_R2022b_Update_7_glnxa64.zip,target=/tmp/packages/MATLAB_Runtime_R2022b_Update_7_glnxa64.zip \
    set -ex && \
    mkdir -p /tmp/mcr_r2022b && \
    cd /tmp/mcr_r2022b && \
    unzip -q /tmp/packages/MATLAB_Runtime_R2022b_Update_7_glnxa64.zip && \
    ./install -mode silent -agreeToLicense yes -destinationFolder /usr/local/MATLAB/MCR/ && \
    cd / && rm -rf /tmp/mcr_r2022b && \
    # MATLAB MCR cleanup (moved here from the final stage so that it actually
    # reduces the image). Removes the licence/patent text, documentation,
    # examples, demos and tutorials. The old chain also deleted *win32*, *.h,
    # unused toolboxes etc. behind a trailing "|| true", which hid any failure
    # and skipped the rest of the chain; nothing here may end in "|| true".
    cd /usr/local/MATLAB/MCR/R2022b && \
    rm -rf help/ patents.txt trademarks.txt matlabruntime_license_agreement.pdf && \
    find . -type d -name "*doc*" -exec rm -rf {} + && \
    find . -type d -name "*example*" -exec rm -rf {} + && \
    find . -type d -name "*demo*" -exec rm -rf {} + && \
    find . -type d -name "*tutorial*" -exec rm -rf {} + && \
    find . -type f \( -name "*.pdf" -o -name "*.html" -o -name "*.htm" \) -delete && \
    # NVIDIA/CUDA libraries (cuBLAS, cuDNN, cuFFT, cuSPARSE, cuSOLVER, NCCL,
    # NVRTC, NPP, ...) are only used by GPU functions; the container has no
    # GPU. ~2.7 GB. libcurl* matches "libcu*" and must stay.
    find bin/glnxa64 -maxdepth 1 ! -type d \( -name 'libcu*' -o -name 'libnv*' -o -name 'libnccl*' -o -name 'libnpp*' \) \
      ! -name 'libcurl*' -delete && \
    rm -rf sys/cuda && \
    echo "MATLAB Runtime after cleanup: $(du -sh /usr/local/MATLAB/MCR/R2022b | cut -f1)"

#------------------------------------------------------------------------------
# fsl-builder: FSL 6.0.7.23 + MSM
# The tarball is made on jammy from a fresh fslinstaller install with
# lin4neuro-jammy/build-scripts/make-fsl-tarball.sh, which leaves out the
# conda package cache (pkgs/).
#------------------------------------------------------------------------------
FROM base-builder AS fsl-builder

RUN --mount=type=bind,source=build/packages/fsl-6.0.7.23-jammy.tar.gz,target=/tmp/packages/fsl-6.0.7.23-jammy.tar.gz \
    --mount=type=bind,source=build/packages/msm_ubuntu_v3,target=/tmp/packages/msm_ubuntu_v3 \
    set -ex && \
    # FSL
    tar -xf /tmp/packages/fsl-6.0.7.23-jammy.tar.gz -C /usr/local/ && \
    # Headers and the compiler sysroot are only needed for building packages.
    # pkgs/ (the conda package cache) is normally not in the tarball; it is
    # removed here as well in case a tarball made another way carries it.
    rm -rf /usr/local/fsl/pkgs /usr/local/fsl/include /usr/local/fsl/src \
           /usr/local/fsl/x86_64-conda-linux-gnu && \
    # The wrappers under share/fsl/bin call their Python interpreter by
    # absolute path; make sure it exists instead of failing only at run time.
    fsl_python="$(sed -n 2p /usr/local/fsl/share/fsl/bin/fsleyes | awk '{print $1}')" && \
    echo "FSL wrappers use interpreter: ${fsl_python}" && \
    test -x "${fsl_python}" && \
    # Drop dangling symlinks and list them in the build log
    find /usr/local/fsl -xtype l -print -delete && \
    # MSM (HOCR v3) replaces the msm shipped with FSL
    mv /usr/local/fsl/bin/msm /usr/local/fsl/bin/msm.orig && \
    install -m 755 /tmp/packages/msm_ubuntu_v3 /usr/local/fsl/bin/msm

#------------------------------------------------------------------------------
# hcp-builder: HCP Pipelines v6.0.0 + modified example scripts
# The tag is required: an untagged clone gets master, which moves on.
# build/hcp/modified-scripts is based on this version (upstream
# Examples/Scripts with this container's paths and settings).
#------------------------------------------------------------------------------
FROM base-builder AS hcp-builder

ARG HCP_PIPELINES_VERSION=v6.0.0

RUN --mount=type=bind,source=build/hcp/modified-scripts,target=/tmp/modified-scripts \
    set -ex && \
    mkdir -p /home/brain/projects && \
    git clone --depth 1 --branch ${HCP_PIPELINES_VERSION} \
      https://github.com/Washington-University/HCPpipelines.git \
      /home/brain/projects/HCPpipelines && \
    # Copy modified scripts to override default ones
    cp /tmp/modified-scripts/* /home/brain/projects/HCPpipelines/Examples/Scripts/

#------------------------------------------------------------------------------
# Stage 2: The "Final" Stage
# - Starts from a clean Ubuntu base image.
# - Installs only runtime dependencies.
# - Copies the pre-built software from the builder stages.
# - Configures the user and environment.
#------------------------------------------------------------------------------
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Tokyo \
    DISPLAY=:1 \
    RESOLUTION=1920x1080x24

# Part 0: Create the "brain" user first (uid/gid 1000), so that the later
# COPY --chown steps can refer to it and no recursive chown is needed.
RUN set -ex && \
    useradd -u 1000 -m -s /bin/bash brain && \
    echo "brain:lin4neuro" | chpasswd && \
    usermod -aG sudo brain

# Part 1: Install runtime dependencies (one RUN, so that the apt lists removed
# at the end never land in a layer)
RUN --mount=type=bind,source=build/packages/libpng12-0_1.2.54-1ubuntu1.1+1~ppa0~eoan_amd64.deb,target=/tmp/packages/libpng12-0_1.2.54-1ubuntu1.1+1~ppa0~eoan_amd64.deb \
    set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      # XFCE Desktop & VNC
      xfce4-session xfce4-panel xfwm4 xfce4-terminal xfce4-settings \
      xfdesktop4 xfce4-screenshooter xfce4-appfinder \
      shimmer-themes \
      thunar thunar-archive-plugin file-roller xdg-utils \
      gnome-icon-theme tango-icon-theme elementary-xfce-icon-theme \
      libgtk2.0-0 xinit \
      tightvncserver novnc websockify net-tools supervisor \
      x11vnc xvfb dbus-x11 sudo \
      dbus \
      # Python (system 3.10, used by apt tools only; see Part 1b)
      python3-gpg \
      # Core Utilities
      wget tzdata iputils-ping less nano rsync locate git apt-utils apt-file \
      apturl at-spi2-core bc dc ca-certificates default-jre evince gedit \
      gnome-system-monitor gnome-system-tools baobab imagemagick \
      vim rename ntp tree unzip zip p7zip-full pigz csh tcsh gnupg meld \
      # Fonts & Themes
      software-properties-common fonts-noto fonts-noto-cjk \
      appmenu-gtk-module-common appmenu-gtk2-module libappmenu-gtk2-parser0 \
      # Apps & Libs
      gawk sed libopenblas-base \
      libjpeg62 language-pack-en gettext \
      libncurses5 && \
    apt-get install -y octave gnumeric && \
    # libpng12 for FreeSurfer 6.0.1 (lib/qt/lib/libQtGui.so.4 and the kvl*
    # GUI binaries link against it; jammy no longer ships it)
    apt-get install -y /tmp/packages/libpng12-0_1.2.54-1ubuntu1.1+1~ppa0~eoan_amd64.deb && \
    # Timezone setup
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    # deadsnakes PPA (Python 3.12 for the venv in Part 1b)
    add-apt-repository -y --no-update ppa:deadsnakes/ppa && \
    # Firefox repository
    install -d -m 0755 /etc/apt/keyrings && \
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | \
      gpg --dearmor -o /etc/apt/keyrings/packages.mozilla.org.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.gpg] https://packages.mozilla.org/apt mozilla main" | \
      tee /etc/apt/sources.list.d/mozilla.list > /dev/null && \
    echo 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000' | \
      tee /etc/apt/preferences.d/mozilla && \
    # NeuroDebian repository (Connectome Workbench)
    . /etc/os-release && \
    printf '%s\n%s\n' \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/neurodebian.gpg] http://neuroimaging.sakura.ne.jp/neurodebian data main contrib non-free" \
      "deb [arch=amd64 signed-by=/usr/share/keyrings/neurodebian.gpg] http://neuroimaging.sakura.ne.jp/neurodebian ${VERSION_CODENAME} main contrib non-free" \
      > /etc/apt/sources.list.d/neurodebian.sources.list && \
    wget -qO- http://neuro.debian.net/_static/neuro.debian.net.asc | \
      gpg --dearmor --yes --output /usr/share/keyrings/neurodebian.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends firefox && \
    apt-get install -y --no-install-recommends python3.12 python3.12-venv python3.12-tk && \
    apt-get install -y connectome-workbench && \
    xdg-mime default firefox.desktop text/html && \
    # Final apt cleanup for this layer (must stay in this RUN to be effective)
    apt-get clean && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/* && \
    # Remove locales other than English and empty the logs
    find /usr/share/locale -maxdepth 1 -mindepth 1 ! -name 'en*' -exec rm -r {} \; && \
    find /var/log/ -type f -exec truncate -s 0 {} \;

# Part 1b: Python venv (/opt/venv, Python 3.12)
# The single Python environment of this image: HCP Pipelines (CorrThick,
# ICAFIX AutoReclean via onnxruntime) and the analysis packages all live here.
# bash_aliases puts /opt/venv/bin first in PATH. A separate RUN so that a
# change to the package list does not re-run the apt layer above; owned by
# brain so that the user can pip install without sudo (the chown stays in
# this RUN, so no layer is duplicated).
# - pcntoolkit 1.x needs Python >= 3.11 (1.0-1.1 declare 3.10 but import
#   typing.LiteralString); pinned so that the build does not silently change
# - "gdcm" on PyPI is an abandoned package without wheels for 3.12;
#   "python-gdcm" is the official GDCM wheel (provides "import gdcm")
RUN set -ex && \
    python3.12 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir \
       numpy scipy pandas matplotlib seaborn jupyter notebook \
       nibabel nipype pydicom python-gdcm heudiconv \
       psutil threadpoolctl joblib scikit-learn xgboost onnxruntime \
       pcntoolkit==1.3.0 && \
    chown -R brain:brain /opt/venv

# Part 2: Copy pre-built applications from the builder stages
# Part 2a: Copy small neuroimaging tools
COPY --from=tools-builder /usr/local/MRIcroGL/ /usr/local/MRIcroGL/
COPY --from=tools-builder /usr/local/dcm2niix/ /usr/local/dcm2niix/

# Part 2b: Copy FreeSurfer
COPY --from=fs-builder /usr/local/freesurfer/ /usr/local/freesurfer/
COPY --from=fs-builder --chown=brain:brain /home/brain/freesurfer/ /home/brain/freesurfer/

# Part 2c: Copy MATLAB MCR R2022b
COPY --from=mcr-builder /usr/local/MATLAB/ /usr/local/MATLAB/

# Part 2d: Copy FSL + MSM
COPY --from=fsl-builder /usr/local/fsl/ /usr/local/fsl/

# Part 2e: Copy HCP Pipelines (with the modified example scripts)
COPY --from=hcp-builder --chown=brain:brain /home/brain/projects/ /home/brain/projects/

# Part 3: User setup and configuration
COPY build/desktop/deep_ocean.png /usr/share/backgrounds/
COPY build/home/bash_aliases /etc/skel/.bash_aliases
COPY build/home/bash_aliases /root/.bash_aliases
COPY --chown=brain:brain build/home/bash_aliases /home/brain/.bash_aliases
COPY --chown=brain:brain build/home/startup.m /home/brain/matlab/
COPY --chown=brain:brain build/desktop/xfce4-desktop.xml /home/brain/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
COPY --chown=brain:brain build/desktop/xfce4-panel.xml /home/brain/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
COPY --chown=brain:brain build/desktop/terminalrc /home/brain/.config/xfce4/terminal/terminalrc
COPY build/init/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chmod=755 build/init/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=755 build/init/startup.sh /usr/local/bin/startup.sh

# The user itself was created in Part 0; only its shell files, the VNC
# password and a few empty directories remain. No recursive chown over
# /home/brain: everything copied in above is already owned by brain.
RUN set -ex && \
    rm -f /usr/share/backgrounds/xfce/xfce*.*p*g && \
    chmod 644 /root/.bash_aliases /etc/skel/.bash_aliases && \
    sed -i "s/UI.initSetting('resize', 'off');/UI.initSetting('resize', 'local');/g" /usr/share/novnc/app/ui.js && \
    echo '# Load .bashrc for bash login shells' > /home/brain/.profile && \
    echo 'if [ -n "$BASH_VERSION" ]; then' >> /home/brain/.profile && \
    echo '  . ~/.bashrc' >> /home/brain/.profile && \
    echo 'fi' >> /home/brain/.profile && \
    chmod 644 /home/brain/.bash_aliases /home/brain/.profile && \
    mkdir -p /home/brain/.vnc /home/brain/logs /home/brain/.dbus && \
    echo "lin4neuro" | vncpasswd -f > /home/brain/.vnc/passwd && \
    chmod 600 /home/brain/.vnc/passwd && \
    chown brain:brain /home/brain/.profile && \
    chown -R brain:brain /home/brain/.vnc /home/brain/logs /home/brain/.dbus && \
    chmod 1777 /tmp && \
    # Git settings for repositories on the bind-mounted share folder (same as
    # docker-abis-2027). Docker Desktop can present a Windows/macOS folder as
    # root-owned with synthetic 0777 modes; git then stops with "detected
    # dubious ownership" and reports every file as mode-changed. /etc/gitconfig
    # applies to brain and root alike.
    git config --system --add safe.directory '*' && \
    git config --system core.fileMode false

# Expose port for noVNC
EXPOSE 6080

# startup.sh runs as ROOT first, then switches to brain user
ENV USER=brain

# Set the default command to run on container start
CMD ["/usr/local/bin/startup.sh"]

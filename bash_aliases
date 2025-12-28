# alias for xdg-open
alias open='xdg-open &> /dev/null'

# shopt
shopt -s direxpand
shopt -s autocd

# Disable screensaver
xset s off

# XDG Runtime Directory
export XDG_RUNTIME_DIR="/tmp/runtime-brain"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# Qt Session Management - Disable to avoid VNC authentication errors
unset SESSION_MANAGER
export QT_X11_NO_MITSHM=1
export QT_GRAPHICSSYSTEM=native
export QT_X11_NO_XIM=1

# MRIcroGL
export PATH=/usr/local/MRIcroGL:$PATH
export PATH=/usr/local/MRIcroGL/Resources:$PATH

# dcm2niix
export PATH=/usr/local/dcm2niix:$PATH

#FreeSurfer 6.0.1
export SUBJECTS_DIR=~/freesurfer/6.0.1/subjects
export FREESURFER_HOME=/usr/local/freesurfer/6.0.1
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# FSL Setup
FSLDIR=/usr/local/fsl
PATH=${FSLDIR}/share/fsl/bin:${PATH}
export FSLDIR PATH
. ${FSLDIR}/etc/fslconf/fsl.sh


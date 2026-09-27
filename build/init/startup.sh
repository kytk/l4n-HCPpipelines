#!/bin/bash
# Shared Folder Setup - Cross-platform (Windows/macOS/Linux)
# Author: K. Nemoto
# Version: 1.0.19
#
# The shared folder is always mounted at /home/brain/share on every OS.
# On Windows the external drive must be NTFS: exFAT cannot store POSIX
# ownership, which is what the old /root/share + "mount --bind" workaround
# (and the --privileged flag it needed) was for. macOS works with exFAT too.

echo "=== Setting up shared folder ==="

if [[ -d /home/brain/share ]]; then
    chown -R brain:brain /home/brain/share 2>/dev/null || true
    echo "Shared folder is ready: /home/brain/share"
else
    echo "INFO: No shared folder configured"
fi

# Screen resolution of the virtual display (docker run -e RESOLUTION=WxHxD).
# "su -" resets the environment, so the value is checked here and passed on
# explicitly; supervisord.conf uses it for Xvfb.
default_resolution=1920x1080x24
if [[ -z "${RESOLUTION:-}" ]]; then
    RESOLUTION=$default_resolution
elif [[ ! "$RESOLUTION" =~ ^[0-9]+x[0-9]+x(8|16|24|32)$ ]]; then
    echo "WARNING: RESOLUTION='$RESOLUTION' is not WIDTHxHEIGHTxDEPTH (e.g. 1600x900x24); using $default_resolution"
    RESOLUTION=$default_resolution
fi
echo "Screen resolution: $RESOLUTION"

echo "=== Starting container ==="
exec su - brain -c "RESOLUTION=$RESOLUTION /usr/local/bin/entrypoint.sh"

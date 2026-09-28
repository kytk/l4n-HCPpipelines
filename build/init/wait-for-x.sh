#!/bin/bash
# Block until the X server on $1 accepts connections, then exec the rest of
# the arguments.
# Version: 1.0.0
#
# supervisord's "priority" only decides the order of the spawns; it does not
# wait for a program to become usable. x11vnc and xfce4-session were therefore
# started while Xvfb was still coming up, which is what put
#
#     xrdb: Connection refused
#     xrdb: Can't open display ':1'
#
# in the startup log: startxfce4 got that far before the server was listening,
# so the Xresources were never merged. The desktop recovered here because the
# rest of the session starts a moment later, but a loaded host can lose the
# race outright.
#
#     command=/usr/local/bin/wait-for-x.sh :1 /usr/bin/startxfce4

set -u

display=$1
shift

deadline=$((SECONDS + 30))
while [ $SECONDS -lt $deadline ]; do
    if xdpyinfo -display "$display" >/dev/null 2>&1; then
        exec "$@"
    fi
    sleep 0.1
done

echo "wait-for-x: $display did not accept connections within 30s" >&2
exit 1

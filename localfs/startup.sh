#!/bin/bash

export LAUNCH=${@:-null}
[[ $LAUNCH == "null" ]] && export AUTOSTART=false || export AUTOSTART=true

echo "Starting with UID : $USER_ID"
echo "Launching : $LAUNCH"
echo "Umask: $UMASK"

# Userhandling
groupadd --gid ${GROUP_ID} app
useradd --home-dir /app --shell /bin/bash --uid ${USER_ID} --gid ${GROUP_ID} app
usermod -a -G tty app

# VNC password
if [[ -z "${PASSWORD}" ]]; then
    echo "No password set"
    args+=("-SecurityTypes None")
else
    mkdir /app/.vnc
    echo ${PASSWORD} | tigervncpasswd -f > /app/.vnc/passwd
    args+=("-PasswordFile /app/.vnc/passwd")
    args+=("-SecurityTypes VncAuth,TLSVnc")
    echo "Password set"
fi

# Local connection only
if [ "$ALLOW_DIRECT_VNC" = false ] ; then
    args+=("-localhost")
else
    echo "Attention! VNC Port 5900 is bound to all interfaces, no limit!"
fi

# Geometry
if [[ -z "${GEOMETRY}" ]]; then
    echo "No geometry given"
    args+=("-geometry 1024x768")
else
    echo "Custom geometry specified: ${GEOMETRY}"
    args+=("-geometry ${GEOMETRY}")
fi

# VNC arguments
args+=("-rfbport 5900")
args+=("-AlwaysShared")
args+=("-AcceptKeyEvents")
args+=("-AcceptPointerEvents")
args+=("-AcceptSetDesktopSize")
args+=("-SendCutText")
args+=("-AcceptCutText")
export VNC_ARGS="${args[*]}"

# Permissions
chown -R ${USER_ID}:${GROUP_ID} /app /data /dev/stdout
chmod o+w /dev/stdout
# Workaround for vscode devcontainers
if [ -d "/tmp/.X11-unix" ]; then
    rm -rf /tmp/.X11-unix
fi

# Setting umask
umask ${UMASK}

# Workaround for vscode devcontainers
if [ -d "/tmp/.X11-unix" ]; then
    rm -rf /tmp/.X11-unix
fi

# check if nginx is already running
if [ -f /var/run/nginx.pid ]; then
    nginx -s reload
else
    nginx
fi


exec /usr/sbin/gosu ${USER_ID}:${GROUP_ID} supervisord

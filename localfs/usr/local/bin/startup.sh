#!/bin/bash

set -x

if [ $# -eq 0 ]; then
    echo "No arguments supplied, will start an empty desktop."
    AUTOSTART=false
    LAUNCH=""
else
    LAUNCH=$*
    AUTOSTART=true
fi

export AUTOSTART LAUNCH

echo "Starting with UID : $USER_ID"
echo "Launching : ${LAUNCH[0]}"
echo "Umask: $UMASK"

# Userhandling
if ! group=$(getent group "${GROUP_ID}"); then
    echo "Creating group app with gid ${GROUP_ID}"
    groupadd --gid "${GROUP_ID}" app
else
    echo "Group with gid ${GROUP_ID} ($(echo $group | cut -d ":" -f 1)) already exists"
fi

if ! user=$(getent passwd "${USER_ID}"); then
    echo "Creating user app with uid ${USER_ID}"
    useradd --home-dir /app --shell /bin/bash --uid "${USER_ID}" --gid "${GROUP_ID}" app
else
    echo "User with uid ${USER_ID} ($(echo $user | cut -d ":" -f 1)) already exists"
fi

usermod -a -G tty "$(getent passwd "${USER_ID}" | cut -d ":" -f 1)"

# VNC password
if [[ -z "${PASSWORD}" ]]; then
    echo "No password set"
    args+=("-SecurityTypes None")
else
    mkdir /app/.vnc
    echo "${PASSWORD}" | tigervncpasswd -f > /app/.vnc/passwd
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
chown -R "${USER_ID}":"${GROUP_ID}" /app /data /dev/stdout
chmod o+w /dev/stdout
# Workaround for vscode devcontainers
if [ -d "/tmp/.X11-unix" ]; then
    rm -rf /tmp/.X11-unix
fi

# Setting umask
umask "${UMASK}"

# Workaround for vscode devcontainers
if [ -d "/tmp/.X11-unix" ]; then
    rm -rf /tmp/.X11-unix
fi

# Read pid from file and check if process is running
if [ -f /var/run/nginx.pid ]; then
    pid=$(cat /var/run/nginx.pid)
    if ! ps -p "${pid}" > /dev/null; then
        echo "nginx is not running, starting it now"
        rm /var/run/nginx.pid
        nginx
    else
        echo "nginx is running, sending reload signal"
        nginx -s reload
    fi
else
    echo "nginx is not running, starting it now"
    nginx
fi

exec /usr/sbin/gosu "${USER_ID}":"${GROUP_ID}" supervisord

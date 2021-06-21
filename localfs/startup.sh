#!/bin/bash

export LAUNCH=${@:-null}
[[ $LAUNCH == "null" ]] && export AUTOSTART=false || export AUTOSTART=true

echo "Starting with UID : $USER_ID"
echo "Launching : $LAUNCH"

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

# VNC arguments
args+=("-localhost")
args+=("-rfbport 5900")
args+=("-AlwaysShared")
args+=("-AcceptKeyEvents")
args+=("-AcceptPointerEvents")
args+=("-AcceptSetDesktopSize")
args+=("-SendCutText")
args+=("-AcceptCutText")
export VNC_ARGS="${args[*]}"

# Permissions
chown -R app:app /app /data /dev/stdout

exec /usr/sbin/gosu app supervisord

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

# Local connection only
if [ "$ALLOW_DIRECT_VNC" = false ] ; then
    args+=("-localhost")
else
    echo "Attention! VNC Port 5900 is bound to all interfaces, no limit!"
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

exec /usr/sbin/gosu ${USER_ID}:${GROUP_ID} supervisord

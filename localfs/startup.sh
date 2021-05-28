#!/bin/bash

export LAUNCH=${@:-null}

[[ $LAUNCH == "null" ]] && export AUTOSTART=false || export AUTOSTART=true

echo "Starting with UID : $USER_ID"
echo "Launching : $LAUNCH"

groupadd --gid ${GROUP_ID} app
useradd --home-dir /app --shell /bin/bash --uid ${USER_ID} --gid ${GROUP_ID} app

chown -R app:app /app /data /dev/stdout

exec /usr/sbin/gosu app supervisord

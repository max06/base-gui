# syntax=docker/dockerfile:1.19
# check=skip=SecretsUsedInArgOrEnv

# The base-image to be used
ARG OS=debian:trixie-slim

# The build starts here.
FROM $OS

ARG OS

LABEL Name=base-gui Author=max06/base-gui Flavor=$OS

# Container Language
ENV LANG=en_US.UTF-8
ENV LC_ALL=${LANG}

# App options
ENV USER_ID=1000 GROUP_ID=1000 APP=unknown UMASK=0022 PASSWORD="" ALLOW_DIRECT_VNC=false

# Configure apt and install required packages
RUN \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt -q update && \
  LC_ALL=C DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends -y --ignore-missing \
  gosu \
  locales \
  openbox \
  supervisor \
  tigervnc-common \
  tigervnc-tools \
  tigervnc-standalone-server \
  tint2 \
  ca-certificates \
  python3-minimal \
  python3-setuptools \
  nginx-light && \
  rm /var/cache/fontconfig/*

# novnc installation
COPY --from=novnc /tmp/ /opt/novnc/

# install websockify
RUN --mount=type=bind,from=websockify,source=/tmp,target=/tmp/websockify,rw \
  cd /tmp/websockify && \
  python3 setup.py install

# Copy configuration files and scripts
COPY localfs/ /
RUN chmod +x /usr/local/bin/startup.sh

# Add user to avoid root and create directories
RUN mkdir -p /app /data
WORKDIR /app

# Web viewer
EXPOSE 4000

# Create locale (in subsequent build)
ONBUILD RUN sed -i "/${LANG}/s/^# //g" /etc/locale.gen && locale-gen

# And there we go!
ENTRYPOINT [ "/usr/local/bin/startup.sh" ]

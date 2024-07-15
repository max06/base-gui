# syntax=docker/dockerfile:1.7-labs
ARG OS=debian:bookworm-slim

# Multistage build

# Stage 1: Get novnc
FROM $OS AS novnc

ARG NOVNC_VERSION=v1.5.0

ADD --exclude=AUTHORS \
        --exclude=docs \
        --exclude=eslint.config.mjs \
        --exclude=karma.conf.js \
        --exclude=package.json \
        --exclude=po \
        --exclude=README.md \
        --exclude=snap \
        --exclude=tests \
        --exclude=vnc_lite.html \
    https://github.com/novnc/noVNC.git#${NOVNC_VERSION} \
    /app/novnc/


# Stage 2: Final image
FROM $OS

LABEL Name=base-gui Author=max06/base-gui Flavor=$OS

ARG PKG="apt-get install --no-install-recommends -y --ignore-missing"

ENV LANG en_US.UTF-8
ENV LC_ALL ${LANG}

ENV USER_ID=1000 GROUP_ID=1000
ENV APP=unknown
ENV PASSWORD=""
ENV UMASK=0022
ENV ALLOW_DIRECT_VNC=false

# Prepare installation
RUN apt-get -q update
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive ${PKG} lsb-release

# Install all the stuff
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive ${PKG} \
    gosu \
    locales \
    openbox \
    supervisor \
    tigervnc-common \
    $(lsb_release -sc | grep -q bookworm && echo tigervnc-tools) \
    tigervnc-standalone-server \
    tint2 \
    python3-pip \
    python3-venv \
    nginx-light

# Cleanup
RUN apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/fontconfig/*

# novnc installation and patching
COPY --from=novnc /app/novnc/ /opt/novnc/
RUN sed -i "s/UI.initSetting('resize', 'off')/UI.initSetting('resize', 'remote')/g" /opt/novnc/app/ui.js


# install websockify
RUN python3 -m venv /opt/websockify
RUN /opt/websockify/bin/pip3 install websockify

# prepare nginx
COPY localfs/nginx/vnc.conf /etc/nginx/sites-enabled/vnc.conf

# Place our own configuration files
COPY localfs/supervisord.conf /etc/
COPY localfs/startup.sh /usr/local/bin/
COPY localfs/tint2rc /etc/xdg/tint2/
COPY localfs/openbox-autostart /etc/xdg/openbox/autostart
RUN chmod +x /usr/local/bin/startup.sh

# Add user to avoid root and create directories
RUN mkdir -p /app /data

# Set working dir
WORKDIR /app

# Web viewer
EXPOSE 4000

# Create locale (in subsequent build)
ONBUILD RUN sed -i "/${LANG}/s/^# //g" /etc/locale.gen && locale-gen

# And there we go!
ENTRYPOINT [ "/usr/local/bin/startup.sh" ]

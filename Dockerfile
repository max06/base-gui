ARG OS=debian:bookworm-slim

# Multistage build

# Stage 1: Get novnc
FROM bitnami/git:2.45.2 as novnc

ARG NOVNC_VERSION=v1.5.0

WORKDIR /app
RUN git clone --depth 1 --branch ${NOVNC_VERSION} https://github.com/novnc/novnc

# Stage 2: Final image
FROM $OS

LABEL Name=base-gui Author=max06/base-gui Flavor=$OS

ARG PKG="apt-get install --no-install-recommends -y --ignore-missing"

ENV LANG=en_US.UTF-8
ENV LC_ALL=${LANG}

ENV USER_ID=1000 GROUP_ID=1000
ENV APP=unknown
ENV PASSWORD=""
ENV UMASK=0022
ENV ALLOW_DIRECT_VNC=false

# Prepare installation
RUN apt-get -q update > /dev/null && \
    apt-get -q -y upgrade > dev/null && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive ${PKG} apt-utils lsb-release && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive ${PKG} \
        gosu \
        locales \
        nginx-light \
        openbox \
        python3-pip \
        python3-venv \
        supervisor \
        tigervnc-common \
        tigervnc-standalone-server \
        $(lsb_release -sc | grep -q bookworm && echo tigervnc-tools) \
        tint2 && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/fontconfig/*

# novnc installation and patching
# then install websockify
# then cleanup novnc artifacts
COPY --from=novnc /app/novnc/ /opt/novnc/
RUN sed -i "s/UI.initSetting('resize', 'off')/UI.initSetting('resize', 'remote')/g" /opt/novnc/app/ui.js && \
    python3 -m venv /opt/websockify && \
    /opt/websockify/bin/pip3 install websockify && \
    cd /opt/novnc && \
    rm -rf .git* .eslint* AUTHORS docs README.md tests

# prepare nginx
COPY localfs/nginx/vnc.conf /etc/nginx/sites-enabled/vnc.conf

# Place our own configuration files
COPY localfs/supervisord.conf /etc/
COPY localfs/startup.sh /usr/local/bin/
COPY localfs/tint2rc /etc/xdg/tint2/
COPY localfs/openbox-autostart /etc/xdg/openbox/autostart

# Add user to avoid root and create directories
RUN chmod +x /usr/local/bin/startup.sh && \
    mkdir -p /app /data

# Set working dir
WORKDIR /app

# Web viewer
EXPOSE 4000

# Create locale (in subsequent build)
ONBUILD RUN sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG

# And there we go!
ENTRYPOINT [ "/usr/local/bin/startup.sh" ]

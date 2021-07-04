# Multistage build

ARG OS=debian:buster-slim

# Building easy-novnc
FROM golang:1.16.4-buster AS easy-novnc-build
WORKDIR /src
RUN go mod init build && \
    go get github.com/geek1011/easy-novnc@v1.1.0 && \
    go build -o /bin/easy-novnc github.com/geek1011/easy-novnc


# Building application container
FROM $OS

LABEL Name=base-gui Author=max06/base-gui Flavor=$OS

ARG PKG="apt-get install --no-install-recommends -y"

ENV LANG en_US.UTF-8
ENV LC_ALL ${LANG} 

ENV USER_ID=1000 GROUP_ID=1000
ENV APP=unknown
ENV PASSWORD=""
ENV ALLOW_DIRECT_VNC=false

# Prepare installation
RUN apt-get -q update

# Install all the stuff
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive ${PKG} \
    gosu \
    locales \ 
    openbox \
    supervisor \
    tigervnc-common \
    tigervnc-standalone-server

# Cleanup
RUN apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/fontconfig/*

# Add easy-novnc from the previous build
COPY --from=easy-novnc-build /bin/easy-novnc /usr/local/bin/

# Place our own configuration files
COPY localfs/supervisord.conf /etc/
COPY localfs/startup.sh /usr/local/bin/
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

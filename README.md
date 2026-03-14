Available Options:

At buildtime:
ARG OS=debian:trixie-slim
ARG NOVNC_VERSION=v1.6.0
ENV LANG=en_US.UTF-8

At runtime:
ENV LANG=en_US.UTF-8 (inherited)
ENV USER_ID=1000 GROUP_ID=1000
ENV APP=unknown
ENV UMASK=0022
ENV PASSWORD=""
ENV ALLOW_DIRECT_VNC=false

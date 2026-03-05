FROM alpine

ARG VERSION

ADD https://github.com/novnc/websockify.git#${VERSION} /tmp

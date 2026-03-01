FROM alpine

ARG VERSION

ADD https://github.com/novnc/novnc.git#${VERSION} /tmp
RUN sed -i "s/UI.initSetting('resize', 'off')/UI.initSetting('resize', 'remote')/g" /tmp/app/ui.js

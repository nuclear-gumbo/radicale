FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

ARG RADICALE_VERSION=3.8.0
ARG S6_OVERLAY_VERSION=3.2.3.2
ARG S6_NOARCH_SHA256=5379750ed30a84bbd2e2dd74847ba6b5bd29cd0b2e3ea2ec58049b57eb2eda12
ARG S6_X86_64_SHA256=e6befcc96a437a3831386ecfc51808c5d3e939dc5fe3c02ae9284599e8aa2408

LABEL org.opencontainers.image.source=https://github.com/nuclear-gumbo/radicale
LABEL org.opencontainers.image.description="Radicale CalDAV/CardDAV server on alpine + s6-overlay"
LABEL org.opencontainers.image.licenses=GPL-3.0-only

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/x86_64.tar.xz

# py3-bcrypt comes from apk so the venv needs no compiler toolchain
RUN echo "${S6_NOARCH_SHA256}  /tmp/noarch.tar.xz" | sha256sum -c - \
    && echo "${S6_X86_64_SHA256}  /tmp/x86_64.tar.xz" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/noarch.tar.xz \
    && tar -C / -Jxpf /tmp/x86_64.tar.xz \
    && rm /tmp/*.tar.xz \
    && apk add --no-cache python3 py3-bcrypt tzdata \
    && apk add --no-cache --virtual .venv-deps py3-pip \
    && python3 -m venv --system-site-packages /app \
    && /app/bin/pip install --no-cache-dir "radicale==${RADICALE_VERSION}" \
    && apk del .venv-deps

COPY rootfs /

VOLUME /var/lib/radicale
EXPOSE 5232

ENTRYPOINT [ "/init" ]

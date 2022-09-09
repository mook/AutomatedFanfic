FROM python:3.9-slim

# set version label
ARG VERSION
ARG CALIBRE_RELEASE
ARG FFF_RELEASE
LABEL build_version="FFDL-Auto version:- ${VERSION} Calibre: ${CALIBRE_RELEASE} FFF: ${FFF_RELEASE}"

ENV PUID="911" \
    PGID="911"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -x && \
    apt-get update && \
    apt-get install -y --upgrade \
    bash \
    ca-certificates \
    gcc \
    wget \
    xdg-utils \
    curl \
    dbus \
    jq \
    python3 \
    calibre

RUN set -x && \
    addgroup --gid "$PGID" abc && \
    adduser \
        --gecos "" \
        --disabled-password \
        --no-create-home \
        --uid "$PUID" \
        --ingroup abc \
        --shell /bin/bash \
        abc 

RUN dbus-uuidgen > /etc/machine-id

RUN echo "**** s6 omsta;; ****" && \
	set -ex && \
    ARCH=`uname -m` && \
    if [ "$ARCH" = "x86_64" ]; then \
        s6_package="s6-overlay-amd64.tar.gz" ; \
    elif [ "$ARCH" = "aarch64" ]; then \
        s6_package="s6-overlay-aarch64.tar.gz" ; \
    else \
        echo "unknown arch: ${ARCH}" && \
        exit 1 ; \
    fi && \
    wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/${s6_package} && \
    tar -xzf /tmp/${s6_package} -C /

RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    echo *** Install Packages *** && \
	set -x && \
    if [ -z ${FFF_RELEASE+x} ]; then \
        python3 -m pip install FanFicFare; \
    else \
        python3 -m pip install --extra-index-url https://testpypi.python.org/pypi FanFicFare==${FFF_RELEASE}; \
    fi && \
    python3 -m pip install pushbullet.py pillow && \
    ln -s /opt/calibre/calibredb /bin/calibredb

COPY root/ /

VOLUME /config

WORKDIR /config

ENTRYPOINT ["/init"]

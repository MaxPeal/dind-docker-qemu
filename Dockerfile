ARG QEMU_VER=3
ARG HTTP_PROXY
ARG http_proxy
ARG HTTPS_PROXY
ARG https_proxy
ARG FTP_PROXY
ARG ftp_proxy
ARG NO_PROXY
ARG no_proxy
ARG TARGETPLATFORM
# - platform of the build result. Eg linux/amd64, linux/arm/v7, windows/amd64.
ARG TARGETOS
# - OS component of TARGETPLATFORM
ARG TARGETARCH
# - architecture component of TARGETPLATFORM
ARG TARGETVARIANT
# - variant component of TARGETPLATFORM
ARG BUILDPLATFORM
# - platform of the node performing the build.
ARG BUILDOS
# - OS component of BUILDPLATFORM
ARG BUILDARCH
# - architecture component of BUILDPLATFORM
ARG BUILDVARIANT
# - variant component of BUILDPLATFORM
FROM tianon/qemu:${QEMU_VER} as builder

#ARG ARCH=
#FROM ${ARCH}debian:buster-slim
# https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/
# https://www.docker.com/blog/multi-arch-images/


RUN apt-get update -qq &&\
    apt-get install -y \
        signify-openbsd \
        curl \
        wget \
        rsync \
        gpg \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY key-setup.sh /
RUN bash key-setup.sh
COPY run.sh /
RUN bash run.sh
CMD ["bash", "run.sh"]

#FROM builder


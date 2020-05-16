# syntax = <frontend image>, e.g. # syntax = docker/dockerfile:1.0-experimental
# syntax = docker/dockerfile:1.0-experimental
# https://docs.docker.com/develop/develop-images/build_enhancements/
#ARG QEMU_VER=3
ARG QEMUVER
ENV QEMU_VER=${QEMUVER:-4}
ARG TAG
ENV TAGvar=${TAG:-word}
#ENV env_var_name=$var_name
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

ARG SOURCE_BRANCH
#: the name of the branch or the tag that is currently being tested.
ARG SOURCE_COMMIT
#: the SHA1 hash of the commit being tested.
ARG COMMIT_MSG
#: the message from the commit being tested and built.
ARG DOCKER_REPO
#: the name of the Docker repository being built.
ARG DOCKERFILE_PATH
#: the dockerfile currently being built.
ARG DOCKER_TAG
#: the Docker repository tag being built.
ARG IMAGE_NAME
#: the name and tag of the Docker repository being built. (This variable is a combination of DOCKER_REPO:DOCKER_TAG.)

FROM tianon/qemu:${QEMU_VER} as builder
RUN ECHO tagvar $TAGvar tagvar
RUN ECHO tag $TAG tag



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
#RUN bash run.sh
CMD ["bash", "run.sh"]

#FROM builder


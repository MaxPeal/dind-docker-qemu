ARG QEMUVER
ENV QEMU_VER=${QEMUVER:-5}
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


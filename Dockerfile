FROM tianon/qemu as builder

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
RUN run.sh
CMD ["bash", "run.sh"]

#FROM builder


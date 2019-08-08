FROM tianon/qemu

RUN apt-get update -qq &&\
    apt-get install -y \
        iputils-ping \
        signify-openbsd \
        curl \
        wget \
        rsync \
        gpg \
        openssh-client \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY key-setup.sh /
RUN bash key-setup.sh
COPY run.sh /

CMD ["bash", "run.sh"]

FROM ubuntu:16.04 as builder

WORKDIR /work

RUN apt-get update && \
    apt-get install -y \
            build-essential \
            libleveldb-dev \
            git \
            libdb-dev \
            libsodium-dev \
            libtinfo-dev \
            sysvbanner \
            unzip \
            wget \
            wrk \
            zlib1g-dev

RUN wget -q https://github.com/jpmorganchase/constellation/releases/download/v0.3.2/constellation-0.3.2-ubuntu1604.tar.xz && \
    tar -xf constellation-0.3.2-ubuntu1604.tar.xz && \
    cp constellation-0.3.2-ubuntu1604/constellation-node /usr/local/bin && \
    chmod 755 /usr/local/bin/constellation-node && \
    rm -rf constellation-0.3.2-ubuntu1604*

ENV GOREL go1.7.3.linux-amd64.tar.gz
ENV PATH $PATH:/usr/local/go/bin

RUN wget -q https://storage.googleapis.com/golang/$GOREL && \
    tar xfz $GOREL && \
    mv go /usr/local/go && \
    rm -f $GOREL

RUN git clone https://github.com/hagishun/quorum.git && \
    cd quorum && \
    git checkout 5e348757614abfa134c92db7a2cd9ec2454a912a && \
    make all && \
    cp build/bin/geth /usr/local/bin && \
    cp build/bin/bootnode /usr/local/bin && \
    cd .. && \
    rm -rf quorum

FROM ubuntu:16.04

# Install add-apt-repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ethereum/ethereum && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libdb-dev \
        libleveldb-dev \
        libsodium-dev \
        libtinfo-dev \
        zlib1g-dev \
        ca-certificates \
        netbase \
        solc && \
    rm -rf /var/lib/apt/lists/*

# Temporary useful tools
COPY --from=builder \
        /usr/local/bin/constellation-node \
        /usr/local/bin/geth \
        /usr/local/bin/bootnode \
    /usr/local/bin/

EXPOSE 30303/tcp 30303/udp 30304/udp 8545/tcp 8546/tcp

COPY run.sh /run.sh
CMD /run.sh
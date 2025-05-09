#===============================
# Stage 1: Build QUIC libraries (nghttp3 + ngtcp2)
#===============================
FROM ubuntu:latest AS quic-builder
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt update && \
    apt install -y \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        git \
        ca-certificates \
        libssl-dev \
        libev-dev \
        libevent-dev \
        libjemalloc-dev \
        libnghttp2-dev \
        libunistring-dev \
        zlib1g-dev \
        cmake \
        ninja-build \
        python3 \
        curl && \
    apt clean

# Clone and build nghttp3 (simplified)
RUN git clone --branch main --single-branch https://github.com/ngtcp2/nghttp3 && \
    cd nghttp3 && \
    make && \
    make install

# Clone and build ngtcp2 (simplified)
RUN git clone --branch main --single-branch https://github.com/ngtcp2/ngtcp2 && \
    cd ngtcp2 && \
    autoreconf -i && \
    ./configure --prefix=/usr \
        --with-openssl \
        --with-libnghttp3=/usr && \
    make -j$(nproc) && \
    make install

#===============================
# Stage 2: Build SmartDNS with QUIC support
#===============================
FROM ubuntu:latest AS builder
ARG openssl_version=3.0.13

COPY --from=quic-builder /usr /usr

RUN apt update && \
    apt install -y \
        build-essential \
        git \
        wget \
        strip-nondeterminism \
        ca-certificates

# Build OpenSSL
RUN wget "https://www.openssl.org/source/openssl-$openssl_version.tar.gz" && \
    tar xf "openssl-$openssl_version.tar.gz" && \
    cd openssl-$openssl_version && \
    ./config && \
    make build_libs -j$(nproc) && \
    make install_dev && \
    cd .. && rm -rf openssl-$openssl_version*

# Build SmartDNS
RUN git clone https://github.com/pymumu/smartdns /smartdns && \
    cd /smartdns && \
    bash package/build-pkg.sh --platform linux --arch x86_64 --static --enable-quic && \
    strip src/smartdns && \
    mkdir -p /release/var/log /release/run /release/etc/smartdns/ /release/usr/sbin/ && \
    cp etc/smartdns/* /release/etc/smartdns/ && \
    cp src/smartdns /release/usr/sbin/ && \
    rm /release/etc/smartdns/smartdns.conf && \
    cd / && rm -rf /smartdns

#===============================
# Stage 3: Final runtime image
#===============================
FROM alpine:latest
COPY --from=builder /release/ /

WORKDIR /
ADD start.sh /start.sh
ADD smartdns.conf /smartdns.conf

RUN chmod +x /usr/sbin/smartdns \
    && chmod +x /start.sh \
    && apk add ipset

VOLUME ["/etc/smartdns"]

CMD ["/start.sh"]

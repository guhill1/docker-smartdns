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
    make -j$(nproc) || (cat config.log && exit 1) && \
    make install || (cat config.log && exit 1)

# Clone and build ngtcp2 (simplified)
RUN git clone --branch main --single-branch https://github.com/ngtcp2/ngtcp2 && \
    cd ngtcp2 && \
    autoreconf -i && \
    ./configure --prefix=/usr \
        --with-openssl \
        --with-libnghttp3=/usr && \
    make -j$(nproc) && \
    make install

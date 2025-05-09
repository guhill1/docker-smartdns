# Build stage
FROM ubuntu:latest AS builder
LABEL first stage

#===========================================================================================================
# Install build dependencies and OpenSSL
ARG openssl_version=3.0.13

RUN apt update && \
    apt install build-essential wget git curl pkg-config libssl-dev libnghttp2-dev -y && \
    wget "https://www.openssl.org/source/openssl-$openssl_version.tar.gz" && \
    tar xf "openssl-$openssl_version.tar.gz" && \
    cd openssl-$openssl_version && \
    ./config && \
    make build_libs -j $(grep "cpu cores" /proc/cpuinfo | wc -l) && \
    make install_dev  && \
    cd .. && \
    rm -rf "openssl-$openssl_version" "openssl-$openssl_version.tar.gz"

#===========================================================================================================
# Install gRPC and QUIC related dependencies
RUN apt install -y cmake libprotobuf-dev protobuf-compiler \
    && git clone https://github.com/grpc/grpc.git /grpc && \
    cd /grpc && \
    git submodule update --init --recursive && \
    make && make install && \
    cd / && rm -rf /grpc

RUN apt install -y libnghttp3-dev

#===========================================================================================================
# Compile SmartDNS
RUN git clone https://github.com/pymumu/smartdns /smartdns && \
    cd /smartdns && \
    # 使用 --enable-quic 标志启用 QUIC（DoQ）
    bash package/build-pkg.sh --platform linux --arch x86_64 --static --enable-quic && \
    strip src/smartdns && \
    mkdir -p /release/var/log /release/run && \
    mkdir -p /release/etc/smartdns/ && \
    mkdir -p /release/usr/sbin/ && \
    cp etc/smartdns/*.* /release/etc/smartdns/ -a && \
    cp src/smartdns /release/usr/sbin/ -a && \
    rm  /release/etc/smartdns/smartdns.conf && \
    cd / && rm -rf /smartdns

# Final stage
FROM alpine:latest
COPY --from=builder /release/ /

# Working directory for smartdns
WORKDIR /

# Add entrypoint and config file
ADD start.sh /start.sh
ADD smartdns.conf /smartdns.conf

# Make files executable and install ipset
RUN chmod +x /usr/sbin/smartdns \
    && chmod +x /start.sh \
    && apk add ipset

# Mount point for configuration
VOLUME ["/etc/smartdns"]

# Start command
CMD ["/start.sh"]

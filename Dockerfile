# Build stage
FROM ubuntu:22.04 AS builder

LABEL stage=builder

ARG DEBIAN_FRONTEND=noninteractive
ARG openssl_version=3.0.13

# 安装依赖（尽量精简，仅用于构建 QUIC 支持）
RUN apt update && \
    apt install -y build-essential git wget curl ca-certificates pkg-config libtool autoconf automake \
                   libev-dev libevent-dev libjemalloc-dev zlib1g-dev cmake ninja-build \
                   libssl-dev && \
    apt clean

# 构建 nghttp3 和 ngtcp2（QUIC 所需） - 会略花时间
RUN git clone --depth=1 https://github.com/ngtcp2/nghttp3 && \
    cd nghttp3 && \
    autoreconf -i && \
    ./configure --prefix=/usr && make -j$(nproc) && make install && \
    cd .. && rm -rf nghttp3

RUN git clone --depth=1 https://github.com/ngtcp2/ngtcp2 && \
    cd ngtcp2 && \
    autoreconf -i && \
    ./configure --prefix=/usr --with-openssl && make -j$(nproc) && make install && \
    cd .. && rm -rf ngtcp2

# 编译 SmartDNS
RUN git clone --depth=1 https://github.com/pymumu/smartdns /smartdns && \
    cd /smartdns && \
    bash package/build-pkg.sh --platform linux --arch x86_64 --static --enable-quic && \
    strip src/smartdns && \
    mkdir -p /release/usr/sbin && \
    cp src/smartdns /release/usr/sbin/ && \
    mkdir -p /release/etc/smartdns && \
    cp -r etc/smartdns/* /release/etc/smartdns/ && \
    rm /release/etc/smartdns/smartdns.conf

# Final image
FROM alpine:latest

COPY --from=builder /release/ /

# 添加执行脚本与配置文件（你可以替换为你自己的）
ADD start.sh /start.sh
ADD smartdns.conf /smartdns.conf

RUN chmod +x /start.sh /usr/sbin/smartdns && \
    apk add --no-cache ipset

VOLUME ["/etc/smartdns"]

CMD ["/start.sh"]

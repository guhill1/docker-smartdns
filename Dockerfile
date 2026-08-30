FROM ubuntu:latest AS builder

# 1. 修复 LABEL 语法（使用 key=value 格式）
LABEL stage="builder"

#===========================================================================================================
# new compile routine
# compile openssl
ARG openssl_version=3.0.13

# 2. 补充 DEBIAN_FRONTEND 防止编译/安装时弹出交互提示，并清空 apt 缓存精简体积
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y --no-install-recommends \
        build-essential \
        wget \
        ca-certificates \
        git \
        perl \
        make \
        gcc \
        libc6-dev && \
    wget "https://www.openssl.org/source/openssl-$openssl_version.tar.gz" && \
    tar xf "openssl-$openssl_version.tar.gz" && \
    cd "openssl-$openssl_version" && \
    ./config && \
    make build_libs -j$(nproc) && \
    make install_dev && \
    cd .. && \
    rm -rf "openssl-$openssl_version" "openssl-$openssl_version.tar.gz"

#=======================================================================================================    
# compile smartdns

RUN git clone https://github.com/pymumu/smartdns /smartdns && \
    cd /smartdns && \
    bash package/build-pkg.sh --platform linux --arch x86_64 --static && \
    strip src/smartdns && \
    mkdir -p /release/var/log /release/run && \
    mkdir -p /release/etc/smartdns/ && \
    mkdir -p /release/usr/sbin/ && \
    cp etc/smartdns/*.* /release/etc/smartdns/ -a && \
    cp src/smartdns /release/usr/sbin/ -a && \
    rm -f /release/etc/smartdns/smartdns.conf && \
    cd / && rm -rf /smartdns && \
    rm -rf /var/lib/apt/lists/*

#=======================================================================================================    
# Runtime stage
FROM alpine:latest

COPY --from=builder /release/ /

WORKDIR /
COPY start.sh /start.sh
COPY smartdns.conf /smartdns.conf

# 3. 补充 libgmpxx/ca-certificates 依赖以确保静态/半静态编译的运行库完整
RUN chmod +x /usr/sbin/smartdns \
    && chmod +x /start.sh \
    && apk add --no-cache ipset ca-certificates

VOLUME ["/etc/smartdns"]

CMD ["/start.sh"]

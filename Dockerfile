FROM ubuntu:22.04 AS builder
LABEL first stage

#======================================================================================================================================
# new compile routine	
# prepare builder
RUN apt update && \
    apt install build-essential wget -y
ARG openssl_version=3.0.13
RUN wget "https://www.openssl.org/source/openssl-$openssl_version.tar.gz"
RUN tar xf "openssl-$openssl_version.tar.gz"
RUN cd openssl-$openssl_version
ARG LIB_dir=~/x64 
RUN ./config --prefix=$LIB_dir && \
    make build_libs -j $(grep "cpu cores" /proc/cpuinfo | wc -l) && \
    make install_dev
RUN cd .. && \
    rm -rf "openssl-$openssl_version" "openssl-$openssl_version.tar.gz"    
ARG LDFLAGS="-L/root/x64/lib"
ARG CFLAGS="-I/root/x64/include"    
RUN apt install -y libssl-dev git && \
    git clone https://github.com/pymumu/smartdns /smartdns
RUN cd /smartdns && \
    bash package/build-pkg.sh --platform linux --arch x86_64 --static && \
    mkdir -p /release/var/log /release/run && \
    strip package/smartdns/usr/smartdns
RUN cp package/smartdns/etc /release/ -a && \
    cp package/smartdns/usr /release/ -a && \
    rm  /release/etc/smartdns/smartdns.conf && \
    cd / && rm -rf /smartdns
    
FROM alpine
COPY --from=builder /release/ /

WORKDIR /
ADD start.sh /start.sh
ADD smartdns.conf /smartdns.conf

RUN chmod +x /usr/sbin/smartdns \
    && chmod +x /start.sh

VOLUME ["/etc/smartdns"]

EXPOSE 53

CMD ["/start.sh"]

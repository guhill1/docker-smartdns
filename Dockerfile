FROM ubuntu:22.04 AS builder
LABEL first stage

#======================================================================================================================================
# new compile routine	
# prepare builder
RUN apt update && \
    apt install -y make gcc libssl-dev && \
    git clone https://github.com/pymumu/smartdns /smartdns && \
    cd /smartdns && \
    LDFLAGS="-L/root/x64/lib" CFLAGS="-I/root/x64/include" bash package/build-pkg.sh --platform linux --arch x86_64 --static && \
    mkdir -p /release/var/log /release/run && \
    strip package/smartdns/usr/smartdns && \
    cp package/smartdns/etc /release/ -a && \
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

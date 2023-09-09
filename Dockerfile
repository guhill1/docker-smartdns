FROM ubuntu:latest AS builder
LABEL first stage

# prepare builder
RUN apt update -y && \
    apt upgrade -y && \
    apt install perl curl make musl-tools musl-dev git openssl -y
    
# do make
RUN git clone https://github.com/pymumu/smartdns /smartdns
RUN cd /smartdns
RUN export CC=musl-gcc
RUN export CFLAGS="-I /opt/build/include"
RUN export LDFLAGS="-L /opt/build/lib -L /opt/build/lib64"
RUN sh ./package/build-pkg.sh --platform linux --arch `dpkg --print-architecture` --static
RUN ( cd package && tar -xvf *.tar.gz && chmod a+x smartdns/etc/init.d/smartdns ) && \
    \
    mkdir -p /release/var/log /release/run
RUN cp package/smartdns/etc /release/ -a
RUN cp package/smartdns/usr /release/ -a
RUN rm  /release/etc/smartdns/smartdns.conf
RUN cd / && rm -rf /smartdns
    
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

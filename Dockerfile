FROM debian:bookworm-slim AS builder

LABEL first stage

RUN export URL=https://api.github.com/repos/pymumu/smartdns/releases/latest \
  && export OS="linux" \
  && apt-get update -y \
  && apt-get install curl wget -y \
  && cd / \
  && wget --tries=3 $(curl -s $URL | grep browser_download_url | egrep -o 'http.+\.\w+' | grep -i "$(uname -m)" | grep -m 1 -i "$(echo $OS)") \
  && tar zxvf smartdns.*.tar.gz

FROM alpine

COPY --from=builder /smartdns/usr/sbin/smartdns /bin/smartdns

ADD start.sh /start.sh
ADD config.conf /config.conf

RUN chmod +x /bin/smartdns \
    && chmod +x /start.sh

WORKDIR /

VOLUME ["/smartdns"]

EXPOSE 53

CMD ["/start.sh"]

# smartdns docker

smartdns,
https://github.com/pymumu/smartdns

```
安裝
```
```
docker stop smartdns && docker rm smartdns
  
docker run -d \
  -p 6053:6053/udp \
  -p 7053:7053/udp \
  -p 6053:6053/tcp \
  -p 7053:7053/tcp \
  -v /docker/smartdns/:/etc/smartdns/ \
  --restart=always \
  --name=smartdns \
  ghcr.io/guhill1/docker-smartdns
```
```
release使用方法
```
docker import snartdns.tar smartdns

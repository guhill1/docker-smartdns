# smartdns docker

smartdns,
https://github.com/pymumu/smartdns

```
安裝
```
<PRE>
docker stop smartdns && docker rm smartdns
<br>
<br>
docker run -d \\<br>
  -p 6053:6053/udp \\<br>
  -p 7053:7053/udp \\<br>
  -p 6053:6053/tcp \\<br>
  -p 7053:7053/tcp \\<br>
  -v /docker/smartdns/:/etc/smartdns/ \\<br>
  --restart=always \\<br>
  --name=smartdns \\<br>
  ghcr.io/guhill1/docker-smartdns
</PRE>
```
release使用方法
```
docker import snartdns.tar smartdns

# smartdns docker

smartdns,
https://github.com/pymumu/smartdns

```
安裝
```
docker stop smartdns && docker rm smartdns
<br>
<br>
docker run -d \\<br>
&nbsp&nbsp -p 6053:6053/udp \\<br>
&nbsp&nbsp -p 7053:7053/udp \\<br>
&nbsp&nbsp -p 6053:6053/tcp \\<br>
&nbsp&nbsp -p 7053:7053/tcp \\<br>
&nbsp&nbsp -v /docker/smartdns/:/etc/smartdns/ \\<br>
&nbsp&nbsp --restart=always \\<br>
&nbsp&nbsp --name=smartdns \\<br>
&nbsp&nbsp ghcr.io/guhill1/docker-smartdns
```
release使用方法
```
docker import snartdns.tar smartdns

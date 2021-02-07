# myip_server
Python base web-server that show requester IP.

`X-Forwarded-For` should be pass if run after ther proxy.

**to run:**
`docker run -d -p 80:8081 --name myip-server valch85/myip_server`
or use `myipserver.service` file.



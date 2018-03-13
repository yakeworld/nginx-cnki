# nginx-cnki

这是为了解决医院内网访问外网文献数据库问题；

利用nginx来作为反向代理；

需要使用ngx_http_substitutions_filter_module来进行网址替换

努力增加SSL访问支持。

配置参考文章：http://www.ituring.com.cn/article/217692

    docker run --rm -p 80:80 -p 443:443 \

        -v /var/nginx/letsencrypt:/etc/letsencrypt \

        quay.io/letsencrypt/letsencrypt auth \

        --standalone -m someone@email.com --agree-tos \

        -d your.domain1.com -d your.domain2.com

--rm选项表示容器运行结束后自动删除；两个-p选项表示映射主机的两个端口，因为certbot需要通过这两个端口来做验证，这里需要注意的是，我的nginx容器已经占用了这两个端口，因此在申请证书之前，需要先停止nginx容器；-v选项表示映射磁盘数据卷，因为certbot会将所有信息保存在/etc/letsencrypt目录中，我们需要让这个目录的内容持久化并可以从主机以及其他容器（主要是nginx容器）访问它。

证书签发之后，会存放到/etc/letsencrypt目录中，刚才我们映射了数据卷，因此可以直接从宿主机中看到这个目录中的内容，其中证书位于/etc/letsencrypt/live/your.domain1.com中。接下来需要让nginx容器也能够读取这些证书，方法放简单，把这个目录映射给nginx容器就可以了：

    docker run --name nginx-cnki -p 80:80 -p 443:443 \

        -v /var/nginx/conf.d:/usr/local/nginx/conf.d \

        -v /var/nginx/letsencrypt/live:/usr/local/external \

        nginx-cnki

第一个-v是存放nginx配置文件的目录，第二个-v就是存放证书的目录，接下来我们在网站的配置文件里把证书配上去

    server {

        listen 443 ssl;

        server_name www.google.co.uk.proxy.yakeworld.top;

        resolver 8.8.8.8;

        ssl_certificate /usr/local/nginx/external/www.youtube.com.proxy.yakeworld.top/fullchain.pem;

        ssl_certificate_key /usr/local/nginx/external/www.youtube.com.proxy.yakeworld.top/privkey.pem;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

        proxy_set_header Host $host;

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_set_header X-Real-IP $remote_addr;

        proxy_set_header X-Forwarded-Proto $scheme;

        location / {

            subs_filter_types text/css text/xml;

            subs_filter //([^/'"]+) //$1.proxy.yakeworld.top irg;

            proxy_set_header Accept-Encoding "";

            proxy_pass https://www.google.co.uk;

            proxy_redirect https://www.google.co.uk/ https://www.google.co.uk.proxy.yakeworld.top/;

        }

    }

配置文件主要就是ssl_certificate和ssl_certificate_key两行，第一行是提供给客户端的公钥（证书），第二行是服务器用来解密客户端消息的私钥（私钥不会，也不应该在网络上传输）。后面第二个server块是将直接用HTTP的访问重定向到HTTPS连接上。

修改好配置文件之后重启nginx容器，顺利的话网站就可以通过HTTPS访问了，可以通过浏览器看一下证书信息，颁发者是Let's Encrypt Authority X3，它的根CA是DST，即IdenTrust，这是一个为银行和金融提供证书的可信CA，通过和IdenTrust交叉验证，Let's Encrypt的证书可以在各种浏览器上确保可信。不过Let's Encrypt签发的证书是短效证书，有效期只有3个月，但没关系，我们可以通过一个简单的命令对证书进行更新，同样是通过docker容器来运行：

    docker run --rm -p 80:80 -p 443:443 \

        -v /var/nginx/letsencrypt:/etc/letsencrypt \

        quay.io/letsencrypt/letsencrypt renew \

        --standalone

运行这个命令时，certbot会自动检查确认证书有效期，如果过期时间在一个月之内，就会自动更新。在CoreOS中，由于没有Cron，我们需要通过systemd的timer来做定时调度，比如每个月运行一次这个renew任务就可以了，不过记得运行之前先停止nginx容器，运行之后再启动nginx容器。

除了standalone方式验证之外，还可以使用wwwroot方式来做验证，但在我的环境中，nginx容器只是反向代理，本身没有wwwroot，因此standalone方式比较简单，当然缺点是每次签发和更新证书都要先停止nginx容器，这会造成网站服务中断。如果需要保证服务不中断，可以为nginx容器单独配一个验证用的wwwroot。

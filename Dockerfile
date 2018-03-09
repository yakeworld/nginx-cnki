FROM ubuntu
MAINTAINER yakeworld@gmail.com 
RUN apt update \
    && apt-get -yq install build-essential wget git openssl  \
    && mkdir /var/nginx \
    && wget -qO- http://nginx.org/download/nginx-1.13.9.tar.gz | tar xz -C /var/nginx/  \
    && wget -qO-  ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.41.tar.gz | tar xz -C /var/nginx/  \
    && wget --no-check-certificate  -qO-  https://www.openssl.org/source/openssl-1.0.2n.tar.gz | tar xz -C /var/nginx/ \
    && wget -qO-  http://www.zlib.net/zlib-1.2.11.tar.gz | tar xz -C /var/nginx/  \
    && git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git /var/nginx/ngx_http_substitutions_filter_module/ \
    && cd /var/nginx/pcre-8.41 \
    && ./configure \
    && make \
    && make install \
    && cd /var/nginx/zlib-1.2.11 \
    && ./configure \
    && make \
    && make install \
    && cd /var/nginx/nginx-1.13.9 \
    && ./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --with-ipv6 --with-http_sub_module --add-module=/var/nginx/ngx_http_substitutions_filter_module  --with-openssl=/var/nginx/openssl-1.0.2n   --with-zlib=/var/nginx/zlib-1.2.11 \
    && make \
    && make install \
    && cd / \
    && rm -r /var/nginx \
    && useradd -s /sbin/nologin -M www \
    && mkdir -p /usr/local/nginx/external \
    && mkdir -p /usr/local/nginx/conf.d \
    && rm /usr/local/nginx/nginx.conf

ADD nginx.conf /usr/local/nginx/nginx.conf
ADD basic.conf /usr/local/nginx/conf.d/basic.conf
ADD ssl.conf /usr/local/nginx/conf.d/ssl.conf
ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod a+x /opt/entrypoint.sh
ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/usr/local/nginx/sbin/nginx"]    
    

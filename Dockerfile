FROM wojiushixiaobai/tomcat8:latest
LABEL maintainer "wojiushixiaobai"
WORKDIR /config

COPY guacamole-server-0.9.14.tar.gz guacamole-server-0.9.14.tar.gz
COPY entrypoint.sh /bin/entrypoint.sh

RUN set -ex \
    && yum -y update \
    && yum install -y cairo-devel libjpeg-turbo-devel libpng-devel uuid-devel \
    && yum install -y ffmpeg-devel freerdp-devel pango-devel libssh2-devel libtelnet-devel libvncserver-devel pulseaudio-libs-devel openssl-devel libvorbis-devel libwebp-devel ghostscript \
    && ln -s /usr/local/lib/freerdp/guacsnd.so /usr/lib64/freerdp/ \
    && ln -s /usr/local/lib/freerdp/guacdr.so /usr/lib64/freerdp/ \
    && ln -s /usr/local/lib/freerdp/guacai.so /usr/lib64/freerdp/ \
    && ln -s /usr/local/lib/freerdp/guacsvc.so /usr/lib64/freerdp/ \
    && tar xf guacamole-server-0.9.14.tar.gz \
    && cd guacamole-server-0.9.14 \
    && autoreconf -fi \
    && ./configure --with-init-dir=/etc/init.d \
    && make \
    && make install \
    && cd .. \
    && rm -rf guacamole-server-0.9.14.tar.gz guacamole-server-0.9.14 \
    && ldconfig \
    && mkdir -p guacamole/lib \
    && mkdir -p guacamole/extensions \
    && chmod +x /bin/entrypoint.sh \
    && yum clean all \
    && rm -rf /var/cache/yum/*

COPY guacamole-0.9.14.war /config/tomcat8/webapps/ROOT.war
COPY guacamole-auth-jumpserver-0.9.14.jar /config/guacamole/extensions
COPY root/app/guacamole/guacamole.properties /config/guacamole
COPY readme.txt readme.txt

ENV JUMPSERVER_KEY_DIR=/config/guacamole/keys \
    GUACAMOLE_HOME=/config/guacamole \
    JUMPSERVER_ENABLE_DRIVE=true \
    JUMPSERVER_SERVER=http://127.0.0.1:8080

VOLUME /config/guacamole/keys

EXPOSE 8081
ENTRYPOINT ["entrypoint.sh"]

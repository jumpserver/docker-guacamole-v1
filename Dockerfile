FROM centos:7.5.1804
LABEL maintainer "wojiushixiaobai"
WORKDIR /opt

RUN yum -y update && \
    yum -y localinstall --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm && \
    rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro && \
    rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm && \
    yum install -y git gcc java-1.8.0-openjdk libtool && \
    yum install -y cairo-devel libjpeg-turbo-devel libpng-devel uuid-devel && \
    yum install -y ffmpeg-devel freerdp-devel pango-devel libssh2-devel libtelnet-devel libvncserver-devel pulseaudio-libs-devel openssl-devel libvorbis-devel libwebp-devel && \
    yum clean all && \
    rm -rf /var/cache/yum/*

COPY docker-guacamole docker-guacamole
COPY entrypoint.sh /bin/entrypoint.sh

RUN yum install -y wget make && \
    wget http://mirror.bit.edu.cn/apache/tomcat/tomcat-8/v8.5.34/bin/apache-tomcat-8.5.34.tar.gz && \
    mkdir /config && \
    tar xf apache-tomcat-8.5.34.tar.gz -C /config && \
    mv /config/apache-tomcat-8.5.34 /config/tomcat8 && \
    sed -i 's/Connector port="8080"/Connector port="8081"/g' `grep 'Connector port="8080"' -rl /config/tomcat8/conf/server.xml` && \
    sed -i 's/FINE/WARNING/g' `grep 'FINE' -rl /config/tomcat8/conf/logging.properties` && \
    echo "java.util.logging.ConsoleHandler.encoding = UTF-8" >> /config/tomcat8/conf/logging.properties && \
    mkdir -p /config/guacamole \
    /config/guacamole/lib \
    /config/guacamole/extensions && \
    cd /opt/docker-guacamole && \
    tar -xzf guacamole-server-0.9.14.tar.gz && \
    cd guacamole-server-0.9.14 && \
    autoreconf -fi && \
    ./configure --with-init-dir=/etc/init.d && \
    make && \
    make install && \
    cd .. && \
    rm -rf guacamole-server-0.9.14.tar.gz guacamole-server-0.9.14 && \
    ldconfig && \
    rm -rf /config/tomcat8/webapps/* && \
    cp guacamole-0.9.14.war /config/tomcat8/webapps/ROOT.war && \
    cp guacamole-auth-jumpserver-0.9.14.jar /config/guacamole/extensions && \
    cp root/app/guacamole/guacamole.properties /config/guacamole/ && \
    rm -rf /opt/* && \
    yum clean all && \
    rm -rf /var/cache/yum/* && \
    chmod +x /bin/entrypoint.sh

copy readme.txt readme.txt

ENV JUMPSERVER_KEY_DIR=/config/guacamole/keys \
    GUACAMOLE_HOME=/config/guacamole \
    JUMPSERVER_SERVER=http://127.0.0.1:8080

VOLUME /config/guacamole/keys

EXPOSE 8081
ENTRYPOINT ["entrypoint.sh"]
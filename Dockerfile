FROM library/tomcat:9-jre8

ENV ARCH=amd64 \
  GUAC_VER=1.0.0 \
  GUACAMOLE_HOME=/app/guacamole

# Apply the s6-overlay
COPY s6-overlay-${ARCH}.tar.gz .

#RUN curl -SLO "https://github.com/just-containers/s6-overlay/releases/download/v1.20.0.0/s6-overlay-${ARCH}.tar.gz" \
RUN tar -xzf s6-overlay-${ARCH}.tar.gz -C / \
  && tar -xzf s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
  && rm -rf s6-overlay-${ARCH}.tar.gz \
  && mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

WORKDIR ${GUACAMOLE_HOME}

RUN sed -i  's/deb.debian.org/mirrors.163.com/g' /etc/apt/sources.list
RUN sed -i  's/security.debian.org/mirrors.163.com/g' /etc/apt/sources.list
# Install dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev \
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev libfreerdp-dev libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev \
    ghostscript  \
  && rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
COPY guacamole-server-${GUAC_VER}.tar.gz .
# RUN curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
RUN tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
  && cd guacamole-server-${GUAC_VER} \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
  && ldconfig

# Install guacamole-client and postgres auth adapter
RUN rm -rf ${CATALINA_HOME}/webapps/ROOT
#  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "https://sourceforge.net/projects/guacamole/files/current/binary/guacamole-${GUAC_VER}.war"
COPY guacamole-${GUAC_VER}.war ${CATALINA_HOME}/webapps/ROOT.war

ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV GUACAMOLE_HOME=/config/guacamole
RUN mkdir -p ${GUACAMOLE_HOME}/extensions 
# curl -SLo ${GUACAMOLE_HOME}/extensions/guacamole-auth-jumpserver-${GUAC_VER}.jar "https://s3.cn-north-1.amazonaws.com.cn/tempfiles/guacamole-jumpserver/guacamole-auth-jumpserver-${GUAC_VER}.jar"
COPY guacamole-auth-jumpserver-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/guacamole-auth-jumpserver-${GUAC_VER}.jar

# Install ssh-forward for support 
COPY ssh-forward.tar.gz /tmp/
RUN tar xvf /tmp/ssh-forward.tar.gz -C /bin/ && chmod +x /bin/ssh-forward
WORKDIR /config

COPY root /

ENTRYPOINT [ "/init" ]



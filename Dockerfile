FROM library/tomcat:9-jre8

ENV ARCH=amd64 \
  GUACD_VER=1.2.0 \
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

RUN curl -o /etc/apt/sources.list "https://mirrors.163.com/.help/sources.list.stretch"
# Install dependencies
RUN apt-get update && apt-get install -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev \
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev freerdp2-dev libfreerdp-client2-2 libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev \
    ghostscript  \
  && rm -rf /var/lib/apt/lists/*

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server
COPY guacamole-server-${GUACD_VER}.tar.gz .
RUN tar -xzf guacamole-server-${GUACD_VER}.tar.gz \
  && cd guacamole-server-${GUACD_VER} \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make install \
  && cd .. \
  && rm -rf guacamole-server-${GUACD_VER}.tar.gz guacamole-server-${GUACD_VER} \
  && ldconfig

# Install guacamole-client and postgres auth adapter
RUN rm -rf ${CATALINA_HOME}/webapps/ROOT

COPY guacamole-${GUAC_VER}.war ${CATALINA_HOME}/webapps/ROOT.war

ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV GUACAMOLE_HOME=/config/guacamole
RUN mkdir -p ${GUACAMOLE_HOME}/extensions 
COPY guacamole-auth-jumpserver-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/guacamole-auth-jumpserver-${GUAC_VER}.jar

# Install ssh-forward for support 
COPY ssh-forward.tar.gz /tmp/
RUN tar xvf /tmp/ssh-forward.tar.gz -C /bin/ && chmod +x /bin/ssh-forward
WORKDIR /config

COPY root /

ENTRYPOINT [ "/init" ]



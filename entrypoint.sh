#!/bin/bash
#

/etc/init.d/guacd start
cd /config/tomcat8/bin && ./startup.sh
tail -f /opt/readme.txt
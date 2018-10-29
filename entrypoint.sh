#!/bin/bash
#

export LC_ALL=zh_CN.UTF-8

/etc/init.d/guacd start
cd /config/tomcat8/bin && ./startup.sh
tail -f /config/readme.txt
#!/bin/sh


sed -i "s/66666/$PORT/g" /etc/v2ray/config.json
sed -i "s/your_uuid/$UUID/g" /etc/v2ray/config.json

#/usr/bin/v2ray/v2ray -config=/etc/v2ray/config.json

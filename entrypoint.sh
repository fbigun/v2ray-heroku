cd /v2raybin
if [ "$VER" = "latest" ]; then
  wget http://storage.googleapis.com/v2ray-docker/v2ray 
  wget http://storage.googleapis.com/v2ray-docker/v2ctl
  wget http://storage.googleapis.com/v2ray-docker/geoip.dat
  wget http://storage.googleapis.com/v2ray-docker/geosite.dat
else
  wget -O v2ray.zip http://github.com/v2ray/v2ray-core/releases/download/v$VER/v2ray-linux-64.zip
  unzip v2ray.zip 
  mv /v2raybin/v2ray-v$VER-linux-64/v2ray .
  mv /v2raybin/v2ray-v$VER-linux-64/v2ctl .
  mv /v2raybin/v2ray-v$VER-linux-64/geoip.dat .
  mv /v2raybin/v2ray-v$VER-linux-64/geosite.dat .
fi

chmod +x v2ray
chmod +x v2ctl

#echo -e -n "$CONFIG_JSON1" > config.json
#echo -e -n "$PORT" >> config.json
#echo -e -n "$CONFIG_JSON2" >> config.json
#echo -e -n "$UUID" >> config.json
#echo -e -n "$CONFIG_JSON3" >> config.json

sed -i "s/66666/$PORT/g" config.json
sed -i "s/your_uuid/$UUID/g" config.json

./v2ray

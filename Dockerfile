FROM v2ray/official as download


FROM heroku/heroku:18

LABEL maintainer 'fbigun <olutyo@gmail.com>'

ENV PATH /usr/bin/v2ray:$PATH
COPY --from=download /usr/bin/v2ray/v2ray /usr/bin/v2ray/
COPY --from=download /usr/bin/v2ray/v2ctl /usr/bin/v2ray/
COPY --from=download /usr/bin/v2ray/geoip.dat /usr/bin/v2ray/
COPY --from=download /usr/bin/v2ray/geosite.dat /usr/bin/v2ray/
COPY server_config.json /etc/v2ray/config.json
ADD entrypoint.sh .

RUN set -ex && \
    mkdir /var/log/v2ray/ &&\
    chmod +x /usr/bin/v2ray/v2ctl && \
    chmod +x /usr/bin/v2ray/v2ray

CMD ["/bin/sh", "/entrypoint.sh"]

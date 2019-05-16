FROM v2ray/official

RUN adduser -D myuser
USER myuser

WORKON /usr/bin/v2ray/
ADD entrypoint.sh /usr/bin/v2ray/

CMD ["/bin/sh", "/usr/bin/v2ray/entrypoint.sh"]

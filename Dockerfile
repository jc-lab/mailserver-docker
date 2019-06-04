FROM ubuntu:18.04
MAINTAINER Jichan Lee <development@jc-lab.net>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-client libmariadbclient18 postfix postfix-cdb postfix-mysql dovecot-core dovecot-pop3d dovecot-imapd dovecot-mysql dovecot-lmtpd syslog-ng && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 11000 vmail && useradd -g vmail -u 11000 vmail && \
    mkdir -p /mail-storage && \
    chown vmail:vmail -R /mail-storage && \
    mkdir -p /secret

RUN touch /etc/postfix/sasl_passwd && postmap /etc/postfix/sasl_passwd

COPY ["template", "/template"]
COPY ["init.sh", "/"]

RUN chmod +x /init.sh && touch /etc/postfix/sasl_passwd && postmap /etc/postfix/sasl_passwd

CMD ["/init.sh"]


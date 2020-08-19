FROM alpine:3.12
MAINTAINER Joseph Lee <development@jc-lab.net>

RUN adduser -D -g vmail -u 11000 vmail && \
    mkdir -p /mail-storage && \
    chown vmail:vmail -R /mail-storage && \
    mkdir -p /secret

RUN apk add bash procps mariadb-client postfix postfix-mysql dovecot dovecot-sql dovecot-pop3d dovecot-mysql dovecot-lmtpd syslog-ng opendkim opendkim-utils

RUN touch /etc/postfix/sasl_passwd && postmap /etc/postfix/sasl_passwd

COPY ["template", "/template"]
COPY ["init.sh", "/"]

RUN chmod +x /init.sh && \
    touch /etc/postfix/sasl_passwd && \
    postmap /etc/postfix/sasl_passwd && \
    rm -f /var/log/auth.log /var/log/error.log /var/log/boot.log /var/log/cron.log /var/log/kern.log /var/log/mail.log /var/log/messages && \
    ln -s /proc/1/fd/1 /var/log/auth.log && \
    ln -s /proc/1/fd/1 /var/log/error.log && \
    ln -s /proc/1/fd/1 /var/log/boot.log && \
    ln -s /proc/1/fd/1 /var/log/cron.log && \
    ln -s /proc/1/fd/1 /var/log/kern.log && \
    ln -s /proc/1/fd/1 /var/log/mail.log && \
    ln -s /proc/1/fd/1 /var/log/messages

CMD ["/init.sh"]


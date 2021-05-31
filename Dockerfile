FROM alpine:3.12
MAINTAINER Joseph Lee <development@jc-lab.net>

RUN adduser -D -g vmail -u 11000 vmail && \
    mkdir -p /mail-storage && \
    chown vmail:vmail -R /mail-storage && \
    mkdir -p /secret

RUN apk add \
    bash procps mariadb-client postfix postfix-mysql postfix-pcre dovecot dovecot-sql dovecot-pop3d dovecot-mysql dovecot-lmtpd syslog-ng opendkim opendkim-utils \
    libsasl cyrus-sasl-plain cyrus-sasl-ntlm cyrus-sasl-gssapiv2 \
    inotify-tools

RUN touch /etc/postfix/sasl_passwd && postmap /etc/postfix/sasl_passwd

COPY ["template", "/template"]
COPY ["init.sh", "tls-reloader.sh", "dkim-reloader.sh", "/"]

RUN chmod +x /*.sh && \
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


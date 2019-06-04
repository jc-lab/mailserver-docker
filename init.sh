#!/bin/bash

[[ "$DB_PORT" = "" ]] && DB_PORT=3306

cat /template/main.cf > /etc/postfix/main.cf
cat /template/master.cf > /etc/postfix/master.cf
echo "myhostname = $MYHOSTNAME" >> /etc/postfix/main.cf
echo "mydomain = $MYDOMAIN" >> /etc/postfix/main.cf
echo 'myorigin = $mydomain' >> /etc/postfix/main.cf
echo "bounce_notice_recipient = $BOUNCE_NOTICE_RECIPIENT" >> /etc/postfix/main.cf
cat /template/10-master.conf > /etc/dovecot/conf.d/10-master.conf
cat /template/10-mail.conf > /etc/dovecot/conf.d/10-mail.conf
echo "postmaster_address = $POSTMASTER_ADDRESS" > /etc/dovecot/conf.d/15-lda.conf
cat /template/15-lda.conf >> /etc/dovecot/conf.d/15-lda.conf
cat /template/10-auth.conf > /etc/dovecot/conf.d/10-auth.conf
cat /template/auth-sql.conf.ext > /etc/dovecot/conf.d/auth-sql.conf.ext
cat /template/10-ssl.conf > /etc/dovecot/conf.d/10-ssl.conf
cat /template/15-mailboxes.conf > /etc/dovecot/conf.d/15-mailboxes.conf

echo "hosts = $DB_HOST:$DB_PORT" > /etc/postfix/mysql-virtual-alias-maps.cf
echo "dbname = $DB_NAME" >> /etc/postfix/mysql-virtual-alias-maps.cf
echo "user = $DB_USER" >> /etc/postfix/mysql-virtual-alias-maps.cf
echo "password = $DB_PASS" >> /etc/postfix/mysql-virtual-alias-maps.cf
echo $'query = SELECT `destination` FROM `mail_alas` `ta` INNER JOIN `mail_vdom` `td` ON `td`.`domain`=\'%d\' WHERE `ta`.`source`=\'%u\'' >> /etc/postfix/mysql-virtual-alias-maps.cf

echo "hosts = $DB_HOST:$DB_PORT" > /etc/postfix/mysql-virtual-mailbox-domains.cf
echo "dbname = $DB_NAME" >> /etc/postfix/mysql-virtual-mailbox-domains.cf
echo "user = $DB_USER" >> /etc/postfix/mysql-virtual-mailbox-domains.cf
echo "password = $DB_PASS" >> /etc/postfix/mysql-virtual-mailbox-domains.cf
echo $'query = SELECT 1 FROM `mail_vdom` WHERE `domain`=\'%s\'' >> /etc/postfix/mysql-virtual-mailbox-domains.cf

echo "hosts = $DB_HOST:$DB_PORT" > /etc/postfix/mysql-virtual-sender-maps.cf
echo "dbname = $DB_NAME" >> /etc/postfix/mysql-virtual-sender-maps.cf
echo "user = $DB_USER" >> /etc/postfix/mysql-virtual-sender-maps.cf
echo "password = $DB_PASS" >> /etc/postfix/mysql-virtual-sender-maps.cf
echo $'query = SELECT CONCAT(`ta`.`email_username`, \'@\', `td`.`domain`) FROM `mail_user` `ta` INNER JOIN `mail_vdom` `td` ON `td`.`domain`=\'%d\' WHERE `ta`.`email_username`=\'%u\'' >> /etc/postfix/mysql-virtual-sender-maps.cf

echo "hosts = $DB_HOST:$DB_PORT" > /etc/postfix/mysql-virtual-mailbox-map.cf
echo "dbname = $DB_NAME" >> /etc/postfix/mysql-virtual-mailbox-map.cf
echo "user = $DB_USER" >> /etc/postfix/mysql-virtual-mailbox-map.cf
echo "password = $DB_PASS" >> /etc/postfix/mysql-virtual-mailbox-map.cf
echo $'query = SELECT 1 FROM `mail_user` `ta` INNER JOIN `mail_vdom` `td` ON `td`.`domain`=SUBSTRING_INDEX(\'%s\', \'@\', -1) WHERE `ta`.`email_username`=SUBSTRING_INDEX(\'%s\', \'@\', 1)' >> /etc/postfix/mysql-virtual-mailbox-map.cf

echo "driver = mysql" > /etc/dovecot/dovecot-sql.conf.ext
echo "connect = host=$DB_HOST dbname=$DB_NAME user=$DB_USER password=$DB_PASS port=$DB_PORT" >> /etc/dovecot/dovecot-sql.conf.ext
echo "default_pass_scheme = PBKDF2" >> /etc/dovecot/dovecot-sql.conf.ext
echo "password_query = SELECT \`ta\`.\`email_username\` as \`username\`, \`ta\`.\`password\` as \`password\` FROM \`mail_user\` \`ta\` INNER JOIN \`mail_vdom\` \`td\` ON \`td\`.\`domain\`='%d' AND \`ta\`.\`domain_id\`=\`td\`.\`id\` WHERE \`ta\`.\`email_username\`='%n'" >> /etc/dovecot/dovecot-sql.conf.ext
echo "user_query = SELECT 'vmail' as \`gid\`, 'vmail' as \`uid\`, CONCAT('/mail-storage/', \`mailbox_id\`) as \`home\` FROM \`mail_user\` \`ta\` INNER JOIN \`mail_vdom\` \`td\` ON \`td\`.\`domain\`='%d' AND \`ta\`.\`domain_id\`=\`td\`.\`id\` WHERE \`ta\`.\`email_username\`='%n'" >> /etc/dovecot/dovecot-sql.conf.ext

chown vmail:vmail -R /mail-storage/

/usr/sbin/syslog-ng
/usr/sbin/dovecot
/usr/sbin/postfix start

while true
do
	rc_postfix=1
	rc_dovecot=1
	if [[ -f /var/spool/postfix/pid/master.pid ]]; then
		ps -p $(cat /var/spool/postfix/pid/master.pid) >/dev/null
		rc_postfix=$?
	fi
	
	if [[ -f /var/run/dovecot/master.pid ]]; then
		ps -p $(cat /var/run/dovecot/master.pid) >/dev/null
		rc_dovecot=$?
	fi
	if [[ ! $rc_postfix -eq 0 ]] || [[ ! $rc_dovecot -eq 0 ]]; then
		echo "POSTFIX CHECK RET : $rc_postfix"
		echo "DOVECOT CHECK RET : $rc_dovecot"
		exit 1
	fi
	sleep 1
done

exit 0



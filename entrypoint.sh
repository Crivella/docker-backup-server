#!/bin/bash

echo "Creating user"
groupadd -g ${BACKUP_GID} backups
useradd  -u ${BACKUP_UID} -g ${BACKUP_GID} -m -d ${BACKUP_HOME} --shell /bin/bash backups
install -d -m 0750 -o backups -g backups ${BACKUP_HOME}
chown -R backups:backups ${BACKUP_HOME}

mkdir /home
chmod 755 /home

echo "Installing templates"
PAM_ACCESS_STRING=""
for u in ${PAM_ACCESS_USERS}; do
    PAM_ACCESS_STRING+="$u "
done
for g in ${PAM_ACCESS_GROUPS}; do
    PAM_ACCESS_STRING+="($g) "
done
export PAM_ACCESS_STRING
cat /tmp/access.conf | envsubst > /etc/security/access.conf
chmod 400 /etc/security/access.conf
cat /tmp/nslcd.conf | envsubst > /etc/nslcd.conf
chmod 400 /etc/nslcd.conf

echo "Creating nsswitch.conf file"
cat >/etc/nsswitch.conf <<EOL
passwd: compat ldap
group:  compat ldap
shadow: files ldap
gshadow:        files

networks:       files

protocols:      db files
services:       db files ldap
ethers: db files
rpc:    db files

netgroup:       files ldap
sudoers:        files 
EOL

echo "Adjusting pam modules"
sed -i 's/^# account *required *pam_access.so/account required pam_access.so/g' /etc/pam.d/sshd

echo "Adjusting sshd_config"
sed -i "s:^# *AuthorizedKeysFile.*:AuthorizedKeysFile /etc/ssh/ssh_auth_keys/%u:g" /etc/ssh/sshd_config

echo "Starting services"
/etc/init.d/nslcd start
/etc/init.d/ssh start
cron -L 4

/etc/cron.daily/ldap_sync.sh

exec "$@"


#!/bin/bash

chown root:root /etc/ssh/ssh_auth_keys
chmod 755 /etc/ssh/ssh_auth_keys
for GROUP in $PAM_ACCESS_GROUPS; do
    USERS=`getent group ${GROUP} | cut -d: -f4 | tr -s ',' ' '`

    for u in $USERS; do
        DIR="${BACKUP_DIR}/$u"
        mkdir -p ${DIR}
        chown $u:${GROUP} ${DIR}
        chmod 700 ${DIR}

        DIR="/home/$u"
        mkdir -p ${DIR}
        chown $u:${GROUP} ${DIR}
        chmod 500 ${DIR}

        FILE=/etc/ssh/ssh_auth_keys/$u
        touch $FILE
        chown $u:$GROUP $FILE
        chmod 600 $FILE
    done
done

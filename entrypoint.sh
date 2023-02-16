#!/bin/bash

EXTRA_INSTALL=`echo ${EXTRA_INSTALL} | tr -s "," " "`
apt-get update && apt-get install -y --no-install-recommends ${EXTRA_INSTALL} 

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
cat /tmp/nsswitch.conf | envsubst > /etc/nsswitch.conf
chmod 400 /etc/nslcd.conf

echo "Adjusting pam modules"
sed -i 's/^# account *required *pam_access.so/account required pam_access.so/g' /etc/pam.d/sshd

echo "Adjusting sshd_config"
sed -i "s:^# *AuthorizedKeysFile.*:AuthorizedKeysFile /etc/ssh/ssh_auth_keys/%u:g" /etc/ssh/sshd_config

# This allows scripts run through cron to see the ENV variables set in the container
# https://stackoverflow.com/questions/27771781/how-can-i-access-docker-set-environment-variables-from-a-cron-job
# shoulnd only work with pam cron? https://askubuntu.com/questions/700107/why-do-variables-set-in-my-etc-environment-show-up-in-my-cron-environment/700126#700126
echo "Saving ENV variables in /etc/environment..." 
printenv > /etc/environment


echo "Make sure scripts are executables..."
find ${SCRIPT_DIR} -regex "${SCRIPT_REGEX}" -exec chmod +x {} \;
echo "Adding run_dir to cron..."
echo "${CRON_SCHEDULE} root run-parts --regex=${SCRIPT_REGEX} ${SCRIPT_DIR}" > /etc/cron.d/exporter

echo "Starting services"
/etc/init.d/nslcd start
/etc/init.d/ssh start

#This has to be run after starting ssh and nslcd in case the script depends on ahving the LDAP already available
if [[ "${RUN_SCRIPTS_ON_STARTUP,,}" == "yes" ]]; then
    echo "Running scripts on startup..."
    run-parts --test --regex=${SCRIPT_REGEX} ${SCRIPT_DIR}
    run-parts --regex=${SCRIPT_REGEX} ${SCRIPT_DIR}
fi
if [[ "${INOTIFY_ENABLE,,}" == "yes" ]]; then
    echo "Starting inotifywait daemon..."
    INOTIFY_EVENTS="`echo ${INOTIFY_EVENTS} | tr -s "," " "`"
    OPT="${INOTIFY_OPTS} "
    for e in ${INOTIFY_EVENTS}; do
        OPT+=" -e ${e^^}"
    done
    touch ${INOTIFY_LOG_FILE}
    inotifywait -m -d -o ${INOTIFY_LOG_FILE} --format "${INOTIFY_FMT}" --timefmt "${INOTIFY_TIMEFMT}" ${OPT} ${MONITOR_DIR}
fi

cron -L 4

exec "$@"


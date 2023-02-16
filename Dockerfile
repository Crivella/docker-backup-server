FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron \
        acl \
        gettext-base \
		openssh-server \
        ca-certificates \
        inotify-tools \
        libnss-ldapd \
        libpam-ldapd \
        nscd \
        nslcd \
        locales \
    && rm -rf /var/lib/apt/lists/*

RUN \
    locale-gen en_US.UTF-8 \
    && update-locale en_US.UTF-8

ENV \
    BACKUP_DIR="/backups" \
    LDAP_URI="ldaps://scoldap.epfl.ch/" \
    LDAP_BASE="O=epfl,C=ch" \
    PAM_ACCESS_USERS="" \
    PAM_ACCESS_GROUPS="" \
    SCRIPT_DIR="/scripts" \
    SCRIPT_REGEX="^.*\.sh\$" \
    RUN_SCRIPTS_ON_STARTUP="NO" \
    INOTIFY_ENABLE="YES" \
    INOTIFY_LOG_FILE="/backups/inotify.log" \
    INOTIFY_FMT="%T %e %w %f" \
    INOTIFY_TIMEFMT="%Y-%m-%d %H:%M:%S %z" \
    INOTIFY_EVENTS="CREATE" \
    INOTIFY_OPTS="-r" \
    EXTRA_INSTALL="" \
    CRON_SCHEDULE="*/15 * * * *"

EXPOSE 22

VOLUME [ "${SCRIPT_DIR}" ]
VOLUME [ "${BACKUP_DIR}" ]
VOLUME [ "/etc/ssh/ssh_auth_keys" ]


COPY templates/* /tmp/
# COPY ldap_sync.sh /etc/cron.daily
# RUN chmod +x /etc/cron.daily/ldap_sync.sh

CMD tail -f ${INOTIFY_LOG_FILE} 
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Install the entrypoint script.  It will set up ssh-related things and then run
# the CMD which, by default, starts cron.  The 'barman -q cron' job will get
# pg_receivexlog running.  Cron may also have jobs installed to run
# 'barman backup' periodically.
ENTRYPOINT ["/entrypoint.sh"]
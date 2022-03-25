FROM debian:buster

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron \
        acl \
        gettext-base \
		openssh-server \
        ca-certificates \
        libnss-ldapd \
        libpam-ldapd \
        nscd \
        nslcd \
        rsync \
        locales \
    && rm -rf /var/lib/apt/lists/*

RUN \
    locale-gen en_US.UTF-8 \
    update-locale en_US.UTF-8

ENV \
    BACKUP_UID=1002 \
    BACKUP_GID=1002 \
    BACKUP_HOME=/var/lib/backups \
    BACKUP_DIR="/backups" \
    LDAP_URI="ldaps://scoldap.epfl.ch/" \
    LDAP_BASE="O=epfl,C=ch" \
    PAM_ACCESS_USERS="" \
    PAM_ACCESS_GROUPS="" \
    SCRIPT_DIR="/scripts" \
    CRON_SCHEDULE="*/15 * * * *"

EXPOSE 22

VOLUME [ "${SCRIPT_DIR}" ]
VOLUME [ "${BACKUP_DIR}" ]
VOLUME [ "/etc/ssh/ssh_auth_keys" ]


COPY templates/* /tmp/
# COPY ldap_sync.sh /etc/cron.daily
# RUN chmod +x /etc/cron.daily/ldap_sync.sh

CMD tail -f /var/log/nslcd.log 
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Install the entrypoint script.  It will set up ssh-related things and then run
# the CMD which, by default, starts cron.  The 'barman -q cron' job will get
# pg_receivexlog running.  Cron may also have jobs installed to run
# 'barman backup' periodically.
ENTRYPOINT ["/entrypoint.sh"]
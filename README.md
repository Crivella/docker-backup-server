# docker-backup-server

This docker container will setup an SFTP backup server that allows user authentication via an LDAP server.

The idea is to use an intranet LDAP that can be queried without credentials.
Access is granted only to specific users or users belonging to a specific group.

## Instructions

### Installation

docker pull crivella1/docker-backup-server

### Build

    docker build -t crivella1/docker-backup-server .

### Run

    NOTE: Path set to `BACKUP_DIR` variable and mounted volume should match

    docker run --name backup-server -v HOST_SIDE_BACKUP_DIR:BACKUP_DIR -v HOST_SIDE_SCRIPT_DIR:/scripts -v SSH_AUTH_KEYS_DIR:/etc/ssh/ssh_auth_keys -p XXXXX:22  -h docker-backup-server

### Host key files

The location of the host key files is modified by the `entrypoint.sh` to take them from `/etc/ssh/ssh_auth_keys`.
The first time the container is ran, it will either use the host keys already present, or copy the automatically generated ones to `/etc/ssh/ssh_auth_keys`.
This is done so that when a new container is generated from the image, there will be no warning for the user of the host key being changed.

## Container ports

| Container Port | Usage |
| --- | --- |
| 22 | SSH port for scp/sftp/sshfs connections |

## Variables

| Variable | Values | Usage |
| --- | --- | --- |
| `BACKUP_DIR`| `/backups` | Location inside the container of the mounted backup volume |
| `LDAP_URI` |  | The URI of the LDAP server to connect to via nslcd  |
| `LDAP_BASE` |  | The BASE DN for the LDAP authentication |
| `PAM_ACCESS_USERS` |  | SPACE separated list of users that should be given access via PAM modules |
| `PAM_ACCESS_GROUPS` |  | SPACE separated list of groups that should be given access via PAM modules |
| `SCRIPT_DIR` | `/scripts` | Location of the mounted volume containing cron scripts to be periodically executed inside the container |
| `SCRIPT_REGEX` | `^.*\.sh\$` | Regex matching scripts inside $SCRIPT_DIR |
| `RUN_SCRIPTS_ON_STARTUP` | `NO[YES]` | Whether to execute the scripts once at container startup |
| `INOTIFY_ENABLE` | `YES[NO]` | Whether to setup an inotify daemon monitoring the backup directory |
| `INOTIFY_LOG_FILE` | `/backups/inotify.log` | Location of the log file produced by the inotify daemon |
| `INOTIFY_FMT` | `%T %e %w %` | Message format of the inotify log file |
| `INOTIFY_TIMEFMT` | `%Y-%m-%d %H:%M:%S %z` | Time format of the inotify log file |
| `INOTIFY_EVENTS` | `CREATE` | Comma separated list of inotify events to listen to |
| `INOTIFY_OPTS` | `-r` | Extra option passed to `inotifywait` (eg. can be used to pass `--fromfile XXX` to monitor only specific directories) |
| `EXTRA_INSTALL` |  | SPACE separated list of apt packages to be installed at container startup (eg if some custom scripts depends on packages that are not installed by default) |
| `CRON_SCHEDULE` | `*/15 * * * ` | The schedule with which the cron scripts will be executed |
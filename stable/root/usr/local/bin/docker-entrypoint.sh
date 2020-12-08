
#!/usr/bin/env bash
# Init script for Pritunl Docker container
SCRIPT_VERSION="1.0.2"
# Last updated date: 2020-12-08

set -Eeuo pipefail

if [ "${DEBUG}" == 'true' ];then
  set -x
fi

log() {
    echo "$(date -u +%FT$(nmeter -d0 '%3t' | head -n1)) <docker-entrypoint> $*"
}

log "INFO - Script version ${SCRIPT_VERSION}"


PRITUNL=/usr/bin/pritunl
PRITUNL_OPTS="${PRITUNL_OPTS}"
FAKE_API_CHOICE='yes'

# 用于替换官方产品购买的API接口为第三方接口
if [[ $FAKE_API_CHOICE == 'yes' ]];then
  log "##################  Now Changing API Address to yours ##############"
  export ORIG_API_SERVER='app.pritunl.com'
  export ORIG_API_SERVER_ESCAPED=$(echo "$ORIG_API_SERVER" | sed -e 's/\./\\./g')
  export ORIG_AUTH_SERVER='auth.pritunl.com'
  export ORIG_AUTH_SERVER_ESCAPED=$(echo "$ORIG_AUTH_SERVER" | sed -e 's/\./\\./g')

  export FAKE_API_SERVER='pritunl-api.simonmicro.de'
  export FAKE_API_SERVER_ESCAPED=$(echo "$FAKE_API_SERVER" | sed -e 's/\./\\./g')
  export FAKE_AUTH_SERVER="$FAKE_API_SERVER/auth/"
  export FAKE_AUTH_SERVER_ESCAPED=$(echo "$FAKE_AUTH_SERVER" | sed -e 's/\./\\./g')

  #find /usr/lib/python2.7 -type f -print0 | xargs -0 grep -o 'app.pritunl.com'
  find /usr/lib/python2.7 -type f -print0 | xargs -0 sed -i "s/$ORIG_API_SERVER_ESCAPED/$FAKE_API_SERVER_ESCAPED/g"
  #find /usr/lib/python2.7 -type f -print0 | xargs -0 grep -o 'pritunl-api.simonmicro.de'


  find /usr/share/pritunl/www/ -type f -print0 | xargs -0 sed -i "s/$ORIG_API_SERVER_ESCAPED/$FAKE_API_SERVER_ESCAPED/g"
  #find /usr/share/pritunl/www/ -type f -print0 | xargs -0 grep -o 'pritunl-api.simonmicro.de'

  find /usr/lib/python2.7 -type f -print0 | xargs -0 sed -i "s#$ORIG_AUTH_SERVER_ESCAPED#$FAKE_AUTH_SERVER_ESCAPED#g"

  find /usr/share/pritunl/www/ -type f -print0 | xargs -0 sed -i "s/$ORIG_AUTH_SERVER_ESCAPED/$FAKE_AUTH_SERVER_ESCAPED/g"
elif [[ $FAKE_API_CHOICE == 'no' ]];then
  log "##################  Skiped Chang API Address  ##############"
fi



pritunl_setup() {
    log "INFO - Insuring pritunl setup for container"

    ${PRITUNL} set-mongodb ${MONGODB_URI:-"mongodb://mongo:27017/pritunl"}

    if [ "${REVERSE_PROXY}" == 'true' ] && [ "${WIREGUARD}" == 'false' ]; then
            ${PRITUNL} set app.reverse_proxy true
            ${PRITUNL} set app.redirect_server false
            ${PRITUNL} set app.server_ssl false
            ${PRITUNL} set app.server_port 9700
    elif [ "${REVERSE_PROXY}" == 'true' ] && [ "${WIREGUARD}" == 'true' ]; then
            ${PRITUNL} set app.reverse_proxy true
            ${PRITUNL} set app.redirect_server false
            ${PRITUNL} set app.server_ssl true
            ${PRITUNL} set app.server_port 443
    else
        ${PRITUNL} set app.reverse_proxy false
        ${PRITUNL} set app.redirect_server true
        ${PRITUNL} set app.server_ssl true
        ${PRITUNL} set app.server_port 443
    fi

    PRITUNL_OPTS="start ${PRITUNL_OPTS}"
}

exit_handler() {
    log "INFO - Exit signal received, commencing shutdown"
    pkill -15 -f ${PRITUNL}
    for i in `seq 0 20`;
        do
            [ -z "$(pgrep -f ${PRITUNL})" ] && break
            # kill it with fire if it hasn't stopped itself after 20 seconds
            [ $i -gt 19 ] && pkill -9 -f ${PRITUNL} || true
            sleep 1
    done
    log "INFO - Shutdown complete. Nothing more to see here. Have a nice day!"
    log "INFO - Exit with status code ${?}"
    exit ${?};
}

# Wait indefinitely on tail until killed
idle_handler() {
    while true
    do
        tail -f /dev/null & wait ${!}
    done
}

trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

if [[ "${@}" == 'pritunl' ]];
    then
        pritunl_setup

        log "EXEC - ${PRITUNL} ${PRITUNL_OPTS}"
        exec 0<&-
        exec ${PRITUNL} ${PRITUNL_OPTS} &
        idle_handler
    else
        log "EXEC - ${@}"
        exec "${@}"
fi

# Script should never make it here, but just in case exit with a generic error code if it does
exit 1;

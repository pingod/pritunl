#!/usr/bin/env bash

# Init script for Pritunl Docker container
# License: Apache-2.0
# Github: https://github.com/goofball222/pritunl.git
SCRIPT_VERSION="1.0.1"
# Last updated date: 2018-08-22

set -Eeuo pipefail
DEBUG=true
if [ "${DEBUG}" == 'true' ];
    then
        set -x
fi

log() {
    echo "$(date -u +%FT$(nmeter -d0 '%3t' | head -n1)) <docker-entrypoint> $*"
}

log "INFO - Script version ${SCRIPT_VERSION}"

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
  find /usr/lib/python2.7 -type f -print0 | xargs -0 sed -i "s#$ORIG_API_SERVER_ESCAPED#$FAKE_API_SERVER_ESCAPED#g"
  #find /usr/lib/python2.7 -type f -print0 | xargs -0 grep -o 'pritunl-api.simonmicro.de'


  find /usr/share/pritunl/www/ -type f -print0 | xargs -0 sed -i "s#$ORIG_API_SERVER_ESCAPED#$FAKE_API_SERVER_ESCAPED#g"
  #find /usr/share/pritunl/www/ -type f -print0 | xargs -0 grep -o 'pritunl-api.simonmicro.de'

  find /usr/lib/python2.7 -type f -print0 | xargs -0 sed -i "s#$ORIG_AUTH_SERVER_ESCAPED#$FAKE_AUTH_SERVER_ESCAPED#g"

  find /usr/share/pritunl/www/ -type f -print0 | xargs -0 sed -i "s#$ORIG_AUTH_SERVER_ESCAPED#$FAKE_AUTH_SERVER_ESCAPED#g"
elif [[ $FAKE_API_CHOICE == 'no' ]];then
  log "##################  Skiped Chang API Address  ##############"
fi

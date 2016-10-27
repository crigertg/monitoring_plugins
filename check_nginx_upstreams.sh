#!/usr/bin/env bash
# check the status page of yaobeiwin's nginx_upstream_health_module (https://github.com/yaoweibin/nginx_upstream_check_module)
# returns CRITICAL if at least one server of an upstream is down
# Author: gricertg
# License: The MIT License (MIT)

PATH="/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin"
LIBEXEC="/usr/lib/nagios/plugins"
. $LIBEXEC/utils.sh

print_help() {
  echo "check the status page of yaobeiwin's nginx_upstream_health_module"
  echo "returns CRITICAL if at least one server of an upstream is down"
  echo "parameters:"
  echo "-h            print help"
  echo "-H [HOSTNAME] specify the hostname to send the request to. DEFAULT: localhost"
  echo "-P [PORT]     specify the port for the request, DEFAULT: 80 or 443"
  echo "-u [PATH]     path to the nginx_upstream_health_module status page. DEFAULT: '/upstream_status"
  echo "-S            enable SSL for the check"
  echo "-a [USER:PW]  credentials for basic auth/htpasswd"
}

# default values
HOSTNAME='localhost'
PORT=''
SCHEME='http://'
STATUSPAGE='/upstream_status'

while getopts 'hH:P:p:w:c:a:S' OPT; do
  case $OPT in
    h) print_help; exit $STATE_WARNING;;
    H) HOSTNAME=$OPTARG;;
    P) PORT=":${OPTARG}";;
    p) STATUSPAGE=$OPTARG;;
    S) SCHEME='https://';;
    a) CREDENTIALS="-u ${OPTARG}";;
    *) print_help; exit $STATE_WARNING;;
  esac
done

# check if important parameters are valid
[[ ! $(which curl) ]] && echo "curl command not found" && exit $STATE_WARNING

CURL="$(which curl) -s ${CREDENTIALS} ${SCHEME}${HOSTNAME}${PORT}${STATUSPAGE}?format=csv&status=down"

# check response code
RETURNCODE=$($CURL -I | head -n 1 | cut -d ' ' -f 2)
if ! [ $RETURNCODE -eq 200 ]; then
  echo "Request to ${SCHEME}${HOSTNAME}${PORT}${STATUSPAGE}?format=csv&status=down returned ${RETURNCODE}"
  exit $STATE_CRITICAL
fi

# check if there are any DOWN upstream servers
RESPONSE=$($CURL)
[ -z "${RESPONSE}" ] && echo 'OK - All upstream servers online' && exit $STATE_OK

# get names of down servers
SERVERS=$(echo $RESPONSE | tr ' ' '\n' | cut -d ',' -f 3)

# get corresponding upstream of down servers and create response messages
MESSAGE="CRITICAL -"
for server in $(echo $SERVERS); do
  UPSTREAM=$(echo $RESPONSE | tr ' ' '\n' | grep $server | cut -d ',' -f 2)
  MESSAGE+=" Server ${server} of upstream ${UPSTREAM} marked down."
done

echo $MESSAGE
exit $STATE_CRITICAL


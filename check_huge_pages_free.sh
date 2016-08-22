#!/usr/bin/env bash
# check if the configured percentage of huge pages is free
# Author: gricertg
# License: The MIT License (MIT)

PATH="/usr/bin:/usr/sbin:/bin:/sbin"
LIBEXEC="/usr/lib/nagios/plugins"
. $LIBEXEC/utils.sh

print_help() {
  echo 'check if the configured percentage of huge pages is free'
  echo 'PARAMETER  DESCRIPTION'
  echo '-w         WARNING percentage value for free memory'
  echo '-c         CRITICAL percentage value for free memory'
}

while getopts 'w:c:h--help' OPT; do
  case $OPT in
    w) WARNING=$OPTARG;;
    c) CRITICAL=$OPTARG;;
    h) print_help; exit $STATE_OK;;
    --help) print_help; exit $STATE_OK;;
    *) print_help; exit $STATE_WARNING;;
  esac
done

[ $# -gt 0 ] || { print_help; exit $STATE_WARNING; }
[ "${WARNING}" ] || { echo "You must define a Warning value"; exit $STATE_WARNING; }
[ "${CRITICAL}" ] || { echo "You must define a Critical value"; exit $STATE_WARNING; }
[ "${WARNING}" -lt 99 ] || { echo "Warning can't be greater than 99%"; exit $STATE_WARNING; }
[ "${CRITICAL}" -lt 99 ] || { echo "Critical can't be greater than 99%"; exit $STATE_WARNING; }
[ "${WARNING}" -gt "${CRITICAL}" ] || { echo "Warning can't be smaller than Critical"; exit $STATE_WARNING; }

TOTAL=$(grep HugePages_Total /proc/meminfo | awk '{print $2}')
FREE=$(grep HugePages_Free /proc/meminfo | awk '{print $2}')

PERCENT=$(echo "scale=2; ${FREE}/${TOTAL}*100" | bc)
PERCENT=${PERCENT%.*}

if [ "${PERCENT}" -lt "${CRITICAL}" ]; then
  echo "CRITICAL - ${PERCENT}% Huge_Pages free | free=${PERCENT}%;${WARNING};${CRITICAL}"
  exit $STATE_CRITICAL
elif [ "${PERCENT}" -lt "${WARNING}" ]; then
  echo "WARNING - ${PERCENT}% Huge_Pages free | free=${PERCENT}%;${WARNING};${CRITICAL}"
  exit $STATE_WARNING
else
  echo "OK - ${PERCENT}% Huge_Pages free | free=${PERCENT}%;${WARNING};${CRITICAL}"
  exit $STATE_OK
fi

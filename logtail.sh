#!/bin/bash

_logtail-debug() {
  printf "[DEBUG] %s::%d: \"%s\"\n" "$0" "$1" "$2"
}

_logtail() {
  logDir="/var/log"
  declare -a include=("*log" "debug" "dmesg" "messages")

  declare -a generated
  for ((i=0; $i<${#include}; ++i)); do
    generated+=(${logDir}/${include[$i]})
  done

  _logtail-debug $LINENO generated[@]="`echo ${generated[@]}`"

  unset logDir include

  declare -a filtered
  for ((i=0; $i<${#generated}; ++i)); do
    file "${generated[$i]}" | grep text 1>&2 > /dev/null
    [ $? -eq 0 ] && filtered+=("${generated[$i]}")
  done

  _logtail-debug $LINENO filtered[@]="`echo ${filtered[@]}`"

  unset generated

  tail -f ${filtered[@]}

  unset filtered
}

echo 0=\"$0\" 1=\"$1\" 2=\"$2\" @=\"$@\"

if [[ "$0" =~ .*logtail.sh ]]; then
  echo "GO"
  _logtail $@
else
  echo "SET ALIAS"
  alias logtail="_logtail "
fi


#!/bin/bash

### ###########################################################################
### CONFIG -- USER SETABLE

# Directory that will be prepended to values in include
logDir="/var/log"

# globs/Files that will be simultaneously tailed
declare -a include=("*log" "debug" "dmesg" "messages")

#################################################################### END CONFIG


### ###########################################################################
### DECLARATIONS

black='\E[30m'; red='\E[31m'; green='\E[32m'; yellow='\E[33m';
blue='\E[34m'; magenta='\E[35m'; cyan='\E[36m'; white='\E[37m';
resetColor="tput sgr0"

# 0 = ON
debugSwitch=0

_logtail-debug() {
  [ $debugSwitch -eq 0 ] || return

  printf "${yellow}[DEBUG]${green} %s:%s:%d: " "$0" "$BASH_SOURCE" "$1"
  $resetColor
  printf "\'%s\'\n" "$2"
}

_logtail() {
  # Build array of literal paths to all files under logDir we want to watch
  # Glob expansion happens here
  declare -a generated
  for ((i=0; $i<${#include}; ++i)); do
    generated+=(${logDir}/${include[$i]})
  done
  _logtail-debug $LINENO generated[@]="`echo ${generated[@]}`"

  unset logDir include

  # Check that each element of the array is a text type file,
  #> drop files that are empty or not text
  declare -a filtered
  for ((i=0; $i<${#generated}; ++i)); do
    file "${generated[$i]}" | grep text 1>&2 > /dev/null
    [ $? -eq 0 ] && filtered+=("${generated[$i]}")
  done
  _logtail-debug $LINENO filtered[@]="`echo ${filtered[@]}`"

  unset generated

  # Watch the list of files that passed tests
  tail -f ${filtered[@]}

unset filtered
}

############################################################## END DECLARATIONS


### ###########################################################################
### MAIN

debugSwitch=1

_logtail-debug $LINENO "0=\"$0\" 1=\"$1\" 2=\"$2\" @=\"$@\""

if [[ "$0" =~ .*logtail.sh ]]; then
  _logtail-debug $LINENO "Regex matched, executing..."
  _logtail $@ # WTF, I don't accept any arguments :P
else
  _logtail-debug $LINENO "It seems we are being sourced, declaring alias..."
  alias logtail='_logtail '
fi

###################################################################### END MAIN

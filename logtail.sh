#!/bin/bash

### ###########################################################################
### CONFIG -- USER SETABLE

_logtail-config() {
  # Directory that will be prepended to values in _logtail_include
  _logtail_logDir="/var/log"

  # globs/Files that will be simultaneously tailed
  # This is a space deliminated string that will be converted into an array.
  _logtail_include="*log debug dmesg messages"

  _logtail_black='\E[30m'; _logtail_red='\E[31m'; _logtail_green='\E[32m';
  _logtail_yellow='\E[33m'; _logtail_blue='\E[34m'; _logtail_magenta='\E[35m';
  _logtail_cyan='\E[36m'; _logtail_white='\E[37m'; _logtail_resetColor="tput sgr0"

  _logtail-debug $LINENO logDir="`echo ${_logtail_logDir}`"
  _logtail-debug $LINENO include="`echo ${_logtail_include}`"

  export _logtail_logDir _logtail_include
  export _logtail_black _logtail_red _logtail_green
  export _logtail_yellow _logtail_blue _logtail_magenta
  export _logtail_cyan _logtail_white _logtail_resetColor
}

#################################################################### END CONFIG


### ###########################################################################
### DECLARATIONS

_logtail-debug() {
  [ $debugSwitch -eq 0 ] || return

  printf "${_logtail_yellow}[DEBUG]${_logtail_green} %s:%s:%d: " "$0" "$BASH_SOURCE" "$1"
  $_logtail_resetColor
  printf "\'%s\'\n" "$2"
}

_logtail() {
  _logtail-config
  _logtail-debug $LINENO logDir="`echo ${_logtail_logDir}`"
  _logtail-debug $LINENO include="`echo ${_logtail_include}`"
  
  # Convert _logtail_include string to array
  include_arr=(`echo ${_logtail_include}`)
  _logtail-debug $LINENO include_arr[@]="`echo ${include_arr[@]}`"
  
  # Build array of literal paths to all files under _logtail_logDir we want to watch
  # Glob expansion happens here
  declare -a generated
  for ((i=0; $i<${#include_arr[@]}; ++i)); do
    generated+=(${_logtail_logDir}/${include_arr[$i]})
  done
  _logtail-debug $LINENO generated[@]="`echo ${generated[@]}`"

  # Check that each element of the array is a text type file,
  #> drop files that are empty or not text
  declare -a filtered
  for ((i=0; $i<${#generated[@]}; ++i)); do
    _logtail-debug $LINENO "i=${i} / #generated=${#generated[@]}"
    _logtail-debug $LINENO "file ${generated[$i]}=`file ${generated[$i]}`"
    file "${generated[$i]}" | grep text 1>&2 > /dev/null
    [ $? -eq 0 ] && filtered+=("${generated[$i]}")
  done
  _logtail-debug $LINENO filtered[@]="`echo ${filtered[@]}`"

  # Watch the list of files that passed tests
  tail -f ${filtered[@]}

  unset _logtail_logDir _logtail_include
  unset _logtail_black _logtail_red _logtail_green
  unset _logtail_yellow _logtail_blue _logtail_magenta
  unset _logtail_cyan _logtail_white _logtail_resetColor
  unset include_arr generated filtered
}

############################################################## END DECLARATIONS


### ###########################################################################
### MAIN

# debugSwitch 0 == ON; 1 == OFF
debugSwitch=0

_logtail-debug $LINENO "0=\"$0\" 1=\"$1\" 2=\"$2\" @=\"$@\""

if [[ "$0" =~ .*logtail.sh ]]; then
  _logtail-debug $LINENO "Regex matched, executing..."
  _logtail $@ # WTF, I don't accept any arguments :P
else
  _logtail-debug $LINENO "It seems we are being sourced, declaring alias..."
  alias logtail='_logtail '
fi

###################################################################### END MAIN

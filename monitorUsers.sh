#!/bin/bash
function getUsers {
  local OUT=
  for i in $(users); do
    if [[ "$OUT" == *"$i"* ]]; then
      continue;
    else
      OUT+="$i "
    fi
  done
  echo $OUT;
}

function printUserProcesses {
  until [ -z "$1" ]
  do
    echo "---------------- $1 ----------------"
    echo "--------------------------------------------"
    ps w -c -H r -U "$1"
    echo "--------------------------------------------"
    shift
  done  
}

while [ "1" = "1" ]; do
  printUserProcesses $(getUsers)
  echo Active Users on $HOSTNAME at $(date +%d/%m' '%H%M)
  getUsers
  if [ -z "$1" ]; then
    sleep 600  # 5 minutes
  else
    sleep $(expr 60 \* "$1")
  fi
done

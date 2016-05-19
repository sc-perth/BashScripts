#!/bin/bash

result=0
while [ $result -eq 0 ]; do
	sleep $((5 * 60))
	ping -c 4 camelot.semicosmic.net 2>&1 >/dev/null
	result=$?
done

printf "Camelot unresponsive at %s.\n" "$(date)" >> /home/perth/garbage/camelot_result

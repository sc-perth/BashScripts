#!/bin/bash
echo Ping Check! Self, Router, Google IP, Google FQDN

false
while [ $? -ne 0 ]; do
	ping -c 4 192.168.1.127
done
echo -e "\n\n"

false
while [ $? -ne 0 ]; do
	ping -c 4 192.168.1.1
done
echo -e "\n\n"

false
while [ $? -ne 0 ]; do
	ping -c 4 8.8.8.8
done
echo -e "\n\n"

false
while [ $? -ne 0 ]; do
	ping -c 4 google.com
done

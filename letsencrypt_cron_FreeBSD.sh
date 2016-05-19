#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin


logfile="/var/log/letsencrypt/renew.log"
grepstr="not due for renewal"
serviceArgs="postfix reload,dovecot reload"
result=0


# Attempt to renew all issued certificates. Overwrite $logfile (resetting it) w/ output
if ! letsencrypt renew > $logfile 2>&1 ; then
    echo >> $logfile
    echo "Automated renewal failure detected." >> $logfile
    result=1
fi
echo >> $logfile


# Check if letsencrypt exited successfully, but did not renew certs.
if grep -io "$grepstr" $logfile > /dev/null 2>&1 ; then
    echo "Certs did not need renewed." >> $logfile
    exit 0
fi


# If certs were renewed, execute service $services_nth $command_nth
if [ $result -lt 1 ] ; then
    OLDIFS="$IFS"; IFS=','

    for arg in $serviceArgs ; do
        IFS=' '
        service $arg
        if [ $? -eq 0 ] ; then
            echo "$arg successful" >> $logfile
        else
            echo "$arg FAILED" >> $logfile
            result=-1
        fi
    done

    IFS="$OLDIFS"
fi


if [ $result -ne 0 ] ; then
    echo "PROBLEMS ENCOUNTERED!" >> $logfile
    /root/Scripts/cron_sendmail.sh -f root -t perth -s "LetsEncrypt Renew Failure" -i "$logfile"
    exit 1
fi


echo "Update succeeded"
/root/Scripts/cron_sendmail.sh -f root -t perth -s "LetsEncrypt Renew Success" -i "$logfile"
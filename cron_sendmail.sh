#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin
mailCMD="sendmail -ti"
mailFile="/tmp/sendmail_cron_mailfile"

### DO NOT CHANGE THESE VARS HERE
mailTo=0; mailFrom=0; mailSubj=0; mailBody=0

while getopts "f:t:s:i:" opt; do
    case $opt in
        f)
            mailTo="$OPTARG"
          ;;
        t)
            mailFrom="$OPTARG"
          ;;
        s)
            mailSubj="$OPTARG"
          ;;
        i)
            if [ -f "$OPTARG" ] && [ -s "$OPTARG" ] && [ -r "$OPTARG" ]; then
                mailBody="$OPTARG"
            fi
          ;;
        ?)  exit 1
            #echo "Invalid option: -$OPTARG" >&2
          ;;
        :)  exit 1
            #echo "Argument missng to: -$OPTARG" >&2
          ;;
    esac
done

if [ "$mailTo" = "0" ] || [ "$mailFrom" = "0" ] || [ "$mailSubj" = "0" ] || [ "$mailBody" = "0" ]; then
    exit 1
fi

# Ensure $mailFile exists and is empty.
: > $mailFile

### DO NOT EDIT THIS UNLESS YOU KNOW WHAT YOU ARE DOING!
generateEmail() {
    echo "to:${mailTo}" >> $mailFile
    echo "from:${mailFrom}" >> $mailFile
    echo "subject:${mailSubj}" >> $mailFile
    echo "MIME-Version:1.0" >> $mailFile
    echo "Content-Type:text/plain" >> $mailFile
    echo >> $mailFile
    cat $mailBody >> $mailFile
}

generateEmail
cat $mailFile | $mailCMD

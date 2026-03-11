#!/bin/sh

echo "$MODDIR"

key_click() {
    kc=""
    while [ "$kc" = "" ]; do
        kc="$(getevent -qlc 1 | awk '{ print $3 }' | grep 'KEY_')"
        sleep 0.2
    done
}

DLBSERV=$(find /*/bin/hw -type f -name "*vendor.dolby*dms*service")
DAX_FILE="/vendor/etc/dolby/dax-default.xml"
LAST_MOD_TIME=$(stat -c %Y "$DAX_FILE")

echo "start listen"
while true; do
    sleep 1
    CURRENT_MOD_TIME=$(stat -c %Y "$DAX_FILE")

    if [ "$CURRENT_MOD_TIME" -ne "$LAST_MOD_TIME" ]; then
        LAST_MOD_TIME="$CURRENT_MOD_TIME"

        if [ ! -z "$DLBSERV" ]; then
            for serv in ${DLBSERV}; do
                echo " "
                echo " -- restarting service: "
                echo " $serv "
                su -c setprop sys.audio.restart.hal 1
                sleep 1
                su -c killall "$serv"
                sleep 1
                su -c "$serv" &
            done
        else
            su -c setprop sys.audio.restart.hal 1
        fi

        echo " "
        echo " -- DONE! -- "
    fi
done
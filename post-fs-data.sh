MODPATH=${0%/*}

# MODPATH=/data/adb/modules/Mi17Audio

for i in `/bin/find $MODPATH/odm -type f -printf "%P "`; do
    /bin/mount /$MODPATH/odm/$i /odm/$i
    restorecon /odm/$i
done

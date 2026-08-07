SKIPUNZIP=0

KEY_LISTENER_PID=""
KEY_FIFO=""

start_key_listener() {
    if [ -n "$KEY_LISTENER_PID" ] && kill -0 "$KEY_LISTENER_PID" 2>/dev/null; then
        return
    fi
    KEY_FIFO=$(mktemp -u -p /dev/tmp)
    mkfifo "$KEY_FIFO" || exit 1
    getevent -ql > "$KEY_FIFO" &
    KEY_LISTENER_PID=$!
}

stop_key_listener() {
    if [ -n "$KEY_LISTENER_PID" ]; then
        kill "$KEY_LISTENER_PID" >/dev/null 2>&1
        KEY_LISTENER_PID=""
    fi
    if [ -n "$KEY_FIFO" ]; then
        rm -f "$KEY_FIFO"
        KEY_FIFO=""
    fi
}

volume_key_detection() {
    local timeout_seconds="${1:-0}"
    local detection_result_file=$(mktemp -u -p /dev/tmp)

    (
        while read -r line; do
            if echo "$line" | grep -Eiq "(KEY_)?VOLUME ?UP|KEYCODE_VOLUME_UP" && echo "$line" | grep -Eiq "DOWN|PRESS"; then
                echo "0" > "$detection_result_file"
                exit 0
            elif echo "$line" | grep -Eiq "(KEY_)?VOLUME ?DOWN|KEYCODE_VOLUME_DOWN" && echo "$line" | grep -Eiq "DOWN|PRESS"; then
                echo "1" > "$detection_result_file"
                exit 0
            fi
        done < "$KEY_FIFO"
    ) &
    local detection_pid=$!

    if [ "$timeout_seconds" -gt 0 ]; then
        (
            sleep "$timeout_seconds"
            if kill -0 "$detection_pid" 2>/dev/null; then
                kill "$detection_pid" 2>/dev/null
                echo "2" > "$detection_result_file"
            fi
        ) &
        local timeout_pid=$!

        wait "$detection_pid" 2>/dev/null
        kill "$timeout_pid" 2>/dev/null
        wait "$timeout_pid" 2>/dev/null
    else
        wait "$detection_pid" 2>/dev/null
    fi

    if [ -f "$detection_result_file" ]; then
        local result=$(cat "$detection_result_file")
        rm -f "$detection_result_file"
        return "$result"
    fi

    rm -f "$detection_result_file"
    return 2
}

handle_choice() {
    local question="$1"
    local choice_yes="${2:-是}"
    local choice_no="${3:-否}"
    local timeout_seconds="${4:-10}"

    ui_print " "
    ui_print "--------------------------------------------------"
    ui_print "- ${question}"
    ui_print "- [ 音量加(+) ]: ${choice_yes}"
    ui_print "- [ 音量减(-) ]: ${choice_no}"
    ui_print "- [ ${timeout_seconds} 秒内未选择将默认选择: ${choice_yes} ]"

    timeout 0.1 getevent -c 1 >/dev/null 2>&1

    start_key_listener
    volume_key_detection "$timeout_seconds"
    local result=$?
    stop_key_listener

    if [ "$result" -eq 0 ]; then
        ui_print "  => 您选择: ${choice_yes}"
        return 0
    elif [ "$result" -eq 1 ]; then
        ui_print "  => 您选择: ${choice_no}"
        return 1
    else
        ui_print "  => 超时未选择，默认选择: ${choice_yes}"
        return 0
    fi
}

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
  set_perm_recursive $MODPATH/odm/etc 0 0 0755 0644
  set_perm_recursive $MODPATH/system/vendor/etc 0 0 0755 0644 u:object_r:vendor_configs_file:s0
}

replace_targets() {
  for path in $1; do
    for file in $2; do
      if [ -f "/$path/$file" ]; then
        mkdir -p "$MODPATH/$path"
        touch "$MODPATH/$path/$file"
        ui_print "- Replacing: /$path/$file"
      fi
    done
  done
}

remove_files() {
  replace_targets \
    "system/lib64 system/system_ext/lib64 system/vendor/lib64 odm/vendor/lib64" \
    "libaudioclientimpl.so libaudioflingerimpl.so libaudiopolicyserviceimpl.so libmiaudiopolicymanager.so"

  replace_targets \
    "system/etc/audio system/system_ext/etc/audio system/vendor/etc/audio odm/etc/audio" \
    "audio_lowpower_app_list.xml"
}

remove_files
set_permissions
# ui_print "- config.toml is located in /data/adb/modules/Mi17Audio/"
ui_print "- config.toml 位于 /data/adb/modules/Mi17Audio/"

handle_choice \
    "超低延时通路是否绕过 DSP, 延时最低但听感较差" \
    "否" \
    "是" \
    "10"
choice=$?
if [ "$choice" -eq 0 ]; then
    sed -i '/<!-- FLAG:ULL START -->/,/<!-- FLAG:ULL END -->/d' \
        "$MODPATH/odm/etc/audio/sku_canoe/resourcemanager_canoe_mtp.xml"
# elif [ "$choice" -eq 1 ]; then
#     ui_print "bypass cirrus dsp in ultra low latency"
fi

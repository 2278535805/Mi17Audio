#!/bin/sh

boost() {
    pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/top-app/cgroup.procs
    chrt -p $pid -f 10
    done
}

boost_tid() {
    pgrep -f "$1" | while read pid; do
        [ -d "/proc/$pid" ] || continue
        grep -lE "$2" /proc/$pid/task/*/comm 2>/dev/null | cut -d/ -f5 | while read tid; do
            echo $tid > /dev/cpuset/top-app/tasks
            chrt -p $tid -f 10
        done
    done
}

is_low_latency_audio() {
    dumpsys media.audio_flinger 2>/dev/null | awk '
        BEGIN { found = 0 }

        # 遇到历史日志退出
        /^Historical Thread Log/ {
            if (found) exit 0; else exit 1
        }

        /^Output thread/ {
            if (found) exit 0
            type = 0; standby = 0; found = 0
            if ($0 ~ /type 0 \(/) type = 0
            else if ($0 ~ /type 5 \(/) type = 5
        }

        /Standby: yes/ { standby = 1 }
        /Standby: no/  { standby = 0 }

        # type 0: 看 FastMixer 的 activeMask
        type == 0 && /activeMask=0x/ {
            if (standby == 0) {
                split($0, a, "=")
                mask = a[2]
                gsub(/ /, "", mask)
                if (mask != "0x0" && mask != "0x00") found = 1
            }
        }

        # type 5: 看 Tracks 数量
        type == 5 && /^[ \t]*[0-9]+ Tracks/ {
            if (standby == 0) {
                tracks = $1
                gsub(/ /, "", tracks)
                if (tracks + 0 > 0) found = 1
            }
        }

        END { if (found) exit 0; else exit 1 }
    '
}
prev_foreground=""

while true; do
    foreground=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -o '[^/{ ]*/' | head -1 | tr -d '/')

    if [ "$foreground" != "$prev_foreground" ] && [ -n "$foreground" ]; then
        prev_foreground="$foreground"
        sleep 5
        foreground=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -o '[^/{ ]*/' | head -1 | tr -d '/')
        if is_low_latency_audio && [ "$foreground" = "$prev_foreground" ]; then
            echo "Low latency audio is active, boost audio"
            boost_tid "audioserver" "FastMixer|Audio.*Out_.*|AAudio_.*|binder:.*"
            boost_tid "audiohalservice.qti" "low_latency_out|raw_out_.*|mmap_no_irq_out"
            boost_tid "$foreground" "AudioTrack|AAudio_.*|FMOD mixer.*"
        fi
    fi

    sleep 5

    while [ "$(dumpsys deviceidle get screen)" = "false" ]; do
        sleep 5
    done
done

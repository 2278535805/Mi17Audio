#!/bin/sh

boost() {
    pgrep -f $1 | while read pid; do
    echo $pid > /dev/cpuset/top-app/cgroup.procs
    chrt -p $pid -f 5
    done
}

boost_tid() {
    pgrep -f "$1" | while read pid; do
        if [ ! -d "/proc/$pid" ]; then
            continue
        fi
        
        # ps -T -p <PID>
        for tid in $(ls /proc/$pid/task/); do
            comm=$(cat /proc/$pid/task/$tid/comm 2>/dev/null)
            if echo "$comm" | grep -qE "$2"; then
                echo $tid > /dev/cpuset/top-app/tasks
                chrt -p $tid -f 5
            fi
        done
    done
}

while true; do
    boost_tid "audioserver" "FastMixer|AudioOut_.*|AAudio_.*"
    boost_tid "audiohalservice.qti" "low_latency_out|raw_out_.*|mmap_no_irq_out|writer"

    foreground=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity | grep -o '[^/{ ]*/' | head -1 | tr -d '/')
    [ -n "$foreground" ] && boost_tid "$foreground" "AudioTrack|AAudio_.*|FMOD mixer.*"

    sleep 1

    screen=`dumpsys deviceidle get screen`
    while test "$screen" = "false" ; do
        sleep 5
        screen=`dumpsys deviceidle get screen`
    done

done

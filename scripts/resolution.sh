#!/bin/bash

set_resolution(){
        xrandr --newmode ${MODELINE} 2> /dev/null
        xrandr --addmode ${MONITOR} ${MODE} 2> /dev/null
        xrandr --output ${MONITOR} --mode ${MODE}
}

re='^[0-9]+$'
if [[ ! $1 =~ $re || ! $2 =~ $re || $3 =~ $re || $1 == "--help" || $1 == "-help" || $1 == "-h" ]]; then
        echo "Usage: resolution.sh <Width> <Height> [<Monitor Name>]"
else
        MODELINE=$(cvt $1 $2 |tail -1|sed "s/Modeline //")
        MODE=$(echo $MODELINE | awk '{print$1}')
        if [[ $# == 2 ]]; then
                echo "Please select your monitor:"
                select MONITOR in $(xrandr | grep -E 'connected' | awk '{print$1"............"$2}')
                do
                        MONITOR=$(echo $MONITOR | cut -d '.' -f 1)
                        set_resolution
                        exit 0
                done
        elif [[ $# == 3 ]]; then
                MONITOR=$3
                set_resolution
        fi
fi

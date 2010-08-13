#!/bin/bash
# This is script for opening and closing the port to
# the tatget host for a specified time, or without it.
# Anton Ukolov, 2010

usage() {
    echo "Script for opening and closing port to the target host"
    echo "open - open the port"
    echo "close - close the port"
    echo "or"
    echo "$0 open|close [--host (ip_addr/net)] [-m] [--port port_num] [--proto tcp|udp|icmp] [--sleep minutes]"
    echo "proto tcp is default"
    exit 1
}

check_param() {
    BASE=`echo $PARAM | sed s/\-\-//`
    RES=`echo $STR | grep "\-\-$BASE"`
    if [[ "$RES" ]]; then
        echo "duplicated param: $PARAM"
        echo
        usage
    fi
}

do_act() {
    case "$ACT" in
        open)
            iptables -A FORWARD $MULTI -s $HOST -p $PROTO --dport $PORT -j ACCEPT
            iptables -A FORWARD $MULTI -d $HOST -p $PROTO --sport $PORT -m state --state ESTABLISHED -j ACCEPT
            ;;
        close)
            iptables -D FORWARD $MULTI -s $HOST -p $PROTO --dport $PORT -j ACCEPT
            iptables -D FORWARD $MULTI -d $HOST -p $PROTO --sport $PORT -m state --state ESTABLISHED -j ACCEPT
            ;;
        *)
            echo "wrong action, it may be open or close"
            echo
            usage
            ;;
    esac
}

do_sleep() {
    sleep $SLEEP
    ACT="close"
    do_act
#   echo "ports are closed!"
}

HOST="192.168.125.1"
PORT="80"
PROTO="tcp"
SLEEP=""
MULTI=""

ACT="$1"
shift
if [[ $1 -eq '-m' ]]
then
    MULTI="-m multiport"
    shift
fi

RES=$(($#%2))
if [[ $RES -eq 0 ]]; then
    while [ $# -gt 0 ] 
    do
        case $1 in 
            --host) 
                PARAM="$1"; shift
                STR="$*"; HOST="$1"
                check_param; shift
                ;;
            --port) 
                PARAM="$1"; shift
                STR="$*"; PORT="$1"
                check_param; shift
                ;;
            --proto)
                PARAM="$1"; shift
                STR="$*"; PROTO="$1"
                check_param; shift
                ;;
            --sleep)
                PARAM="$1"; shift
                STR="$*"; SLEEP=$(($1*60))
                check_param; shift
                ;;
            *) 
                echo "wrong param: $1"
                echo
                usage
                ;;
        esac
    done
else
    echo "wrong number of params"
    echo
    usage
fi

do_act
if [[ "$ACT" = "open" && $SLEEP ]]; then
    do_sleep &
fi


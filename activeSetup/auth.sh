#!/bin/bash

METHOD="$1"
MAC="$2"

case "$METHOD" in
    auth_client)
        USERNAME="$3"
        PASSWORD="$4"
        if [[ -z "$USERNAME" ]] || [[ -z "$PASSWORD" ]];
        then
            exit 1
        fi
        printf "[%s] %s:%s\n" "$(date +'%F %T')" "$USERNAME" "$PASSWORD" >> /tmp/captivePortlalLog.txt
        echo 7200 0 0
        exit 0
    ;;
    client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
        INGOING_BYTES="$3"
        OUTGOING_BYTES="$4"
        SESSION_START="$5"
        SESSION_END="$6"
    ;;
esac

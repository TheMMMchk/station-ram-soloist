#!/bin/sh

while :; do
    sleep 120
    [ -d /tmp/soloist/cache ] || exit 0
    KB=$(du -sk /tmp/soloist/cache 2>/dev/null | awk '{print $1}')
    [ "${KB:-0}" -gt 10240 ] && rm -rf /tmp/soloist/cache/*
done
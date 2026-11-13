#!/bin/sh

while :; do
    sleep 120
    [ -d /tmp/soloist/cache ] || exit 0
    [ "${KB:-0}" -gt 20480 ] && rm -rf /tmp/soloist/cache/*
done
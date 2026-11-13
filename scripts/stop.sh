#!/bin/sh
set -eu

RAM="/tmp/soloist"

for pid in $(ps | grep '[r]amsoloist/start\.sh' | awk '{print $1}'); do
    [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null || true
done
for pid in $(ps | grep '[r]amsoloist/cacheguard\.sh' | awk '{print $1}'); do
    [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null || true
done

killall ld-linux-aarch64.so.1 2>/dev/null || true

i=0
while [ "$i" -lt 5 ] && pidof ld-linux-aarch64.so.1 >/dev/null 2>&1; do
    sleep 1; i=$((i + 1))
done

killall -9 ld-linux-aarch64.so.1 2>/dev/null || true

rm -rf "$RAM"

pidof ld-linux-aarch64.so.1 && echo "WARN: Soloist всё ещё жив" >&2
echo "INFO: Soloist stopped. RAM cleared."
#!/bin/sh
set -eu

RAM="/tmp/soloist"

killall soloist 2>/dev/null || true

sleep 1
rm -rf "$RAM"

echo "INFO: Soloist stopped. RAM cleared."
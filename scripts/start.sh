#!/bin/sh
set -eu

ROOT="/data/opt/ramsoloist"
CONFIG="$ROOT/config"
RAM="/tmp/soloist"

# 1. Curl check
if command -v curl >/dev/null 2>&1; then
    CURL="$(command -v curl)"
elif [ -x /opt/bin/curl ]; then
    CURL="/opt/bin/curl"
else
    echo "ERROR: curl не найден." >&2
    exit 1
fi

# 2. Configuration check
[ -f "$CONFIG/config.env" ] || {
    echo "ERROR: config.env не найден." >&2
    exit 1
}

if [ ! -s "$CONFIG/apikey" ]; then
    echo "ERROR: API key не найден." >&2
    exit 1
elif [ "$(cat "$CONFIG/apikey")" = "dummy" ]; then
    echo "ERROR: Пожалуйста, замените 'dummy' на ваш реальный API ключ Soloist в файле $CONFIG/apikey" >&2
    exit 1
fi

. "$CONFIG/config.env"
API_KEY="$(cat "$CONFIG/apikey")"

DEVICE_NAME="${DEVICE_NAME:-Yandex Station}"
INITIAL_VOLUME="${INITIAL_VOLUME:-40}"

# 3. Internet check
wait_for_internet() {
    ATTEMPT=1

    while [ "$ATTEMPT" -le 5 ]; do
        echo "INFO: Проверка интернета ($ATTEMPT/5)..."

        if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 ||
           ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
            echo "INFO: Интернет доступен."
            return 0
        fi

        ATTEMPT=$((ATTEMPT + 1))
        [ "$ATTEMPT" -gt 5 ] || sleep 5
    done

    echo "ERROR: Интернет недоступен." >&2
    return 1
}

wait_for_internet || exit 1

# 4. Prepare RAM
mkdir -p "$RAM/bin" "$RAM/lib64" "$RAM/cache"

# 5. Download Spotify Soloist
echo "INFO: Скачивание Spotify Soloist..."
if [ ! -f "$RAM/bin/soloist" ] && [ ! -f "$RAM/soloist_arm64.tar.gz" ]; then
    "$CURL" -fL \
        -o "$RAM/soloist_arm64.tar.gz" \
        "https://soloist-builds.spotifycdn.com/soloist_release_arm64.tar.gz"
fi

# 6. Download libraries
if [ ! -f "$RAM/lib64/ld-linux-aarch64.so.1" ] || [ ! -f "$RAM/lib64/libpulse.so.0" ]; then
    if [ ! -f "$RAM/lib.tar.gz" ]; then
   
        echo "INFO: Скачивание библиотек..."
        RELEASE="${RELEASE:-latest}"

        if [ "$RELEASE" != "latest" ]; then
            RELEASE_URL="https://github.com/themmmchk/station-ram-soloist/releases/download/$RELEASE/lib.tar.gz"
        else
            RELEASE_URL="https://github.com/themmmchk/station-ram-soloist/releases/latest/download/lib.tar.gz"
        fi

        "$CURL" -fL \
            -o "$RAM/lib.tar.gz" \
            "$RELEASE_URL"
    fi
fi

# 7. Extract
echo "INFO: Распаковка..."

if [ ! -f "$RAM/bin/soloist" ]; then
    gzip -t "$RAM/soloist_arm64.tar.gz"
    gzip -dc "$RAM/soloist_arm64.tar.gz" |
        tar -xf - -C "$RAM/bin" soloist
fi

if [ -f "$RAM/lib.tar.gz" ]; then
    gzip -t "$RAM/lib.tar.gz"
    gzip -dc "$RAM/lib.tar.gz" |
        tar -xf - -C "$RAM/lib64"
fi

# chmod +x 
chmod +x "$RAM"/lib64/*
chmod +x "$RAM"/bin/soloist

# Remove archives to free RAM
rm -f "$RAM/soloist_arm64.tar.gz" "$RAM/lib.tar.gz"

# 8. Start Soloist
mkdir -p "$ROOT/data"

echo "INFO: Запуск cache guard..."

"$ROOT/cacheguard.sh" &

echo "INFO: Запуск Spotify Soloist..."

APULSE_PLAYBACK_DEVICE=plug:default \
APULSE_DIAG=0 \
LD_LIBRARY_PATH="$RAM/lib64" \
"$RAM/lib64/ld-linux-aarch64.so.1" \
    --library-path "$RAM/lib64" \
    "$RAM/bin/soloist" \
    -n "$DEVICE_NAME" \
    -k "$API_KEY" \
    -D "$ROOT/data" \
    -C "$RAM/cache" \
    -w 127.0.0.1:9090 \
    --initial-volume "$INITIAL_VOLUME" \
    -v
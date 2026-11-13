#!/bin/sh
set -e

# 1. Root check
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Этот скрипт должен выполняться от root на колонке!" >&2
    exit 1
fi

# 2. Arch check
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo "ERROR: Архитектура ядра $ARCH не поддерживается (требуется aarch64)." >&2
    exit 1
fi

# 3. Curl check
if command -v curl >/dev/null 2>&1; then
    CURL="$(command -v curl)"
elif [ -x /opt/bin/curl ]; then
    CURL="/opt/bin/curl"
else
    echo "ERROR: curl не найден. Пожалуйста, установите curl или добавьте curl в PATH и повторите попытку." >&2
    exit 1
fi

ROOT="/data/opt/ramsoloist"
CONFIG="$ROOT/config"

mkdir -p "$CONFIG"
echo "INFO: Создана директория $ROOT и $CONFIG"
echo "INFO: Скачивание скриптов start.sh & stop.sh..."
"$CURL" -fL -o "$ROOT/start.sh" https://raw.githubusercontent.com/themmmchk/station-ram-soloist/main/scripts/start.sh
"$CURL" -fL -o "$ROOT/stop.sh" https://raw.githubusercontent.com/themmmchk/station-ram-soloist/main/scripts/stop.sh
"$CURL" -fL -o "$ROOT/cacheguard.sh" https://raw.githubusercontent.com/themmmchk/station-ram-soloist/main/scripts/cacheguard.sh

trap 'mount -o remount,ro /' EXIT

mount -o remount,rw /

echo "INFO: Скачивание init.d скрипта S99zzzramsoloist..."
"$CURL" -fL -o "/etc/init.d/S99zzzramsoloist" https://raw.githubusercontent.com/themmmchk/station-ram-soloist/main/scripts/S99zzzramsoloist
echo "INFO: Скачивание завершено."
echo "INFO: Даем права на выполнение скриптов..."
chmod +x "$ROOT/start.sh" "$ROOT/stop.sh" "/etc/init.d/S99zzzramsoloist"

if [ ! -f "$CONFIG/apikey" ]; then
    printf 'dummy\n' > "$CONFIG/apikey"
    chmod 600 "$CONFIG/apikey"
    echo "INFO: Создан файл конфигурации API ключа. Пожалуйста, замените 'dummy' на ваш реальный API ключ Soloist в файле $CONFIG/apikey"
    echo "INFO: Создать ключ можно на сайте https://developer.spotify.com/dashboard"
fi

if [ ! -f "$CONFIG/config.env" ]; then
    printf '%s\n' \
    'DEVICE_NAME="Yandex Station"' \
    'INITIAL_VOLUME=100' \
    'RELEASE="latest"' \
    > "$CONFIG/config.env"
    echo "INFO: Создан файл конфигурации config.env"
fi
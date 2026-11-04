#!/usr/bin/env bash
# ========================================================
# License / IP Protection — shared library
# Usage (di file lain):
#   [[ -f /usr/local/sbin/lib/license.sh ]] && . /usr/local/sbin/lib/license.sh
# ========================================================

IZIN_URL="https://raw.githubusercontent.com/kcepu877/izin/main/ip"

# Hindari double-load
[[ -n "${__LICENSE_LOADED:-}" ]] && return 0 2>/dev/null || true
__LICENSE_LOADED=1

_lic_fail() {
    clear
    echo -e "\033[0;31m╔══════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;31m║            ACCESS DENIED — LICENSE           ║\033[0m"
    echo -e "\033[0;31m╚══════════════════════════════════════════════╝\033[0m"
    echo -e "\033[1;33m  $1\033[0m"
    shift
    for m in "$@"; do echo -e "\033[0;37m  $m\033[0m"; done
    echo -e "\033[0;36m  WhatsApp : wa.me/6287861167414\033[0m"
    echo ""
    exit 1
}

# Jalankan cek — bisa di-skip dengan env LICENSE_SKIP=1 (untuk debugging)
if [[ "${LICENSE_SKIP:-0}" != "1" ]]; then
    echo -e "\033[1;36m  Verifying license...\033[0m"

    VPS_IP=$(curl -sS --max-time 10 ipv4.icanhazip.com 2>/dev/null \
          || wget -qO- --timeout=10 ipv4.icanhazip.com 2>/dev/null \
          || curl -s --max-time 10 ipinfo.io/ip 2>/dev/null || echo "")

    [[ -z "$VPS_IP" ]] && _lic_fail "Gagal ambil IP VPS"

    echo -e "\033[0;37m  VPS IP : $VPS_IP\033[0m"

    DATE_NOW=$(date +"%Y-%m-%d")

    IZIN_LIST=$(curl -sS --max-time 10 "$IZIN_URL" 2>/dev/null \
             || wget -qO- --timeout=10 "$IZIN_URL" 2>/dev/null || echo "")

    [[ -z "$IZIN_LIST" ]] && _lic_fail "Gagal fetch izin list"

    MATCH=$(echo "$IZIN_LIST" | grep -w "$VPS_IP" || true)

    [[ -z "$MATCH" ]] && _lic_fail "404 NOT FOUND — IP TIDAK TERDAFTAR" "VPS IP : $VPS_IP"

    USERNAME=$(echo "$MATCH" | awk '{print $2}')
    EXPIRY=$(echo "$MATCH"   | awk '{print $3}')

    if [[ "$DATE_NOW" < "$EXPIRY" ]]; then
        echo -e "\033[0;32m  License valid — user: $USERNAME | exp: $EXPIRY\033[0m"
    else
        _lic_fail "LICENSE EXPIRED" "Expiry : $EXPIRY" "Today  : $DATE_NOW"
    fi

    mkdir -p /usr/bin
    echo "$USERNAME" > /usr/bin/user
    echo "$EXPIRY"   > /usr/bin/e
    chmod 644 /usr/bin/user /usr/bin/e
fi

#!/usr/bin/env bash

# Display only in interactive terminals
[[ $- != *i* ]] && return

HOST="$(hostname)"
UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //')"
LOAD="$(awk '{print $1, $2, $3}' /proc/loadavg)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
LAST_LOGIN="$(last -n 2 "$USER" 2>/dev/null | awk 'NR==2 {
    for (i=4; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : "")
}')"

printf '\033[1;36m'
cat <<'EOF'
  ____            _     
 |  _ \          | |    
 | |_) | __ _ ___| |__  
 |  _ < / _` / __| '_ \ 
 | |_) | (_| \__ \ | | |
 |____/ \__,_|___/_| |_|
EOF
printf '\033[0m'

printf '\n'
printf ' Welcome, \033[1;32m%s\033[0m!\n' "$USER"
printf ' Hostname:   %s\n' "$HOST"
printf ' Date:       %s\n' "$(date '+%A, %B %d, %Y — %H:%M:%S')"
printf ' Uptime:     %s\n' "${UPTIME:-unknown}"
printf ' IP address: %s\n' "${IP:-unavailable}"
printf ' Load:       %s\n' "$LOAD"

[[ -n "$LAST_LOGIN" ]] && printf ' Last login: %s\n' "$LAST_LOGIN"

printf '\n'

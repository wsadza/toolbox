#!/bin/bash

#------------------------------------
# Create welcome script 

SCRIPT_PATH_CONFIG="/etc/profile.d/welcome.sh"

cat <<EOF > "${SCRIPT_PATH_CONFIG}"
#!/usr/bin/env bash

printf '\n'
printf 'Welcome, %s@%s\n' \
    "${USER:-$(id -un)}" \
    "$(hostname)"

printf 'Container: %s\n' "$(hostname)"
printf 'System:    %s\n' "$(uname -sr)"

if command -v uptime >/dev/null 2>&1; then
    printf 'Uptime:    %s\n' "$(uptime -p 2>/dev/null || true)"
fi

printf '\n'
EOF

# Change config permissions
chmod -R a+rwX ${SCRIPT_PATH_CONFIG}
chown -R ${SUDO_USER} ${SCRIPT_PATH_CONFIG}

#------------------------------------
# Add to global bash.bashrc
#

BASHRC='/etc/bash.bashrc'
WELCOME_MARKER='# BEGIN liquidprompt'

if grep -Fq "$WELCOME_MARKER" "$BASHRC"; then
  exit 0; 
fi

cat >>"$BASHRC" <<'EOF'

# BEGIN liquidprompt

# Only configure interactive Bash shells.
case $- in
    *i*) ;;
    *) return ;;
esac

# Load Liquidprompt unless already loaded.
if ! declare -F lp_theme >/dev/null 2>&1; then
    source /usr/share/liquidprompt/liquidprompt
fi

# Load and activate the Unfold theme.
if [[ -r /usr/share/liquidprompt/unfold.theme ]]; then
    source /usr/share/liquidprompt/unfold.theme
    lp_theme unfold
fi

EOF

#!/bin/bash

#------------------------------------
# Create welcome script 

INITIAL_MESSAGE=$(cat <<EOF
Purpose:
  - 
Tools:

  - aider
  - llmchat
  - llm-cli

  - terraform
  - azure-cli
  - neovim
  - docker
  - tmux
  - k9s
  - kubectl
  - helm
    
Services:
  - llama.cpp       your localhosted ai
EOF
);

SCRIPT_PATH_CONFIG="/etc/profile.d/welcome.sh"

cat <<EOF > "${SCRIPT_PATH_CONFIG}"
#!/usr/bin/env bash

source /etc/docker-shared/logging.sh

log_separator
log_color "Toolbox"
log_box "${INITIAL_MESSAGE}"
log_separator

EOF

# Change config permissions
chmod -R a+rwX ${SCRIPT_PATH_CONFIG}
chown -R ${SUDO_USER} ${SCRIPT_PATH_CONFIG}

#------------------------------------
# Add to global bash.bashrc
#

BASHRC='/etc/bash.bashrc'
WELCOME_MARKER='# BEGIN welcome message'

if grep -Fq "$WELCOME_MARKER" "$BASHRC"; then
  exit 0; 
fi

cat >>"$BASHRC" <<'EOF'

# BEGIN interactive welcome message

# Show the welcome message for every interactive Bash invocation,
# including: docker exec -it <container> /bin/bash
case $- in
    *i*)
        if [[ -r /etc/profile.d/welcome.sh ]]; then
            source /etc/profile.d/welcome.sh
        fi
        ;;
esac

# END interactive welcome message
EOF

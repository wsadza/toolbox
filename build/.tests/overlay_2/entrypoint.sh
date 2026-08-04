############################################################
# Copyright (c) 2026 Igor Sadza 
# Released under the GPLv3 license
# ----------------------------------------------------------
# 
# FILE: ./overlay/entrypoint.sh
# DESC: 
#
############################################################
#!/bin/bash

# -----------------------------------
# Load global interactive Bash configuratuin fragments.
#

BASHRC='/etc/bash.bashrc'
BASHRC_MARKER='# BEGIN bash.bashrc.d loader'

if ! grep -Fq "${BASHRC_MARKER}" "${BASHRC}"; then
  sudo tee -a "${BASHRC}" >/dev/null <<'EOF'

# BEGIN bash.bashrc.d loader
# Load global interactive Bash configuration fragments.
if [[ $- == *i* ]] && [[ -d /etc/bash.bashrc.d ]]; then
    for file in /etc/bash.bashrc.d/*.sh; do
        [[ -r "$file" ]] && source "$file"
    done
    unset file
fi
# END bash.bashrc.d loader
EOF
fi

# -----------------------------------
# Execute all container core init scripts
#

for init_script in /etc/cont-init.d/core/*.sh; do
    echo "${init_script}"
    sudo chmod +x "${init_script}"
    sudo -E "${init_script:?}"
done

# -----------------------------------
# Execute all container optional init scripts
#

for init_script in /etc/cont-init.d/optional/*.sh; do
    echo "${init_script}"
    sudo chmod +x "${init_script}"
    sudo -E "${init_script:?}"
done

# Prepare all run-* scripts 
for init_script in /usr/bin/*_start_*.sh; do
    echo $init_script
    sudo chmod +x ${init_script}
done

# -----------------------------------
# Execute supervisord
#

# Consume global config
source /etc/bash.bashrc

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf --nodaemon  

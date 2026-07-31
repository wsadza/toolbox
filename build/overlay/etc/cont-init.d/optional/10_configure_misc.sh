#!/bin/bash

#------------------------------------
# Use Nvidia-GPU to render all applications
#

# Check nvidia-gpu avilibility
# 
if ! command -v nvidia-smi > /dev/null 2>&1; then
  exit 0;
fi

# Use gpu to render all applications
# 
if [ "${PRIME_RENDERER_GLOBAL}" == "true" ]; then

cat <<EOF >> /etc/bash.bashrc
export LLAMA_ARG_N_GPU_LAYERS=all
EOF

cat <<EOF >> /etc/environment
LLAMA_ARG_N_GPU_LAYERS=all
EOF

fi

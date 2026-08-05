#!/bin/bash
# https://nektosact.com/usage/index.html

# ----
<<<<<<< HEAD
#cat << EOF > /tmp/act_secrets
#GITHUB_TOKEN=""
#TOKEN=""
#EOF
=======
cat << EOF > /tmp/act_secrets
GITHUB_TOKEN=""
TOKEN=""
EOF
>>>>>>> c331b14 (Revert "cicd: added act.sh script")
# ----

act \
  --secret-file /tmp/act_secrets \
  --verbose

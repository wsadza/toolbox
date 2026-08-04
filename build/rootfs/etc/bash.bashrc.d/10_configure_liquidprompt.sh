#!/bin/bash

# -----------------------------------
# This file is sourced by interactive Bash shells only.
#

LIQUIDPROMPT_DIR=/usr/share/liquidprompt

if [[ -r "${LIQUIDPROMPT_DIR}/liquidprompt" ]]; then
    source "${LIQUIDPROMPT_DIR}/liquidprompt"
fi

if declare -F lp_theme >/dev/null 2>&1 \
    && [[ -r "${LIQUIDPROMPT_DIR}/${LIQUIDPROMPT_THEME}.theme" ]]; then
    source "${LIQUIDPROMPT_DIR}/${LIQUIDPROMPT_THEME}.theme"
    lp_theme ${LIQUIDPROMPT_THEME}
fi

unset LIQUIDPROMPT_DIR

#!/bin/bash

# ===========================================================            
# Variables
# =========================================================== 

# colors
export TERM=xterm-256color

# lolcat 
export PATH="/usr/games:$PATH"

# ===========================================================            
# Logging
# ===========================================================            

# Base Log - Core 
function log() {
  local status=$1 color=$2 phrase=$3 reset='\033[0m'
  echo >&2 -e "[\033[0;${color}m${status}${reset}]: ${phrase}" >&2
}

# Base Log's 
function log_error()   { log "ERROR"   "31" "$1"; }
function log_success() { log "SUCCESS" "32" "$1"; }
function log_info()    { log "INFO"    "34" "$1"; }
function log_warning() { log "WARNING" "33" "$1"; }

# Print break line; tput (ncurses) package is required
function log_separator() {
  if command -v tput &>/dev/null; then
    printf -v hr "%*s" "$(tput cols)" && echo -e "\033[0;35m${hr// /${1--}}\033[0m"
  else
    echo "tput (ncurses) is not installed. Please install ncurses to use log_separator."
  fi
}

# Print styled text; figlet package is required
function log_color() {
  if command -v figlet &>/dev/null && command -v lolcat &>/dev/null; then
    figlet -f smslant "$1" | lolcat -f
  else
    echo "figlet or lolcat is not installed. Please install them to use log_color."
  fi
}

# Print boxed text; boxes package is required 
function log_box() {
  if command -v boxes &>/dev/null; then
    echo "$1" | boxes -d ansi-rounded
  else
    echo "boxes is not installed. Please install it to use log_box."
  fi
}


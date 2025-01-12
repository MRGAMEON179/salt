#!/bin/bash

# VPS Deployment Script for Discord Bot with Role-Based Specs
# No systemd, systemctl, or Docker

# Configuration
BOT_REPO="https://github.com/your-username/your-discord-bot-repo.git" # Replace with your bot's GitHub repository
BOT_DIR_BASE="$HOME/discord-bot" # Base directory where bots will be installed
ENTRY_FILE="main.js" # Replace with the actual entry file of your bot (e.g., app.js, server.js, etc.)
NODE_VERSION="18" # Specify Node.js version
LOG_BASE_DIR="$HOME/discord-bot-logs" # Base directory for logs
ROLE="" # User role (admin, member, free)

# Role-Specific Deployment Specs
# Admin: No restrictions
# Member: Allow deploying bots with up to 6 GB storage
# Free: Restrict deployment to limited resources
MEMBER_STORAGE_LIMIT=6 # in GB
FREE_STORAGE_LIMIT=2 # in GB

# Helper Functions
function check_role_and_specs() {
  echo "Checking user role and resource limits..."
  
  if [[ "$ROLE" == "admin" ]]; then
    echo "Role: Admin. No restrictions on deployment."
  elif [[ "$ROLE" == "member" ]]; then
    echo "Role: Member. Bots are limited to $MEMBER_STORAGE_LIMIT GB of storage."
    enforce_storage_limit $MEMBER_STORAGE_LIMIT
  elif [[ "$ROLE" == "free" ]]; then
    echo "Role: Free User. Bots are limited to $FREE_STORAGE_LIMIT GB of storage."
    enforce_storage_limit $FREE_STORAGE_LIMIT
  else
    echo "Error: Invalid role. Please specify a valid role (admin, member, free)."
    exit 1
  fi
}

function enforce_storage_limit() {
  local limit_gb=$1
  echo "Enforcing storage limit: $limit_gb GB"

  # Check the current storage usage of the bot directory
  if [ -d "$BOT_DIR" ]; then
    local current_size=$(du -sh "$BOT_DIR" | awk '{print $1}' | sed 's/G//')
    if (( $(echo "$current_size > $limit_gb" | bc -l) )); then
      echo "Error: Current bot directory exceeds the allowed storage limit of $limit_gb GB."
      exit 1
    fi
  fi
}

function install_dependencies() {
  echo "Installing dependencies..."
  
  # Update package manager
  sudo apt update && sudo apt upgrade -y

  # Install Node.js and npm
  if ! command -v node &>/dev/null || ! node -v | grep -q $NODE_VERSION; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
    sudo apt install -y nodejs
  fi

  # Install Git
  if ! command -v git &>/dev/null; then
    echo "Installing Git..."
    sudo apt install -y git
  fi
}

function clone_or_update_repo() {
  if [ -d "$BOT_DIR" ]; then
    echo "Bot directory already exists. Pulling latest changes..."
    cd "$BOT_DIR" && git pull
  else
    echo "Cloning bot repository..."
    git clone "$BOT_REPO" "$BOT_DIR"
  fi
}

function install_bot_dependencies() {
  echo "Installing bot dependencies..."
  cd "$BOT_DIR" || exit
  npm install
}

function start_bot() {
  echo "Starting the bot..."
  
  # Check if the entry file exists
  if [ ! -f "$BOT_DIR/$ENTRY_FILE" ]; then
    echo "Error: Entry file '$ENTRY_FILE' not found in $BOT_DIR. Please update the ENTRY_FILE variable."
    exit 1
  fi

  # Check if the bot is already running
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo "Bot is already running with PID $(cat $PID_FILE)."
    exit 0
  fi

  # Start the bot in the background
  nohup node "$BOT_DIR/$ENTRY_FILE" >"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  echo "Bot started with PID $(cat $PID_FILE). Logs are being written to $LOG_FILE."
}

function stop_bot() {
  echo "Stopping the bot..."
  
  # Check if the bot is running
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    kill $(cat "$PID_FILE") && rm -f "$PID_FILE"
    echo "Bot stopped."
  else
    echo "Bot is not running."
  fi
}

function show_logs() {
  echo "Showing logs..."
  tail -f "$LOG_FILE"
}

# Prompt for User Role
read -p "Enter your role (admin, member, free): " ROLE

# Adjust Bot Directory and Log Files Based on Role
BOT_DIR="$BOT_DIR_BASE-$ROLE"
LOG_FILE="$LOG_BASE_DIR/$ROLE-bot.log"
PID_FILE="$BOT_DIR/bot.pid"

# Main Menu
echo "Discord Bot VPS Deployment Script (Role-Based)"
echo "----------------------------------------------"
check_role_and_specs
echo "1) Install/Update Bot"
echo "2) Start Bot"
echo "3) Stop Bot"
echo "4) Show Logs"
echo "5) Exit"
read -p "Choose an option: " OPTION

case $OPTION in
1)
  install_dependencies
  clone_or_update_repo
  install_bot_dependencies
  ;;
2)
  start_bot
  ;;
3)
  stop_bot
  ;;
4)
  show_logs
  ;;
5)
  echo "Exiting."
  exit 0
  ;;
*)
  echo "Invalid option."
  exit 1
  ;;
esac

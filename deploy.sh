#!/bin/bash

# Configuration
BOT_REPO="https://github.com/your-username/your-discord-bot-repo.git"  # Replace with your bot repo
BOT_DIR_BASE="$HOME/discord-bot"  # Base directory where bots are deployed
LOG_BASE_DIR="$HOME/discord-bot-logs"  # Base directory for logs
ENTRY_FILE="index.js"  # Default entry file (can be Python or Node.js script)
NODE_VERSION="18"  # Node.js version for Node-based bots
ROLE=""  # User role (admin, member, free)
MEMBER_STORAGE_LIMIT=6  # GB
FREE_STORAGE_LIMIT=2  # GB

# Role-based specifications
check_role_and_specs() {
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

# Enforce resource limits based on role
enforce_storage_limit() {
    limit_gb=$1
    echo "Enforcing storage limit of $limit_gb GB..."
    total_size=$(du -sh "$BOT_DIR" | awk '{print $1}')
    # Convert to GB for easier comparison
    total_size_gb=$(echo $total_size | sed 's/[A-Za-z]//g')
    if [[ "$total_size_gb" -gt "$limit_gb" ]]; then
        echo "Error: Bot directory exceeds the allowed storage limit of $limit_gb GB. Current size: $total_size_gb GB."
        exit 1
    fi
}

# Install dependencies for the bot
install_dependencies() {
    echo "Installing dependencies..."

    # Update package manager
    sudo apt-get update && sudo apt-get upgrade -y

    # Install Node.js and npm if necessary
    if ! command -v node &> /dev/null; then
        echo "Node.js is not installed. Installing Node.js version $NODE_VERSION..."
        curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # Install Git if necessary
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Installing Git..."
        sudo apt-get install -y git
    fi
}

# Clone or update the bot repository
clone_or_update_repo() {
    echo "Cloning or updating bot repository..."

    if [[ -d "$BOT_DIR" ]]; then
        echo "Bot directory already exists. Pulling latest changes..."
        cd "$BOT_DIR" || exit
        git pull
    else
        echo "Cloning bot repository..."
        git clone "$BOT_REPO" "$BOT_DIR"
    fi
}

# Install Node.js dependencies
install_node_dependencies() {
    echo "Installing Node.js dependencies..."

    # Go to the bot directory and install npm packages
    cd "$BOT_DIR" || exit

    # Check if package.json exists, if not, there's a problem with your setup
    if [[ ! -f "package.json" ]]; then
        echo "Error: package.json not found. This is likely not a Node.js bot."
        exit 1
    fi

    # Install dependencies using npm
    npm install
}

# Start or restart the bot
start_bot() {
    echo "Starting the bot..."
    if [[ -f "$BOT_DIR/$ENTRY_FILE" ]]; then
        # Start bot in the background
        nohup node "$BOT_DIR/$ENTRY_FILE" > "$LOG_BASE_DIR/bot.log" 2>&1 &
        echo "Bot started successfully. Logs are being written to $LOG_BASE_DIR/bot.log."
    else
        echo "Error: Entry file ($ENTRY_FILE) not found in $BOT_DIR."
        exit 1
    fi
}

# Main Program
echo "Discord Bot Upgrade Script"

# Prompt for user role
read -p "Enter your role (admin, member, free): " ROLE
ROLE=$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')

# Adjust directories based on role
BOT_DIR="$BOT_DIR_BASE-$ROLE"
LOG_DIR="$LOG_BASE_DIR-$ROLE"
mkdir -p "$LOG_DIR"

# Checking role and enforcing storage limit
check_role_and_specs

# Install required dependencies (Node.js, npm, git)
install_dependencies

# Clone or update bot repository
clone_or_update_repo

# Install node dependencies
install_node_dependencies

# Restart the bot
start_bot

echo "Bot is now online!"

#!/bin/bash

# Configuration
BOT_REPO="https://github.com/your-username/your-discord-bot-repo.git"  # Replace with your bot repo
BOT_DIR_BASE="$HOME/discord-bot"  # Base directory where bots are deployed
LOG_BASE_DIR="$HOME/discord-bot-logs"  # Base directory for logs
ENTRY_FILE="index.js"  # Default entry file (can be Python or Node.js script)
NODE_VERSION="18"  # Node.js version for Node-based bots

# Discord Role IDs (replace these with your actual role IDs from Discord)
ADMIN_ROLE_ID="1327979782100488212"  # Replace with your Discord admin role ID
MEMBER_ROLE_ID="your_member_role_id"  # Replace with your Discord member role ID
FREE_ROLE_ID="your_free_role_id"  # Replace with your Discord free role ID

# Role-based specifications (in GB)
ADMIN_STORAGE_LIMIT=100  # Admins have no limit, but you can set a high limit here
MEMBER_STORAGE_LIMIT=6  # Members are limited to 6 GB
FREE_STORAGE_LIMIT=2  # Free users are limited to 2 GB

# Function to get the user's Discord role ID
get_discord_role_id() {
    # For simplicity, we can ask the user to enter their role ID manually for now
    read -p "Enter your Discord role ID: " ROLE_ID
    echo "$ROLE_ID"
}

# Role-based behavior based on Discord role ID
check_role_and_specs() {
    echo "Checking user role and resource limits..."
    
    # Use case-insensitive comparison for role IDs
    if [[ "$ROLE_ID" == "$ADMIN_ROLE_ID" ]]; then
        echo "Role: Admin. No restrictions on deployment."
        STORAGE_LIMIT=$ADMIN_STORAGE_LIMIT
    elif [[ "$ROLE_ID" == "$MEMBER_ROLE_ID" ]]; then
        echo "Role: Member. Bots are limited to $MEMBER_STORAGE_LIMIT GB of storage."
        STORAGE_LIMIT=$MEMBER_STORAGE_LIMIT
    elif [[ "$ROLE_ID" == "$FREE_ROLE_ID" ]]; then
        echo "Role: Free User. Bots are limited to $FREE_STORAGE_LIMIT GB of storage."
        STORAGE_LIMIT=$FREE_STORAGE_LIMIT
    else
        echo "Error: Invalid role ID ($ROLE_ID). Please specify a valid Discord role ID."
        exit 1
    fi
    
    enforce_storage_limit $STORAGE_LIMIT
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

# Get the user's Discord role ID
ROLE_ID=$(get_discord_role_id)

# Adjust directories based on role
BOT_DIR="$BOT_DIR_BASE-$ROLE_ID"
LOG_DIR="$LOG_BASE_DIR-$ROLE_ID"
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

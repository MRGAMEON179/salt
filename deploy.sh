import os
import subprocess
import sys
import shutil

# Configuration
BOT_REPO = "https://github.com/your-username/your-discord-bot-repo.git"  # Replace with your bot repo
BOT_DIR_BASE = os.path.expanduser("~/discord-bot")  # Base directory where bots are deployed
LOG_BASE_DIR = os.path.expanduser("~/discord-bot-logs")  # Base directory for logs
ENTRY_FILE = "index.js"  # Default entry file (can be Python or Node.js script)
NODE_VERSION = "18"  # Node.js version for Node-based bots

# Role-based specifications
ROLE = ""  # User role (admin, member, free)
MEMBER_STORAGE_LIMIT = 6  # GB
FREE_STORAGE_LIMIT = 2  # GB

def check_role_and_specs():
    """Check role and enforce resource limits."""
    print("Checking user role and resource limits...")
    if ROLE == "admin":
        print("Role: Admin. No restrictions on deployment.")
    elif ROLE == "member":
        print(f"Role: Member. Bots are limited to {MEMBER_STORAGE_LIMIT} GB of storage.")
        enforce_storage_limit(MEMBER_STORAGE_LIMIT)
    elif ROLE == "free":
        print(f"Role: Free User. Bots are limited to {FREE_STORAGE_LIMIT} GB of storage.")
        enforce_storage_limit(FREE_STORAGE_LIMIT)
    else:
        print("Error: Invalid role. Please specify a valid role (admin, member, free).")
        sys.exit(1)

def enforce_storage_limit(limit_gb):
    """Enforce storage limit for the bot directory."""
    if os.path.exists(BOT_DIR):
        total_size = sum(
            os.path.getsize(os.path.join(dirpath, filename))
            for dirpath, _, filenames in os.walk(BOT_DIR)
            for filename in filenames
        ) / (1024 ** 3)  # Convert bytes to GB
        if total_size > limit_gb:
            print(f"Error: Current bot directory exceeds the allowed storage limit of {limit_gb} GB.")
            sys.exit(1)

def install_dependencies():
    """Install required dependencies."""
    print("Installing dependencies...")
    # Update package manager
    subprocess.run(["sudo", "apt", "update"], check=True)
    subprocess.run(["sudo", "apt", "upgrade", "-y"], check=True)

    # Install Node.js and npm if necessary
    if ENTRY_FILE.endswith(".js"):
        subprocess.run(
            f"curl -fsSL https://deb.nodesource.com/setup_{NODE_VERSION}.x | sudo -E bash -",
            shell=True,
            check=True,
        )
        subprocess.run(["sudo", "apt", "install", "-y", "nodejs"], check=True)

    # Install Git
    if shutil.which("git") is None:
        subprocess.run(["sudo", "apt", "install", "-y", "git"], check=True)

    # Install Python dependencies (if needed)
    if ENTRY_FILE.endswith(".py"):
        subprocess.run([sys.executable, "-m", "pip", "install", "--upgrade", "pip"], check=True)

def clone_or_update_repo():
    """Clone or update the bot repository."""
    if os.path.exists(BOT_DIR):
        print("Bot directory already exists. Pulling latest changes...")
        subprocess.run(["git", "-C", BOT_DIR, "pull"], check=True)
    else:
        print("Cloning bot repository...")
        subprocess.run(["git", "clone", BOT_REPO, BOT_DIR], check=True)

def install_bot_dependencies():
    """Install bot-specific dependencies."""
    print("Installing bot dependencies...")
    if ENTRY_FILE.endswith(".js"):
        subprocess.run(["npm", "install"], cwd=BOT_DIR, check=True)
    elif ENTRY_FILE.endswith(".py"):
        requirements_file = os.path.join(BOT_DIR, "requirements.txt")
        if os.path.exists(requirements_file):
            subprocess.run([sys.executable, "-m", "pip", "install", "-r", requirements_file], check=True)

def restart_bot():
    """Restart the bot."""
    print("Restarting the bot...")
    pid_file = os.path.join(BOT_DIR, "bot.pid")

    # Check if the bot is already running
    if os.path.exists(pid_file):
        with open(pid_file, "r") as f:
            pid = f.read().strip()
        if pid and subprocess.run(["kill", "-0", pid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            print(f"Bot is already running with PID {pid}. Restarting...")
            subprocess.run(["kill", pid], check=True)

    # Start the bot
    start_bot()

def start_bot():
    """Start the bot."""
    print("Starting the bot...")
    if not os.path.exists(os.path.join(BOT_DIR, ENTRY_FILE)):
        print(f"Error: Entry file '{ENTRY_FILE}' not found in {BOT_DIR}.")
        sys.exit(1)

    pid_file = os.path.join(BOT_DIR, "bot.pid")
    log_file = os.path.join(LOG_BASE_DIR, "bot.log")

    # Start the bot in the background
    command = []
    if ENTRY_FILE.endswith(".js"):
        command = ["node", ENTRY_FILE]
    elif ENTRY_FILE.endswith(".py"):
        command = [sys.executable, ENTRY_FILE]

    with open(log_file, "a") as log:
        process = subprocess.Popen(command, cwd=BOT_DIR, stdout=log, stderr=log)
        with open(pid_file, "w") as f:
            f.write(str(process.pid))

    print(f"Bot started with PID {process.pid}. Logs are being written to {log_file}.")

def show_logs():
    """Show bot logs."""
    log_file = os.path.join(LOG_BASE_DIR, "bot.log")
    if os.path.exists(log_file):
        subprocess.run(["tail", "-f", log_file])
    else:
        print("No logs found.")

# Main Program
if __name__ == "__main__":
    # Prompt for user role
    ROLE = input("Enter your role (admin, member, free): ").strip().lower()

    # Adjust directories based on role
    BOT_DIR = f"{BOT_DIR_BASE}-{ROLE}"
    LOG_DIR = f"{LOG_BASE_DIR}-{ROLE}"

    # Create log directory if it doesn't exist
    os.makedirs(LOG_DIR, exist_ok=True)

    # Menu
    print("Discord Bot VPS Upgrade Script")
    print("-----------------------------")
    check_role_and_specs()
    while True:
        print("\n1) Upgrade Bot (Pull latest code and install dependencies)")
        print("2) Restart Bot")
        print("3) Show Logs")
        print("4) Exit")
        choice = input("Choose an option: ").strip()

        if choice == "1":
            install_dependencies()
            clone_or_update_repo()
            install_bot_dependencies()
        elif choice == "2":
            restart_bot()
        elif choice == "3":
            show_logs()
        elif choice == "4":
            print("Exiting.")
            break
        else:
            print("Invalid option.")

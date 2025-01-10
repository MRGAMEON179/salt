import discord
from discord.ext import commands
import paramiko
import asyncio
import requests

# Replace these placeholders with your information
BOT_TOKEN = "YOUR_BOT_TOKEN"
DISCORD_WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL"
PROXMOX_SERVER_IP = "YOUR_PROXMOX_SERVER_IP"
DISCORD_SERVER_ID = "YOUR_DISCORD_SERVER_ID"
AUTHORIZED_ROLE_IDS = ["ROLE_ID_1"]  # List of authorized role IDs
SSH_USERNAME = "root"  # Default SSH username
SSH_PASSWORD = "YOUR_SSH_PASSWORD"  # Root password for Proxmox

# Discord bot setup
intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix="/", intents=intents)

@bot.event
async def on_ready():
    print(f"Bot is online and logged in as {bot.user}")

# Create VPS command
@bot.command(name="create-vps-intel")
async def create_vps(ctx, memory: int, cores: int, disk: str, customer: str):
    # Check for authorized roles
    user_roles = [role.id for role in ctx.author.roles]
    if not any(role_id in AUTHORIZED_ROLE_IDS for role_id in user_roles):
        await ctx.send("You are not authorized to use this command.")
        return

    # Send acknowledgment
    await ctx.send("Creating VPS...")

    # Define SSH command to create a VPS on Proxmox
    ssh_command = f"""
    pct create 100 local:vztmpl/debian-11-standard_11.0-1_amd64.tar.gz \
    -memory {memory} -cores {cores} -rootfs local-lvm:{disk} \
    -net0 name=eth0,bridge=vmbr0,firewall=1 \
    -hostname {customer} --password=securepassword123 \
    --start=1
    """

    try:
        # Establish SSH connection to Proxmox server
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(PROXMOX_SERVER_IP, username=SSH_USERNAME, password=SSH_PASSWORD)

        # Execute the command
        stdin, stdout, stderr = ssh.exec_command(ssh_command)
        output = stdout.read().decode("utf-8")
        error = stderr.read().decode("utf-8")
        ssh.close()

        if error:
            await ctx.send(f"Error creating VPS: {error}")
        else:
            await ctx.send(f"VPS created successfully: {output}")

            # Send login details to the user via DM
            dm_message = (
                f"Hello {ctx.author.name}, your VPS has been created.\n"
                f"Hostname: {customer}\nMemory: {memory}GB\nCores: {cores}\n"
                f"Disk: {disk}\nPassword: securepassword123"
            )
            await ctx.author.send(dm_message)

            # Log the event to a Discord webhook
            payload = {"content": f"VPS created for {customer} by {ctx.author.name}"}
            requests.post(DISCORD_WEBHOOK_URL, json=payload)

    except Exception as e:
        await ctx.send(f"An error occurred: {str(e)}")

# Run the bot
if __name__ == "__main__":
    bot.run(BOT_TOKEN)

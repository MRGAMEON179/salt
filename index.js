// Import discord.js
const { Client, GatewayIntentBits } = require('discord.js');

// Create a new client instance
const client = new Client({ 
  intents: [
    GatewayIntentBits.Guilds, 
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers
  ]
});

// The token of your bot (replace with your actual bot token)
const token = 'YOUR_BOT_TOKEN';

// When the bot is ready, log a message to the console
client.once('ready', () => {
  console.log('Bot is online!');
});

// Listen for messages and respond to a "ping" message with "Pong!"
client.on('messageCreate', (message) => {
  if (message.content.toLowerCase() === 'ping') {
    message.reply('Pong!');
  }
});

// Log in to Discord with your app's token
client.login(token);

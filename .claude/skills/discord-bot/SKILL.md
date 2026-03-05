---
name: discord-bot
description: Discord bot development with discord.py 2.x and discord.js 14.x. Covers cogs, slash commands, events, embeds, and deployment patterns.
---

# Discord Bot Development Skill

## When to Activate
- Creating or modifying Discord bots
- Working with Discord API
- Building slash commands, event handlers
- Discord server automation

## Framework Selection

| Framework | Language | Use Case |
|-----------|----------|----------|
| **discord.py 2.x** | Python | General bots, async Python ecosystem, data-heavy bots |
| **discord.js 14.x** | Node.js | Real-time features, large community, TypeScript support |

## discord.py 2.x Project Structure

```
bot/
  __init__.py
  main.py            # Entry point
  config.py          # Settings
  cogs/
    __init__.py
    general.py       # General commands
    moderation.py    # Mod commands
    music.py         # Music features
  utils/
    __init__.py
    embeds.py        # Embed builders
    checks.py        # Permission checks
    database.py      # DB operations
```

### Bot Entry Point (discord.py)
```python
import discord
from discord.ext import commands
import os

intents = discord.Intents.default()
intents.message_content = True
intents.members = True

bot = commands.Bot(command_prefix="!", intents=intents)

async def load_extensions():
    for filename in os.listdir("./bot/cogs"):
        if filename.endswith(".py") and not filename.startswith("_"):
            await bot.load_extension(f"bot.cogs.{filename[:-3]}")

@bot.event
async def on_ready():
    await bot.tree.sync()
    print(f"Logged in as {bot.user}")

async def main():
    await load_extensions()
    await bot.start(os.getenv("DISCORD_TOKEN"))

import asyncio
asyncio.run(main())
```

### Hybrid Commands (work as both prefix and slash commands)
```python
import discord
from discord.ext import commands

@bot.hybrid_command(name="ping", description="Check bot latency")
async def ping(ctx):
    """Works as both !ping and /ping."""
    latency = round(bot.latency * 1000)
    await ctx.send(f"Pong! {latency}ms")

@bot.hybrid_command(name="avatar", description="Get a user avatar")
async def avatar(ctx, member: discord.Member = None):
    """Display a user's avatar."""
    member = member or ctx.author
    embed = discord.Embed(title=f"{member.display_name}'s Avatar")
    embed.set_image(url=member.display_avatar.url)
    await ctx.send(embed=embed)

# Don't forget to sync the command tree on startup:
# await bot.tree.sync()
```

### Cog with Slash Commands
```python
import discord
from discord.ext import commands
from discord import app_commands

class General(commands.Cog):
    def __init__(self, bot: commands.Bot):
        self.bot = bot

    @app_commands.command(name="ping", description="Check bot latency")
    async def ping(self, interaction: discord.Interaction):
        await interaction.response.send_message(
            f"Pong! {round(self.bot.latency * 1000)}ms"
        )

    @app_commands.command(name="info", description="Server info")
    async def info(self, interaction: discord.Interaction):
        guild = interaction.guild
        embed = discord.Embed(title=guild.name, color=discord.Color.blue())
        embed.add_field(name="Members", value=guild.member_count)
        embed.add_field(name="Created", value=guild.created_at.strftime("%Y-%m-%d"))
        await interaction.response.send_message(embed=embed)

async def setup(bot: commands.Bot):
    await bot.add_cog(General(bot))
```

### Event Handlers
```python
class Events(commands.Cog):
    def __init__(self, bot):
        self.bot = bot

    @commands.Cog.listener()
    async def on_member_join(self, member: discord.Member):
        channel = member.guild.system_channel
        if channel:
            embed = discord.Embed(
                title="Welcome!",
                description=f"{member.mention} joined the server!",
                color=discord.Color.green()
            )
            await channel.send(embed=embed)

    @commands.Cog.listener()
    async def on_command_error(self, ctx, error):
        if isinstance(error, commands.CommandNotFound):
            return  # Silently ignore unknown commands
        elif isinstance(error, commands.MissingPermissions):
            perms = ", ".join(error.missing_permissions)
            await ctx.send(f"Missing permissions: {perms}")
        elif isinstance(error, commands.MissingRequiredArgument):
            await ctx.send(f"Missing argument: `{error.param.name}`")
        elif isinstance(error, commands.BadArgument):
            await ctx.send(f"Invalid argument: {error}")
        elif isinstance(error, commands.CommandOnCooldown):
            await ctx.send(f"Cooldown: try again in {error.retry_after:.1f}s")
        elif isinstance(error, commands.CheckFailure):
            await ctx.send("You do not have permission to use this command.")
        else:
            print(f"Unexpected error: {error}")
            await ctx.send("An unexpected error occurred.")
```

## discord.js 14.x Structure

```
bot/
  index.js           # Entry point
  config.js          # Settings
  commands/
    general/
      ping.js
      info.js
    moderation/
      ban.js
      kick.js
  events/
    ready.js
    interactionCreate.js
    guildMemberAdd.js
  utils/
    embeds.js
    database.js
```

### Slash Command (discord.js)
```javascript
const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');

module.exports = {
    data: new SlashCommandBuilder()
        .setName('ping')
        .setDescription('Check bot latency'),
    async execute(interaction) {
        await interaction.reply(`Pong! ${interaction.client.ws.ping}ms`);
    },
};
```

## Key Patterns

- Use slash commands (not prefix commands) for new bots
- Implement proper rate limiting and cooldowns
- Use embeds for rich message formatting
- Separate concerns into cogs (Python) or command files (JS)
- Store bot token in environment variables, never in code
- Use Discord's built-in permissions system
- Implement error handling for all commands

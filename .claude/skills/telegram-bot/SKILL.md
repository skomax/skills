---
name: telegram-bot
description: Telegram bot development with aiogram 3.x, python-telegram-bot, Telethon, and pyrogram. Covers bot architecture, handlers, keyboards, webhooks, and deployment.
---

# Telegram Bot Development Skill

## When to Activate
- Creating or modifying Telegram bots
- Working with Telegram Bot API
- Setting up webhooks or long polling
- Building inline keyboards, callback handlers
- Telegram userbot or channel management

## Framework Selection

| Framework | Use Case | Style |
|-----------|----------|-------|
| **aiogram 3.x** | Production bots, complex logic, FSM | Async, router-based |
| **python-telegram-bot 21.x** | Simple bots, quick prototypes | Sync/async, handler-based |
| **Telethon** | Userbots, account automation, MTProto | Async, low-level |
| **pyrogram** | Userbots + bots, media handling | Async, modern API |

**Default choice: aiogram 3.x** - best for production bots.

## aiogram 3.x Project Structure

```
bot/
  __init__.py
  main.py              # Entry point, bot startup
  config.py            # Settings from env
  handlers/
    __init__.py
    start.py           # /start, /help commands
    admin.py           # Admin commands
    callbacks.py       # Callback query handlers
    errors.py          # Error handler
  keyboards/
    __init__.py
    inline.py          # InlineKeyboardMarkup builders
    reply.py           # ReplyKeyboardMarkup builders
  middlewares/
    __init__.py
    auth.py            # User authentication
    throttling.py      # Rate limiting
  services/
    __init__.py
    database.py        # DB operations
    api_client.py      # External API calls
  models/
    __init__.py
    user.py            # User model
  filters/
    __init__.py
    admin.py           # Admin check filter
  states/
    __init__.py
    forms.py           # FSM states
  utils/
    __init__.py
    helpers.py
```

## aiogram 3.x Core Patterns

### Bot Entry Point
```python
import asyncio
from aiogram import Bot, Dispatcher
from aiogram.enums import ParseMode
from aiogram.client.default import DefaultBotProperties

from bot.config import settings
from bot.handlers import start, admin, callbacks

async def main():
    bot = Bot(
        token=settings.BOT_TOKEN,
        default=DefaultBotProperties(parse_mode=ParseMode.HTML)
    )
    dp = Dispatcher()

    # Register routers
    dp.include_routers(
        start.router,
        admin.router,
        callbacks.router,
    )

    # Start polling
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
```

### Router-Based Handlers
```python
from aiogram import Router, F
from aiogram.types import Message, CallbackQuery
from aiogram.filters import Command, CommandStart

router = Router()

@router.message(CommandStart())
async def cmd_start(message: Message):
    await message.answer(
        "Welcome! Choose an option:",
        reply_markup=get_main_keyboard()
    )

@router.message(Command("help"))
async def cmd_help(message: Message):
    await message.answer("Available commands:\n/start - Main menu\n/help - This message")

@router.callback_query(F.data.startswith("action:"))
async def handle_action(callback: CallbackQuery):
    action = callback.data.split(":")[1]
    await callback.answer(f"Processing: {action}")
    await callback.message.edit_text(f"Action {action} completed")
```

### Inline Keyboards
```python
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton
from aiogram.utils.keyboard import InlineKeyboardBuilder

def get_main_keyboard() -> InlineKeyboardMarkup:
    builder = InlineKeyboardBuilder()
    builder.row(
        InlineKeyboardButton(text="Status", callback_data="action:status"),
        InlineKeyboardButton(text="Settings", callback_data="action:settings"),
    )
    builder.row(
        InlineKeyboardButton(text="Help", callback_data="action:help"),
    )
    return builder.as_markup()
```

### FSM (Finite State Machine)
```python
from aiogram.fsm.state import State, StatesGroup
from aiogram.fsm.context import FSMContext

class AddChannel(StatesGroup):
    waiting_for_name = State()
    waiting_for_url = State()
    confirmation = State()

@router.message(Command("add_channel"))
async def start_add(message: Message, state: FSMContext):
    await state.set_state(AddChannel.waiting_for_name)
    await message.answer("Enter channel name:")

@router.message(AddChannel.waiting_for_name)
async def process_name(message: Message, state: FSMContext):
    await state.update_data(name=message.text)
    await state.set_state(AddChannel.waiting_for_url)
    await message.answer("Enter channel URL:")

@router.message(AddChannel.waiting_for_url)
async def process_url(message: Message, state: FSMContext):
    data = await state.get_data()
    await state.clear()
    await message.answer(f"Channel '{data['name']}' with URL {message.text} added!")
```

### Middleware
```python
from aiogram import BaseMiddleware
from typing import Callable, Awaitable, Any

class AuthMiddleware(BaseMiddleware):
    async def __call__(
        self,
        handler: Callable[[Message, dict[str, Any]], Awaitable[Any]],
        event: Message,
        data: dict[str, Any],
    ) -> Any:
        user = await db.get_user(event.from_user.id)
        if not user:
            await event.answer("Access denied. Contact admin.")
            return
        data["user"] = user
        return await handler(event, data)
```

### Webhook Setup (Production)
```python
from aiogram.webhook.aiohttp_server import SimpleRequestHandler, setup_application
from aiohttp import web

WEBHOOK_PATH = f"/webhook/{settings.BOT_TOKEN}"
WEBHOOK_URL = f"https://{settings.DOMAIN}{WEBHOOK_PATH}"

async def on_startup(bot: Bot):
    await bot.set_webhook(WEBHOOK_URL)

app = web.Application()
webhook_handler = SimpleRequestHandler(dispatcher=dp, bot=bot)
webhook_handler.register(app, path=WEBHOOK_PATH)
setup_application(app, dp, bot=bot)
web.run_app(app, host="0.0.0.0", port=8080)
```

## Telethon (Userbots / Channel Management)

### Basic Setup
```python
from telethon import TelegramClient, events
from telethon.sessions import StringSession

# File session (persists on disk)
client = TelegramClient("session_name", api_id, api_hash)

# String session (for Docker / serverless - store in env var)
client = TelegramClient(StringSession(SESSION_STRING), api_id, api_hash)
```

### Channel Parsing & Forwarding
```python
@client.on(events.NewMessage(chats=["source_channel"]))
async def forward_handler(event):
    # Forward with original formatting
    await client.send_message("target_channel", event.message)

# Parse channel history
async def parse_channel_history(channel: str, limit: int = 100) -> list[dict]:
    messages = []
    async for msg in client.iter_messages(channel, limit=limit):
        messages.append({
            "id": msg.id,
            "text": msg.text,
            "date": msg.date,
            "views": msg.views,
            "media": bool(msg.media),
            "forwards": msg.forwards,
        })
    return messages

# Download media from channel
async def download_channel_media(channel: str, dest_dir: str, limit: int = 50):
    async for msg in client.iter_messages(channel, limit=limit):
        if msg.media:
            await client.download_media(msg, file=dest_dir)
```

### Session Management
```python
# Generate string session (run once interactively)
async def generate_session():
    async with TelegramClient(StringSession(), api_id, api_hash) as client:
        print("Session string:", client.session.save())

# Multi-account management
# WARNING: Telegram actively bans automated accounts.
# Using multiple userbots may violate Telegram ToS. Use at your own risk.
class AccountPool:
    def __init__(self, sessions: list[str]):
        self.clients = [
            TelegramClient(StringSession(s), api_id, api_hash)
            for s in sessions
        ]
        self.current = 0

    async def get_client(self) -> TelegramClient:
        """Round-robin client selection to avoid rate limits."""
        client = self.clients[self.current]
        self.current = (self.current + 1) % len(self.clients)
        if not client.is_connected():
            await client.connect()
        return client
```

## Pyrogram (Modern MTProto)

```python
from pyrogram import Client, filters
from pyrogram.types import Message

app = Client("my_account", api_id=api_id, api_hash=api_hash)

# Channel message handler
@app.on_message(filters.channel & filters.chat("source_channel"))
async def channel_handler(client: Client, message: Message):
    # Process and forward
    text = message.text or message.caption or ""
    if should_forward(text):
        await client.send_message("target_channel", text)

# Batch operations
async def get_channel_members(channel: str) -> list:
    members = []
    async for member in app.get_chat_members(channel):
        members.append({"id": member.user.id, "name": member.user.first_name})
    return members

# Media group handling
@app.on_message(filters.media_group)
async def media_group_handler(client: Client, message: Message):
    media_group = await client.get_media_group(message.chat.id, message.id)
    for msg in media_group:
        await client.download_media(msg, file_name=f"media/{msg.id}")
```

## Telegram Payments & Mini Apps

### Telegram Stars Payment
```python
from aiogram.types import LabeledPrice

@router.message(Command("buy"))
async def cmd_buy(message: Message):
    await message.answer_invoice(
        title="Premium Access",
        description="30 days of premium features",
        payload="premium_30d",
        currency="XTR",  # Telegram Stars
        prices=[LabeledPrice(label="Premium", amount=100)],  # 100 Stars
    )

@router.pre_checkout_query()
async def pre_checkout(query: PreCheckoutQuery):
    await query.answer(ok=True)

@router.message(F.successful_payment)
async def payment_success(message: Message):
    payment = message.successful_payment
    await activate_premium(message.from_user.id, days=30)
    await message.answer("Premium activated!")
```

### Telegram Mini App (Web App)
```python
from aiogram.types import WebAppInfo, InlineKeyboardButton
from aiogram.utils.keyboard import InlineKeyboardBuilder

@router.message(Command("app"))
async def open_app(message: Message):
    builder = InlineKeyboardBuilder()
    builder.add(InlineKeyboardButton(
        text="Open Dashboard",
        web_app=WebAppInfo(url="https://your-app.com/miniapp")
    ))
    await message.answer("Open the dashboard:", reply_markup=builder.as_markup())

# Validate data from Mini App
from aiogram.utils.web_app import check_webapp_signature, parse_webapp_init_data

def validate_webapp_data(init_data: str, bot_token: str) -> dict:
    if check_webapp_signature(bot_token, init_data):
        return parse_webapp_init_data(init_data)
    raise ValueError("Invalid webapp data")
```

## Bot + Telethon Hybrid Architecture

Use aiogram for bot commands and Telethon for userbot features in the same project.

```python
import asyncio
from aiogram import Bot, Dispatcher
from telethon import TelegramClient

async def main():
    # Bot (via Bot API)
    bot = Bot(token=BOT_TOKEN)
    dp = Dispatcher()
    dp.include_router(bot_handlers.router)

    # Userbot (via MTProto)
    userbot = TelegramClient(StringSession(SESSION), api_id, api_hash)
    await userbot.start()

    # Share data via Redis
    redis = await aioredis.from_url("redis://localhost")

    # Run both concurrently
    await asyncio.gather(
        dp.start_polling(bot),
        userbot.run_until_disconnected(),
    )
```

## Docker Deployment
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "-m", "bot.main"]
```

```yaml
# docker-compose.yml
services:
  bot:
    build: .
    env_file: .env
    restart: always
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
```

## See Also
- `docker-devops` skill for production Docker deployment
- `database-patterns` skill for bot data persistence
- `prompt-engineering` skill for LLM-powered bot features

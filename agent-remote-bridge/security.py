import functools
import html
import logging
from typing import Callable, Any
from telegram import Update
from telegram.constants import ParseMode
from telegram.ext import ContextTypes
from config import settings

logger = logging.getLogger("RemoteBridge.Security")


def is_user_allowed(user_id: int | None) -> bool:
    """Check if the provided Telegram user ID is in the allowed whitelist."""
    if user_id is None:
        return False
    allowed = settings.allowed_user_ids
    if not allowed:
        # If no user whitelist is configured, reject for security
        return False
    return user_id in allowed


def restricted(func: Callable) -> Callable:
    """Decorator to restrict handler access only to authorized user IDs."""

    @functools.wraps(func)
    async def wrapped(update: Update, context: ContextTypes.DEFAULT_TYPE, *args: Any, **kwargs: Any) -> Any:
        user = update.effective_user
        if not user or not is_user_allowed(user.id):
            user_id_str = str(user.id) if user else "Bilinmiyor"
            username_str = f"@{user.username}" if user and user.username else "İsimsiz"
            logger.warning(f"🚫 Yetkisiz erişim denemesi engellendi: ID={user_id_str} ({username_str})")
            
            if update.effective_message:
                await update.effective_message.reply_text(
                    f"⛔ <b>Yetkisiz Erişim</b>\n\n"
                    f"Bu bot Hoppa projesi yönetim köprüsüdür. Erişim yetkiniz bulunmamaktadır.\n\n"
                    f"🆔 <b>Sizin Telegram ID:</b> <code>{html.escape(user_id_str)}</code>\n\n"
                    f"💡 <b>Nasıl yetki alırsınız?</b>\n"
                    f"<code>agent-remote-bridge/.env</code> dosyasındaki <code>ALLOWED_USER_ID</code> alanına yukarıdaki ID'nizi ekleyin.",
                    parse_mode=ParseMode.HTML,
                )
            return
        return await func(update, context, *args, **kwargs)

    return wrapped

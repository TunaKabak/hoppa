import logging
import sys
import asyncio
import html

# Ensure utf-8 encoding on Windows console
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.constants import ParseMode, ChatAction
from telegram.request import HTTPXRequest
from telegram.error import NetworkError, TimedOut, Conflict, BadRequest
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

from config import settings
from security import restricted, is_user_allowed
import agent_runner
import task_analyzer
import ai_agent
import ide_automation

# Configure logging
logging.basicConfig(
    format="%(asctime)s - [%(name)s] - %(levelname)s - %(message)s",
    level=getattr(logging, settings.LOG_LEVEL.upper(), logging.INFO),
)
logger = logging.getLogger("RemoteBridge.Main")


def build_main_keyboard() -> InlineKeyboardMarkup:
    """Build interactive inline keyboard for quick Hoppa control actions."""
    keyboard = [
        [
            InlineKeyboardButton("📊 Proje Durumu", callback_data="cmd_status"),
            InlineKeyboardButton("🌿 Git Durumu", callback_data="cmd_git"),
        ],
        [
            InlineKeyboardButton("🔍 Flutter Analiz", callback_data="cmd_flutter"),
            InlineKeyboardButton("⚙️ Backend Tip Kontrol", callback_data="cmd_backend"),
        ],
        [
            InlineKeyboardButton("🌐 Web Derleme Testi", callback_data="cmd_web"),
            InlineKeyboardButton("🗄️ Prisma Şema Kontrol", callback_data="cmd_prisma"),
        ],
        [
            InlineKeyboardButton("❓ Yardım & Komutlar", callback_data="cmd_help"),
        ],
    ]
    return InlineKeyboardMarkup(keyboard)


async def send_formatted_output(update: Update, title: str, content: str, is_error: bool = False):
    """Send long outputs chunked cleanly in HTML pre blocks."""
    chunks = agent_runner.chunk_text(content)
    icon = "❌" if is_error else "✅"
    
    target = update.effective_message
    if not target:
        return

    # First chunk with title
    header = f"{icon} <b>{html.escape(title)}</b>\n<pre>{html.escape(chunks[0])}</pre>"
    await target.reply_text(header, parse_mode=ParseMode.HTML)

    # Remaining chunks if any
    for chunk in chunks[1:]:
        await target.reply_text(f"<pre>{html.escape(chunk)}</pre>", parse_mode=ParseMode.HTML)


@restricted
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /start command."""
    user = update.effective_user
    name = html.escape(user.first_name if user else "Geliştirici")
    welcome_text = (
        f"👋 <b>Merhaba, {name}!</b>\n\n"
        f"🚀 <b>Hoppa Remote Agent Bridge</b> yönetim paneline bağlandınız.\n\n"
        f"Aşağıdaki hızlı butonları kullanarak projeyi analiz edebilir, derleme testleri çalıştırabilir "
        f"veya herhangi bir görev yazarak onaylı planlama başlatabilirsiniz."
    )
    await update.effective_message.reply_text(
        welcome_text,
        reply_markup=build_main_keyboard(),
        parse_mode=ParseMode.HTML,
    )


@restricted
async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /help command."""
    help_text = (
        f"📖 <b>Hoppa Remote Bridge Komut Listesi:</b>\n\n"
        f"🔹 <code>/status</code> — Çalışma dizini, Git dalı ve sistem bilgileri\n"
        f"🔹 <code>/git_status</code> — Değiştirilen dosyalar ve son commit\n"
        f"🔹 <code>/flutter_analyze</code> — Monorepo genelinde <code>flutter analyze</code>\n"
        f"🔹 <code>/backend_check</code> — Backend <code>npx tsc --noEmit</code> tip kontrolü\n"
        f"🔹 <code>/web_build</code> — Web App <code>npm run build</code> derleme kontrolü\n"
        f"🔹 <code>/prisma_check</code> — Backend Prisma şema doğrulaması\n"
        f"🔹 <code>/run &lt;komut&gt;</code> — Proje dizininde özel terminal komutu çalıştırır\n\n"
        f"💡 <b>Görev Gönderme:</b> Bota doğrudan Türkçe isteğinizi yazabilirsiniz. Bot önce analiz edip onay planı sunacaktır."
    )
    await update.effective_message.reply_text(
        help_text,
        reply_markup=build_main_keyboard(),
        parse_mode=ParseMode.HTML,
    )


@restricted
async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /status command."""
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    status_text = await agent_runner.get_system_info()
    await update.effective_message.reply_text(
        status_text,
        reply_markup=build_main_keyboard(),
        parse_mode=ParseMode.HTML,
    )


@restricted
async def cmd_flutter_analyze(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /flutter_analyze."""
    await update.effective_message.reply_text("⏳ <code>flutter analyze</code> çalıştırılıyor, lütfen bekleyin...", parse_mode=ParseMode.HTML)
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    code, output = await agent_runner.run_flutter_analyze()
    await send_formatted_output(update, "Flutter Analyze Sonucu", output, is_error=(code != 0))


@restricted
async def cmd_backend_check(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /backend_check."""
    await update.effective_message.reply_text("⏳ <code>npx tsc --noEmit</code> çalıştırılıyor...", parse_mode=ParseMode.HTML)
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    code, output = await agent_runner.run_backend_check()
    await send_formatted_output(update, "Backend TypeScript Kontrolü", output, is_error=(code != 0))


@restricted
async def cmd_web_build(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /web_build."""
    await update.effective_message.reply_text("⏳ <code>npm run build</code> (apps/web_app) çalıştırılıyor...", parse_mode=ParseMode.HTML)
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    code, output = await agent_runner.run_web_build()
    await send_formatted_output(update, "Web App Derleme Sonucu", output, is_error=(code != 0))


@restricted
async def cmd_prisma_check(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /prisma_check."""
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    code, output = await agent_runner.run_prisma_check()
    await send_formatted_output(update, "Prisma Şema Kontrolü", output, is_error=(code != 0))


@restricted
async def cmd_git_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /git_status."""
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    code, output = await agent_runner.get_git_status()
    await send_formatted_output(update, "Git Durumu", output, is_error=(code != 0))


@restricted
async def cmd_run(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handler for /run <command>."""
    if not context.args:
        await update.effective_message.reply_text(
            "⚠️ Lütfen çalıştırmak istediğiniz komutu belirtin.\n\n<b>Örnek:</b> <code>/run git status</code>",
            parse_mode=ParseMode.HTML,
        )
        return

    command = " ".join(context.args)
    await update.effective_message.reply_text(f"⏳ Komut çalıştırılıyor:\n<code>{html.escape(command)}</code>", parse_mode=ParseMode.HTML)
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)
    
    code, stdout, stderr = await agent_runner.run_async_command(command)
    output = stdout if stdout else stderr
    await send_formatted_output(update, f"Komut: {command} (Çıkış Kodu: {code})", output or "(Boş çıktı)", is_error=(code != 0))


@restricted
async def handle_callback_query(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle inline keyboard button clicks including approval and standard actions."""
    query = update.callback_query
    await query.answer()
    data = query.data

    if data == "cmd_status":
        await cmd_status(update, context)
    elif data == "cmd_git":
        await cmd_git_status(update, context)
    elif data == "cmd_flutter":
        await cmd_flutter_analyze(update, context)
    elif data == "cmd_backend":
        await cmd_backend_check(update, context)
    elif data == "cmd_web":
        await cmd_web_build(update, context)
    elif data == "cmd_prisma":
        await cmd_prisma_check(update, context)
    elif data == "cmd_help":
        await cmd_help(update, context)
    elif data.startswith("approve_new_") or data.startswith("approve_curr_") or data.startswith("approve_"):
        is_new_chat = data.startswith("approve_new_")
        task_id = data.replace("approve_new_", "").replace("approve_curr_", "").replace("approve_", "")
        task = task_analyzer.pending_tasks.get(task_id)
        if not task:
            await query.edit_message_text("⚠️ Görev bulunamadı veya süresi doldu.")
            return

        safe_prompt = html.escape(str(task['prompt']))
        safe_role = html.escape(str(task['role']))
        chat_mode_text = "Yeni Sohbet Açılarak" if is_new_chat else "Mevcut Sohbet Üzerinden"

        await query.edit_message_text(
            f"⏳ <b>Görev Onaylandı! Antigravity IDE Devrede ({chat_mode_text})...</b>\n\n"
            f"🎯 <b>Görev:</b> \"{safe_prompt}\"\n"
            f"🏷️ <b>Sorumlu:</b> {safe_role}\n\n"
            f"🤖 <i>Antigravity IDE {chat_mode_text.lower()} görevi inceliyor ve dosyalarda düzenlemeleri yapıyor. Tamamlandığında buraya rapor iletilecektir.</i>",
            parse_mode=ParseMode.HTML,
        )

        # 1. Record task to .agents/task.md with unique tag
        task_tag = f"[ID:{task_id}]"
        try:
            ws = agent_runner.get_working_dir()
            task_file = ws / ".agents" / "task.md"
            if task_file.exists():
                content = task_file.read_text(encoding="utf-8")
                if "## 📥 Telegram'dan Gelen Onaylı Görevler" not in content:
                    content += "\n\n## 📥 Telegram'dan Gelen Onaylı Görevler\n"
                content += f"- [ ] {task_tag} {task['prompt']} ({task['role']})\n"
                task_file.write_text(content, encoding="utf-8")
        except Exception as e:
            logger.error(f"Task kayıt hatası: {e}")

        # 2. Log real task in terminal and task.md
        print(f"\n" + "=" * 60, flush=True)
        print(f"📥 [TELEGRAM_GÖREVİ_KAYDEDİLDİ]:", flush=True)
        print(f"   ID    : {task_id}", flush=True)
        print(f"   GÖREV : {task['prompt']}", flush=True)
        print(f"   ROL   : {task['role']}", flush=True)
        print("=" * 60 + "\n", flush=True)

        # 3. Attempt IDE GUI focus injection if on desktop
        injected = ide_automation.send_task_to_ide(task['prompt'], new_chat=is_new_chat)

        if injected:
            await update.effective_message.reply_text(
                f"✅ <b>Görev Antigravity IDE Sohbetine Yazıldı!</b>\n\n"
                f"🎯 <b>Görev:</b> \"{safe_prompt}\"\n\n"
                f"📌 Görev IDE ekranınıza aktarıldı. Ajanın oluşturduğu kodları ve test sonuçlarını IDE arayüzünden canlı takip edebilirsiniz.",
                reply_markup=build_main_keyboard(),
                parse_mode=ParseMode.HTML,
            )
        else:
            await update.effective_message.reply_text(
                f"📋 <b>Görev Görev Listesine (.agents/task.md) Eklendi!</b>\n\n"
                f"🎯 <b>Görev:</b> \"{safe_prompt}\"\n"
                f"🏷️ <b>Sorumlu:</b> {safe_role}\n\n"
                f"💡 Antigravity IDE sohbetine <code>taskları yap</code> yazarak görevi hemen işletebilirsiniz.",
                reply_markup=build_main_keyboard(),
                parse_mode=ParseMode.HTML,
            )

    elif data.startswith("cancel_"):
        task_id = data.replace("cancel_", "")
        task_analyzer.pending_tasks.pop(task_id, None)
        await query.edit_message_text(
            "🚫 <b>Görev İptal Edildi.</b>\n\nHiçbir değişiklik uygulanmadı.",
            parse_mode=ParseMode.HTML,
        )


@restricted
async def handle_text_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Analyze incoming Telegram tasks, generate plan and request user approval."""
    text = update.effective_message.text.strip()
    if text.startswith("/"):
        return  # Already handled by command handlers

    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action=ChatAction.TYPING)

    # 1. Perform impact & domain analysis
    task = task_analyzer.analyze_incoming_task(text)
    analysis_text = task_analyzer.format_analysis_message(task)

    # 2. Build Approval Inline Keyboard with New Chat vs Current Chat options
    approval_keyboard = InlineKeyboardMarkup(
        [
            [
                InlineKeyboardButton("🆕 Yeni Sohbette Başlat", callback_data=f"approve_new_{task['id']}"),
            ],
            [
                InlineKeyboardButton("💬 Mevcut Sohbetten Devam Et", callback_data=f"approve_curr_{task['id']}"),
            ],
            [
                InlineKeyboardButton("❌ İptal Et", callback_data=f"cancel_{task['id']}"),
            ]
        ]
    )

    # 3. Send analysis plan with approval buttons
    await update.effective_message.reply_text(
        analysis_text,
        reply_markup=approval_keyboard,
        parse_mode=ParseMode.HTML,
    )


async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Log the error gracefully and notify user if possible."""
    err = context.error
    err_str = str(err)

    # 1. Handle transient network errors and DNS timeouts silently
    if (
        isinstance(err, (NetworkError, TimedOut))
        or "ConnectError" in err_str
        or "getaddrinfo" in err_str
        or "timeout" in err_str.lower()
    ):
        logger.warning(f"🌐 Geçici ağ/DNS kesintisi algılandı: {err}. Otomatik yeniden bağlanılıyor...")
        return

    # 2. Handle 409 Conflict
    if isinstance(err, Conflict) or "Conflict" in err_str:
        logger.warning("⚠️ Başka bir bot oturumu tespit edildi (Conflict).")
        return

    # 3. Log real internal errors and attempt to notify
    logger.error("Telegram güncellemesinde hata oluştu:", exc_info=err)
    if isinstance(update, Update) and update.effective_message:
        try:
            safe_err = html.escape(err_str)
            await update.effective_message.reply_text(
                f"⚠️ <b>İşlem sırasında bir hata oluştu:</b>\n<code>{safe_err}</code>",
                parse_mode=ParseMode.HTML,
            )
        except Exception:
            pass


def main():
    """Main application entry point."""
    print("=" * 60)
    print("  🚀 HOPPA REMOTE AGENT BRIDGE")
    print("=" * 60)

    if not settings.is_configured:
        print("\n⚠️ [UYARI] TELEGRAM_BOT_TOKEN yapılandırılmamış veya varsayılan değerde.")
        print("Lütfen 'agent-remote-bridge/.env' dosyasını açıp BotFather'dan aldığınız token'ı ve Telegram User ID'nizi girin:")
        print("  TELEGRAM_BOT_TOKEN=\"123456:ABC-DEF...\"")
        print("  ALLOWED_USER_ID=123456789\n")
        print("[INIT] Remote Agent Bridge dinleniyor... (Yapılandırma bekleniyor)")
        return

    allowed_ids = settings.allowed_user_ids
    print(f"📂 Çalışma Dizini   : {settings.AGENT_WORKING_DIR}")
    print(f"🔐 Yetkili ID(ler)   : {list(allowed_ids) if allowed_ids else 'YOK (Tüm erişimler engellenecek)'}")
    print("------------------------------------------------------------")
    print("[INIT] Remote Agent Bridge dinleniyor...")
    print("------------------------------------------------------------")

    try:
        request_config = HTTPXRequest(
            connect_timeout=30.0,
            read_timeout=30.0,
            write_timeout=30.0,
            pool_timeout=30.0,
            connection_pool_size=10,
        )

        app = (
            Application.builder()
            .token(settings.TELEGRAM_BOT_TOKEN)
            .request(request_config)
            .build()
        )

        # Error Handler
        app.add_error_handler(error_handler)

        # Command Handlers
        app.add_handler(CommandHandler("start", cmd_start))
        app.add_handler(CommandHandler("help", cmd_help))
        app.add_handler(CommandHandler("status", cmd_status))
        app.add_handler(CommandHandler("flutter_analyze", cmd_flutter_analyze))
        app.add_handler(CommandHandler("backend_check", cmd_backend_check))
        app.add_handler(CommandHandler("web_build", cmd_web_build))
        app.add_handler(CommandHandler("prisma_check", cmd_prisma_check))
        app.add_handler(CommandHandler("git_status", cmd_git_status))
        app.add_handler(CommandHandler("run", cmd_run))

        # Inline Button Callback Handler
        app.add_handler(CallbackQueryHandler(handle_callback_query))

        # Plain Text Message Handler
        app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text_message))

        # Start Polling with automatic infinite reconnects
        app.run_polling(
            drop_pending_updates=True,
            bootstrap_retries=-1,
            timeout=30,
        )

    except Exception as exc:
        logger.exception(f"Kritik Bot Hatası: {exc}")
        print(f"❌ Hata: {exc}")


if __name__ == "__main__":
    main()

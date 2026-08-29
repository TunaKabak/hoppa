import asyncio
import os
import platform
import subprocess
import logging
from pathlib import Path
from typing import Optional, List, Tuple
from config import settings

logger = logging.getLogger("RemoteBridge.Runner")


def get_working_dir(sub_path: Optional[str] = None) -> Path:
    """Resolve absolute path within the configured AGENT_WORKING_DIR."""
    base = Path(settings.AGENT_WORKING_DIR).resolve()
    if sub_path:
        return (base / sub_path).resolve()
    return base


def chunk_text(text: str, max_chars: int = 3800) -> List[str]:
    """Split text into chunks that fit inside Telegram's 4096 char limit."""
    if not text:
        return ["(Boş çıktı)"]
    
    chunks = []
    lines = text.splitlines(keepends=True)
    current_chunk = ""

    for line in lines:
        if len(current_chunk) + len(line) > max_chars:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = line
        else:
            current_chunk += line

    if current_chunk:
        chunks.append(current_chunk)

    return chunks if chunks else ["(Boş çıktı)"]


async def run_async_command(
    command: str,
    cwd: Optional[str] = None,
    timeout: Optional[int] = None,
) -> Tuple[int, str, str]:
    """
    Execute a shell command asynchronously in the specified directory.
    Returns (returncode, stdout, stderr).
    """
    working_dir = Path(cwd).resolve() if cwd else get_working_dir()
    actual_timeout = timeout or settings.COMMAND_TIMEOUT

    logger.info(f"🚀 Çalıştırılıyor: '{command}' (Dizin: {working_dir})")

    try:
        # Use powershell on Windows or default shell on Unix
        if platform.system() == "Windows":
            process = await asyncio.create_subprocess_shell(
                f'powershell.exe -NoProfile -NonInteractive -Command "{command}"',
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(working_dir),
            )
        else:
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(working_dir),
            )

        try:
            stdout_bytes, stderr_bytes = await asyncio.wait_for(
                process.communicate(),
                timeout=actual_timeout,
            )
            stdout = stdout_bytes.decode("utf-8", errors="replace").strip()
            stderr = stderr_bytes.decode("utf-8", errors="replace").strip()
            returncode = process.returncode if process.returncode is not None else 0
            return returncode, stdout, stderr

        except asyncio.TimeoutError:
            try:
                process.kill()
            except Exception:
                pass
            logger.error(f"⏱️ Komut zaman aşımına uğradı ({actual_timeout}s): {command}")
            return -1, "", f"Komut zaman aşımına uğradı ({actual_timeout} saniye)."

    except Exception as exc:
        logger.exception(f"Komut çalıştırma hatası: {exc}")
        return 1, "", f"Hata oluştu: {str(exc)}"


import html

async def get_system_info() -> str:
    """Gather diagnostic info about the Hoppa workspace and environment."""
    ws = get_working_dir()
    os_info = f"{platform.system()} {platform.release()} ({platform.machine()})"
    
    # Git info
    git_code, git_branch, _ = await run_async_command("git branch --show-current", cwd=str(ws))
    git_code2, git_last, _ = await run_async_command("git log -1 --format='%h - %s (%cr)'", cwd=str(ws))
    
    branch = git_branch.strip() if git_code == 0 and git_branch else "Bilinmiyor"
    last_commit = git_last.strip() if git_code2 == 0 and git_last else "Commit bulunamadı"

    return (
        f"📊 <b>Hoppa Proje Durumu</b>\n\n"
        f"📂 <b>Çalışma Dizini:</b> <code>{html.escape(str(ws))}</code>\n"
        f"💻 <b>İşletim Sistemi:</b> <code>{html.escape(os_info)}</code>\n"
        f"🌿 <b>Aktif Git Dalı:</b> <code>{html.escape(branch)}</code>\n"
        f"🔖 <b>Son Commit:</b> <code>{html.escape(last_commit)}</code>\n"
        f"⏱️ <b>Varsayılan Zaman Aşımı:</b> <code>{settings.COMMAND_TIMEOUT}s</code>"
    )


async def run_flutter_analyze() -> Tuple[int, str]:
    """Run flutter analyze across the project."""
    ws = get_working_dir()
    code, stdout, stderr = await run_async_command("flutter analyze", cwd=str(ws), timeout=180)
    out = stdout if stdout else stderr
    return code, out or "Flutter analyze tamamlandı."


async def run_backend_check() -> Tuple[int, str]:
    """Run npx tsc --noEmit in backend directory."""
    backend_dir = get_working_dir("backend")
    code, stdout, stderr = await run_async_command("npx tsc --noEmit", cwd=str(backend_dir), timeout=120)
    out = stdout if stdout else stderr
    if code == 0 and not out:
        out = "✅ TypeScript derleme doğrulaması başarılı! (0 Hata)"
    return code, out


async def run_web_build() -> Tuple[int, str]:
    """Run npm run build in apps/web_app directory."""
    web_dir = get_working_dir("apps/web_app")
    code, stdout, stderr = await run_async_command("npm run build", cwd=str(web_dir), timeout=300)
    out = stdout if stdout else stderr
    return code, out or "Web derlemesi tamamlandı."


async def run_prisma_check() -> Tuple[int, str]:
    """Run prisma validate in backend directory."""
    backend_dir = get_working_dir("backend")
    code, stdout, stderr = await run_async_command("npx prisma validate", cwd=str(backend_dir), timeout=60)
    out = stdout if stdout else stderr
    return code, out or "Prisma şeması geçerli."


async def get_git_status() -> Tuple[int, str]:
    """Get concise git status and diff count."""
    ws = get_working_dir()
    code, stdout, stderr = await run_async_command("git status -s", cwd=str(ws), timeout=30)
    out = stdout if stdout else stderr
    if code == 0 and not out.strip():
        out = "✅ Çalışma ağacı temiz (Working tree clean - Değişiklik yok)."
    return code, out

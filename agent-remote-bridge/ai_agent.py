import os
import sys
import html
import asyncio
import logging
from pathlib import Path
from typing import Dict, Any, List, Optional
from google import genai
from google.genai import types

from config import settings
import agent_runner

logger = logging.getLogger("RemoteBridge.AIAgent")


def _get_abs_path(rel_path: str) -> Path:
    """Resolve a relative path against the Hoppa workspace root."""
    ws = agent_runner.get_working_dir()
    clean = rel_path.strip().lstrip("/\\")
    return (ws / clean).resolve()


# Workspace Tools
def read_file(file_path: str, start_line: int = 1, line_count: int = 200) -> str:
    """Read contents of a file within the Hoppa workspace with line numbers."""
    try:
        path = _get_abs_path(file_path)
        if not path.exists() or not path.is_file():
            return f"HATA: Dosya bulunamadı: {file_path}"
        
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        start_idx = max(0, start_line - 1)
        end_idx = min(len(lines), start_idx + line_count)
        
        numbered = [f"{i+1:4d}: {lines[i]}" for i in range(start_idx, end_idx)]
        return "\n".join(numbered) if numbered else "(Boş dosya veya geçersiz satır aralığı)"
    except Exception as e:
        return f"HATA: {e}"


def replace_file_content(file_path: str, target_content: str, replacement_content: str) -> str:
    """Replace an exact block of text in a file with new content."""
    try:
        path = _get_abs_path(file_path)
        if not path.exists() or not path.is_file():
            return f"HATA: Dosya bulunamadı: {file_path}"
        
        content = path.read_text(encoding="utf-8")
        if target_content not in content:
            return f"HATA: 'target_content' dosyada birebir bulunamadı. Lütfen önce read_file ile tam eşleşmeyi kontrol edin."
        
        # Replace only once
        new_content = content.replace(target_content, replacement_content, 1)
        path.write_text(new_content, encoding="utf-8")
        return f"BAŞARILI: {file_path} dosyası güncellendi."
    except Exception as e:
        return f"HATA: {e}"


def write_file(file_path: str, content: str) -> str:
    """Create or overwrite a file with given content."""
    try:
        path = _get_abs_path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return f"BAŞARILI: {file_path} dosyası oluşturuldu/yazıldı."
    except Exception as e:
        return f"HATA: {e}"


def grep_search(query: str, search_path: str = "") -> str:
    """Search for a text pattern across files in the workspace."""
    try:
        ws = agent_runner.get_working_dir()
        target_dir = (ws / search_path.strip().lstrip("/\\")) if search_path else ws
        
        matches = []
        for p in target_dir.rglob("*"):
            if p.is_file() and not any(part in p.parts for part in [".git", "node_modules", ".dart_tool", "venv", "build", ".next", ".idea"]):
                try:
                    text = p.read_text(encoding="utf-8", errors="ignore")
                    if query.lower() in text.lower():
                        rel = p.relative_to(ws)
                        matches.append(str(rel))
                        if len(matches) >= 15:
                            break
                except Exception:
                    continue
        return f"Bulunan Dosyalar ({len(matches)}):\n" + "\n".join(matches) if matches else "Eşleşen dosya bulunamadı."
    except Exception as e:
        return f"HATA: {e}"


def list_directory(directory_path: str = "") -> str:
    """List files and directories in a given workspace path."""
    try:
        path = _get_abs_path(directory_path)
        if not path.exists():
            return f"HATA: Dizin bulunamadı: {directory_path}"
        items = []
        for p in path.iterdir():
            if p.name not in [".git", "node_modules", "venv", ".dart_tool", ".next"]:
                prefix = "📁 " if p.is_dir() else "📄 "
                items.append(f"{prefix}{p.name}")
        return "\n".join(sorted(items)[:40])
    except Exception as e:
        return f"HATA: {e}"


def run_terminal_command(command: str) -> str:
    """Execute a shell command (e.g. flutter analyze, npx tsc, npm run build) in workspace."""
    try:
        ws = agent_runner.get_working_dir()
        code, stdout, stderr = asyncio.run(agent_runner.run_async_command(command, cwd=str(ws), timeout=180))
        out = stdout if stdout else stderr
        return f"Çıkış Kodu: {code}\n{out}"
    except Exception as e:
        return f"HATA: {e}"


SYSTEM_INSTRUCTION = """
Sen Hoppa Monorepo projesinin Kıdemli Otonom Yazılım Mühendisi Ajanısın.
Kullanıcı Telegram üzerinden bir geliştirme veya hata düzeltme görevi verdiğinde:
1. Önce `grep_search`, `list_directory` veya `read_file` araçlarıyla ilgili dosyaları incele.
2. Gerekli kod değişikliklerini `replace_file_content` veya `write_file` kullanarak eksiksiz uygula.
3. Değişiklikten sonra `run_terminal_command` ile doğrulama testlerini (örneğin web app için `npm run build`, flutter için `flutter analyze`, backend için `npx tsc --noEmit`) çalıştır.
4. Hata alırsan dosyayı tekrar inceleyip düzelt.
5. Görev başarıyla tamamlandığında yapılan değişikliklerin ve test sonucunun net, Türkçe bir özet raporunu sun.
"""


async def execute_autonomous_task(prompt: str, progress_callback=None) -> str:
    """
    Execute a natural language task end-to-end using the Gemini Agent loop with workspace tools.
    """
    api_key = settings.GEMINI_API_KEY.strip().strip('"').strip("'") or os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        return (
            "⚠️ <b>GEMINI_API_KEY Eksik!</b>\n\n"
            "Otonom kod yazma ve düzenleme yapabilmem için <code>agent-remote-bridge/.env</code> dosyasına "
            "Google AI Studio'dan aldığınız ücretsiz API Key'i ekleyin:\n"
            "<code>GEMINI_API_KEY=\"AIzaSy...\"</code>"
        )

    try:
        client = genai.Client(api_key=api_key)
        
        tools = [
            read_file,
            replace_file_content,
            write_file,
            grep_search,
            list_directory,
            run_terminal_command,
        ]

        if progress_callback:
            await progress_callback("🔍 <b>Ajan Başlatıldı:</b> Görev ve çalışma alanı analiz ediliyor...")

        chat = client.chats.create(
            model="gemini-2.5-flash",
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_INSTRUCTION,
                tools=tools,
                temperature=0.2,
            )
        )

        response = chat.send_message(f"GÖREV: {prompt}")

        # The SDK automatically handles function calling execution with tools list when using client.chats!
        # Let's extract the final text output:
        return response.text or "✅ Görev otonom olarak işlendi ve tamamlandı."

    except Exception as exc:
        logger.exception("Otonom ajan çalışma hatası:")
        return f"❌ <b>Ajan Hatası:</b>\n<code>{html.escape(str(exc))}</code>"

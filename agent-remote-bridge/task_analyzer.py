import uuid
import json
import html
import logging
from pathlib import Path
from typing import Dict, Any, List, Optional
import agent_runner

logger = logging.getLogger("RemoteBridge.Analyzer")

# In-memory storage for pending tasks awaiting user approval
pending_tasks: Dict[str, Dict[str, Any]] = {}


def detect_agent_role(text: str) -> str:
    """Determine responsible agent role based on prompt keywords."""
    lowered = text.lower()
    if any(k in lowered for k in ["flutter", "dart", "consumer", "mobil", "ekran", "widget", "sayfa", "ui"]):
        return "🎨 Frontend Agent (Flutter / Dart)"
    elif any(k in lowered for k in ["backend", "api", "controller", "route", "servis", "express", "ts", "node"]):
        return "⚙️ Backend Agent (Node.js / TypeScript)"
    elif any(k in lowered for k in ["prisma", "veritabanı", "database", "tablo", "şema", "sql", "migration"]):
        return "🗄️ Database & Infra Agent (Prisma / DB)"
    elif any(k in lowered for k in ["test", "analyze", "hata", "ci/cd", "log", "güvenlik", "lint"]):
        return "🛡️ QA & Security Agent (Test & Kalite)"
    elif any(k in lowered for k in ["tasarım", "renk", "gradient", "logo", "ikon", "header", "spacing"]):
        return "🎨 Designer Agent (UI/UX Tasarım)"
    return "🔍 Planner & Analyzer Agent (Genel Görev)"


def find_relevant_files(text: str) -> List[str]:
    """Identify potentially related files/directories in Hoppa workspace based on prompt."""
    ws = agent_runner.get_working_dir()
    lowered = text.lower()
    relevant: List[str] = []

    # Domain mappings aligned with actual Hoppa structure
    mappings = {
        "sepet": ["apps/consumer_app/lib/apps/consumer/pages/checkout_page.dart", "backend/src/controllers/CartController.ts"],
        "sipariş": ["apps/consumer_app/lib/apps/consumer/pages/order_tracking_page.dart", "backend/src/controllers/OrderController.ts", "apps/web_app/src/components/merchant/orders/"],
        "satıcı": ["apps/merchant_app/lib/apps/merchant/", "apps/web_app/src/components/merchant/", "backend/src/controllers/ShopController.ts"],
        "kategori": ["backend/src/controllers/BusinessCategoryController.ts", "apps/consumer_app/lib/apps/consumer/pages/selection_category_page.dart"],
        "ödeme": ["apps/consumer_app/lib/apps/consumer/pages/payment_page.dart", "backend/src/controllers/PaymentController.ts"],
        "kurye": ["apps/courier_app/lib/apps/courier/", "backend/src/controllers/CourierController.ts"],
        "flutter": ["apps/consumer_app/", "packages/core_shared/", "pubspec.yaml"],
        "backend": ["backend/src/routes/", "backend/src/controllers/"],
        "prisma": ["backend/prisma/schema.prisma"],
        "web": ["apps/web_app/src/pages/", "apps/web_app/src/components/"],
    }

    for key, paths in mappings.items():
        if key in lowered:
            for p in paths:
                if (ws / p).exists() and p not in relevant:
                    relevant.append(p)

    if not relevant:
        relevant.append("Monorepo Çalışma Alanı (Genel)")

    return relevant[:4]


def analyze_incoming_task(prompt: str) -> Dict[str, Any]:
    """
    Perform impact and domain analysis for a task sent via Telegram.
    Generates a structured plan and returns task payload with a unique ID.
    """
    task_id = str(uuid.uuid4())[:8]
    agent_role = detect_agent_role(prompt)
    files = find_relevant_files(prompt)

    # Determine recommended validation step
    if "backend" in prompt.lower() or "api" in prompt.lower() or "controller" in prompt.lower():
        validation_step = "npx tsc --noEmit (Backend TypeScript Derleme Doğrulaması)"
    elif "web" in prompt.lower():
        validation_step = "npm run build (apps/web_app Next.js Derleme Doğrulaması)"
    elif "prisma" in prompt.lower() or "veritabanı" in prompt.lower():
        validation_step = "npx prisma validate (Prisma Şema Kontrolü)"
    else:
        validation_step = "flutter analyze (Flutter Statik Kod Analizi)"

    task_payload = {
        "id": task_id,
        "prompt": prompt,
        "role": agent_role,
        "files": files,
        "validation": validation_step,
        "status": "pending_approval",
    }

    pending_tasks[task_id] = task_payload
    return task_payload


def format_analysis_message(task: Dict[str, Any]) -> str:
    """Format the task analysis as robust HTML message."""
    safe_prompt = html.escape(str(task["prompt"]))
    safe_role = html.escape(str(task["role"]))
    safe_validation = html.escape(str(task["validation"]))
    
    files_list = "\n".join([f"  • <code>{html.escape(f)}</code>" for f in task["files"]])
    
    return (
        f"📋 <b>GÖREV ANALİZİ &amp; UYGULAMA PLANI</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━━\n"
        f"🎯 <b>Görev:</b> \"{safe_prompt}\"\n\n"
        f"🏷️ <b>Sorumlu Rol:</b> {safe_role}\n\n"
        f"📁 <b>Etkilenen/İlgili Alanlar:</b>\n{files_list}\n\n"
        f"🛠️ <b>Planlanan Adımlar:</b>\n"
        f"  1. İlgili kod bileşenlerinin incelenmesi\n"
        f"  2. Talep edilen mimari geliştirmelerin uygulanması\n"
        f"  3. Doğrulama testi: <code>{safe_validation}</code>\n\n"
        f"❓ <b>Bu planı onaylıyor musunuz?</b>"
    )

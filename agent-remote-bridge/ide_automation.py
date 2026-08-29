import subprocess
import html
import logging

logger = logging.getLogger("RemoteBridge.IDEAuto")


def send_task_to_ide(prompt: str, new_chat: bool = False) -> bool:
    """
    RPA - Automated GUI injection:
    Acts like a human typing into Antigravity IDE:
    1. Sets Windows clipboard to prompt.
    2. Activates the Antigravity IDE / Hoppa window.
    3. If new_chat is True, triggers shortcut (Ctrl+L) to open a fresh conversation.
    4. Simulates Ctrl+V and Enter keystrokes to send the message directly to IDE chat.
    """
    clean_prompt = prompt.replace("`", "``").replace('"', '`"')
    new_chat_flag = "$true" if new_chat else "$false"
    
    ps_code = f"""
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Clipboard]::SetText(@'
{prompt}
'@)
    
    $wshell = New-Object -ComObject WScript.Shell
    $targets = @("Antigravity", "Hoppa", "Visual Studio Code")
    $found = $false
    foreach ($t in $targets) {{
        if ($wshell.AppActivate($t)) {{
            $found = $true
            break
        }}
    }}
    
    if ($found) {{
        Start-Sleep -Milliseconds 400
        
        # If user requested a new chat, send Ctrl+L shortcut
        if ({new_chat_flag}) {{
            $wshell.SendKeys("^l")
            Start-Sleep -Milliseconds 400
        }}
        
        # Send Ctrl+V (Paste) and Enter
        $wshell.SendKeys("^v")
        Start-Sleep -Milliseconds 200
        $wshell.SendKeys("{{ENTER}}")
        Write-Output "SUCCESS"
    }} else {{
        Write-Output "WINDOW_NOT_FOUND"
    }}
    """
    try:
        proc = subprocess.run(
            ["powershell", "-STA", "-NoProfile", "-Command", ps_code],
            capture_output=True,
            text=True,
            timeout=10,
        )
        out = proc.stdout.strip()
        logger.info(f"IDE GUI Enjeksiyon Sonucu (Yeni Sohbet={new_chat}): {out}")
        return "SUCCESS" in out
    except Exception as e:
        logger.error(f"IDE GUI Enjeksiyon Hatası: {e}")
        return False

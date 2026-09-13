#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "正在启动丛雨 TTS WebUI..."
echo "启动后请在浏览器打开 http://localhost:7860"
echo "按 Ctrl+C 退出"
echo
if [ -f "$SCRIPT_DIR/.venv/bin/python" ]; then
    "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/webui.py" "$@"
else
    echo "[警告] 未找到 .venv，尝试使用系统 Python" >&2
    python3 "$SCRIPT_DIR/webui.py" "$@"
fi

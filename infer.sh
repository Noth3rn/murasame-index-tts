#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.venv/bin/python" ]; then
    "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/infer.py" "$@"
else
    echo "[警告] 未找到 .venv，尝试使用系统 Python" >&2
    python3 "$SCRIPT_DIR/infer.py" "$@"
fi

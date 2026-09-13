@echo off
chcp 65001 >nul
echo 正在启动丛雨 TTS WebUI...
echo 启动后请在浏览器打开 http://localhost:7860
echo 按 Ctrl+C 退出
echo.
if exist .venv\Scripts\python.exe (
    .venv\Scripts\python.exe webui.py %*
) else (
    echo [警告] 未找到 .venv，尝试使用系统 Python
    python webui.py %*
)

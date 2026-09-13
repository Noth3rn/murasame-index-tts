@echo off
chcp 65001 >nul
if exist .venv\Scripts\python.exe (
    .venv\Scripts\python.exe infer.py %*
) else (
    echo [警告] 未找到 .venv，尝试使用系统 Python（可能缺少依赖）
    python infer.py %*
)

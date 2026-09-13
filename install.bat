@echo off
chcp 65001 >nul
echo ============================================================
echo  丛雨 TTS — 安装脚本 (Windows)
echo ============================================================
echo.

:: 检查 Python 版本
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 Python，请先安装 Python 3.10 或 3.11。
    echo 下载地址：https://www.python.org/downloads/
    pause
    exit /b 1
)

for /f "tokens=2" %%v in ('python --version 2^>^&1') do set PY_VER=%%v
echo 检测到 Python %PY_VER%

:: 创建虚拟环境
echo.
echo [1/4] 创建虚拟环境 .venv ...
python -m venv .venv
if errorlevel 1 (
    echo [错误] 创建虚拟环境失败。
    pause
    exit /b 1
)

:: 升级 pip
echo.
echo [2/4] 升级 pip ...
.venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel

:: 安装 PyTorch (CUDA 12.8)
echo.
echo [3/4] 安装 PyTorch 2.8 (CUDA 12.8) ...
echo 正在从 PyTorch 官方源下载，文件较大（约 2-3 GB），请耐心等待...
.venv\Scripts\pip.exe install torch torchaudio --index-url https://download.pytorch.org/whl/cu128
if errorlevel 1 (
    echo [错误] PyTorch 安装失败。请检查网络连接。
    pause
    exit /b 1
)

:: 安装其余依赖
echo.
echo [4/4] 安装其余依赖 ...
.venv\Scripts\pip.exe install -r requirements.txt
if errorlevel 1 (
    echo [错误] 依赖安装失败。
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  安装完成！
echo.
echo  使用方式：
echo    infer.bat "ご主人、今日もよろしく。" -o out.wav
echo    webui.bat
echo ============================================================
pause

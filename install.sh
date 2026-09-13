#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " 丛雨 TTS — 安装脚本 (Linux / macOS)"
echo "============================================================"
echo

# 检查 Python
if ! command -v python3 &>/dev/null; then
    echo "[错误] 未找到 python3，请先安装 Python 3.10 或 3.11。"
    exit 1
fi

PY_VER=$(python3 --version 2>&1 | cut -d' ' -f2)
echo "检测到 Python $PY_VER"

# 创建虚拟环境
echo
echo "[1/4] 创建虚拟环境 .venv ..."
python3 -m venv .venv

# 激活
source .venv/bin/activate

# 升级 pip
echo
echo "[2/4] 升级 pip ..."
pip install --upgrade pip setuptools wheel

# 安装 PyTorch (CUDA 12.8)
echo
echo "[3/4] 安装 PyTorch 2.8 (CUDA 12.8) ..."
echo "正在从 PyTorch 官方源下载（约 2-3 GB），请耐心等待..."
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu128

# macOS (Apple Silicon) 用户请改为：
#   pip install torch torchaudio

# 安装其余依赖
echo
echo "[4/4] 安装其余依赖 ..."
pip install -r requirements.txt

echo
echo "============================================================"
echo " 安装完成！"
echo
echo " 使用方式："
echo '   bash infer.sh "ご主人、今日もよろしく。" -o out.wav'
echo "   bash webui.sh"
echo "============================================================"

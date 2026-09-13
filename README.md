# 丛雨 TTS

基于 [IndexTTS 2.5](https://github.com/index-tts/index-tts) 微调的丛雨声音模型，支持日文与中文 TTS 推理。

> **Derivative Work Notice（衍生作品声明）**  
> Any modifications made to the original model in this Derivative Work are not endorsed,
> warranted, or guaranteed by the original right-holder of the original model, and the
> original right-holder disclaims all liability related to this Derivative Work.

---

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10/11（PowerShell 5.1+）或 Linux |
| GPU | NVIDIA（显存 ≥ 8 GB，推荐 16 GB） |
| CUDA | 12.x |
| Python | 3.10 或 3.11（不支持 3.12+） |
| 磁盘空间 | 约 10 GB（模型文件 + 依赖） |

> **macOS**：Apple Silicon 可运行，但需修改 `install.sh` 中的 torch 安装命令（去掉 `--index-url`），推理速度较慢。

---

## 快速开始

### 1. 克隆代码

```bash
git clone https://github.com/Noth3rn/murasame-index-tts.git
cd murasame-index-tts
```

### 2. 下载模型权重

模型权重托管在 Hugging Face，需单独下载后放入 `checkpoints/` 目录。

**方式一：hf 命令行（推荐）**

```bash
pip install huggingface_hub
hf download Noth3rnY/murasame-index-tts-weights --local-dir ./checkpoints
```

**方式二：手动下载**

前往 [https://huggingface.co/Noth3rnY/murasame-index-tts-weights](https://huggingface.co/Noth3rnY/murasame-index-tts-weights)，下载以下文件放入 `checkpoints/` 目录：

```
checkpoints/
├── gpt.pth                    ← 微调主模型（3.1 GB）
├── codec.pth                  ← 编解码器（579 MB）
├── s2mel.pth                  ← mel 生成（396 MB）
└── hf_cache/
    ├── bigvgan/
    │   └── bigvgan_generator.pt   ← 声码器（428 MB）
    ├── campplus_cn_common.bin     ← 说话人编码器（27 MB）
    ├── semantic_codec_model.safetensors
    └── semantic_codec/
        └── model.safetensors
```

**可选：WebUI 的情感描述模型**

WebUI 的「用情感描述文本控制」需要额外的 Qwen 情感模型（约 1.2 GB），不在上面的权重里：

```bash
hf download IndexTeam/IndexTTS-2.5 --include "qwen0.6bemo4-merge/*" --local-dir ./checkpoints
```

不下也能正常使用 WebUI 和命令行推理，只是该功能不可用（启动时会提示）。

### 3. 安装依赖

**Windows（PowerShell）：**
```powershell
.\install.ps1
```

> `install.ps1` 会依次尝试 `python`、`py -3.11`、`py -3.10`、uv 安装的 Python、`py -3`
> 寻找可用的解释器，并自动跳过 Microsoft Store 的 `python.exe` 占位符。
> 若只找到 3.10 / 3.11 以外的版本（如 3.14），脚本会直接报错退出 —— 本项目的
> `pydantic-core`、`kaldifst` 在新版 Python 上没有预编译 wheel，会退回源码编译并失败。
>
> 常用参数：
> | 参数 | 说明 |
> |------|------|
> | `-Python <路径>` | 显式指定解释器，跳过自动探测 |
> | `-RecreateVenv` | `.venv` 由其他 Python 版本创建时，删除并重建 |
> | `-AllowUnsupportedPython` | 强行用 3.10 / 3.11 以外的版本安装（不推荐） |
> | `-NoPause` | 结束后不等待回车 |
>
> 若提示「无法加载文件……因为在此系统上禁止运行脚本」，说明执行策略不允许运行脚本，改用：
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\install.ps1
> ```

**Linux / macOS：**
```bash
bash install.sh
```

脚本会自动创建 `.venv` 虚拟环境，安装 PyTorch 2.8（CUDA 12.8）及所有推理依赖，**首次约需 10–20 分钟**。

---

## 使用

### 命令行推理

**Windows（PowerShell）：**
```powershell
.\infer.ps1 "ご主人、今日もよろしく。" -o out.wav
```

**Linux / macOS：**
```bash
bash infer.sh "ご主人、今日もよろしく。" -o out.wav
```

> 输出文件路径相对于当前工作目录，建议在项目根目录下运行。

**直接调用 Python（已激活 .venv）：**
```bash
python infer.py "ご主人、今日もよろしく。" -o out.wav
```

#### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `text` | 要合成的文本（必填） | — |
| `--lang ZH/JA` | 指定语言（不填则自动检测） | 自动 |
| `--ref <路径>` | 参考音频（可替换为自己的录音） | `checkpoints/reference.ogg` |
| `--out / -o <路径>` | 输出文件路径 | `output.wav` |
| `--seed <整数>` | 随机种子（固定可复现） | `42` |
| `--model-dir <路径>` | 模型目录 | `./checkpoints` |

#### 示例

```bash
# 日文（自动检测）
python infer.py "うむ、任せよ。" -o ja.wav

# 中文（指定语言）
python infer.py "主人，今天天气真好。" --lang ZH -o zh.wav

# 使用自定义参考音频
python infer.py "..." --ref my_voice.wav -o out.wav
```

### WebUI（图形界面）

**Windows（PowerShell）：**
```powershell
.\webui.ps1
```

**Linux / macOS：**
```bash
bash webui.sh
```

启动后在浏览器打开 **http://localhost:7860** ，可在界面中上传参考音频、输入文本、实时试听。

---

## 语言支持

| 语言 | 参数 | 自动检测规则 |
|------|------|------------|
| 日文 | `--lang JA` | 含假名（ひらがな・カタカナ）→ JA |
| 中文 | `--lang ZH` | 纯汉字（无假名）→ ZH |

混合中日文本建议手动指定 `--lang`。

---

## 关于模型

- **基础模型**：[IndexTTS 2.5](https://github.com/index-tts/index-tts)（bilibili indextts2）
- **微调方法**：LoRA（rank=8，alpha=16，作用于最后 8 层 Transformer）
- **训练数据**：角色丛雨的游戏语音
- **最优 checkpoint**：step600（训练损失 5.76）
- **主要语言**：日文，同时支持中文
- **本仓库改动**：仅替换 `gpt.pth`，引擎代码（`indextts/`）与基础模型权重来自原项目

---

## 目录结构

```
murasame-index-tts/
├── checkpoints/           模型文件（需从 Hugging Face 下载大权重）
│   ├── gpt.pth            *微调主模型（需下载）
│   ├── codec.pth          *编解码器（需下载）
│   ├── s2mel.pth          *mel 生成（需下载）
│   ├── hf_cache/          *辅助模型（需下载）
│   ├── qwen0.6bemo4-merge/ *Qwen 情感模型（WebUI 可选，需下载）
│   ├── feat1.pt           说话人矩阵（随代码分发）
│   ├── feat2.pt           情感矩阵（随代码分发）
│   ├── config.yaml        模型配置
│   ├── pinyin.vocab       拼音词表
│   ├── reference.ogg      参考音频（角色声纹样本）
│   └── multilingual_zh_ja_yue_char_del.tiktoken
├── indextts/              IndexTTS 推理引擎（来自原项目）
├── tools/                 WebUI 多语言支持（来自原项目）
├── infer.py               命令行推理入口
├── webui.py               WebUI 入口
├── examples/              WebUI 示例（cases.jsonl 随仓库分发，示例音频首次启动时自动下载）
├── install.ps1 / .sh      安装脚本
├── infer.ps1 / .sh        推理快捷脚本
└── webui.ps1 / .sh        WebUI 快捷启动
```

---

## 常见问题

**Q：运行时报 `CUDA out of memory`**  
A：显存不足，关闭其他 GPU 程序；或修改 `infer.py` 中 `use_bf16=True` 改为 `False` 降低显存占用。

**Q：安装 torch 失败 / 网速太慢**  
A：可从 https://pytorch.org/get-started/locally/ 手动下载对应 wheel 文件后本地安装。

**Q：语音质量不理想**  
A：尝试更清晰的参考音频（`--ref`），或调整 `--seed` 多生成几次。

**Q：提示「无法加载文件 …… 在此系统上禁止运行脚本」**  
A：这是 PowerShell 的执行策略限制。用 `powershell -ExecutionPolicy Bypass -File .\install.ps1` 运行，
或一次性放行当前用户：
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**Q：Windows 下日文 / 中文显示乱码**  
A：脚本会自动把控制台切到 UTF-8，建议使用 Windows Terminal 或 PowerShell 7。旧版控制台可在标题栏
右键「属性」中换成支持中日文的字体（如 MS Gothic、更纱黑体）。

---

## 开源协议

本项目为 IndexTTS 2.5（bilibili indextts2）的衍生作品，遵循 **bilibili Model Use License Agreement**，详见 [LICENSE](./LICENSE)。

- **仅供个人学习与研究使用，禁止商业用途。**
- 微调模型中使用的角色语音数据，版权归原版权方所有。
- 本仓库作者不对任何第三方声音模拟行为承担责任。

---
license: other
license_name: bilibili-model-use-license
license_link: https://github.com/index-tts/index-tts/blob/main/LICENSE
language:
- ja
- zh
tags:
- text-to-speech
- tts
- fine-tuned
- indextts
- lora
- japanese
- chinese
base_model: index-tts/index-tts
pipeline_tag: text-to-speech
---

# 丛雨 TTS — Model Weights

Fine-tuned model weights for [murasame-index-tts](https://github.com/Noth3rn/murasame-index-tts),
a TTS voice pack based on **IndexTTS 2.5** (bilibili indextts2).

> **Derivative Work Notice**  
> Any modifications made to the original model in this Derivative Work are not endorsed,
> warranted, or guaranteed by the original right-holder of the original model, and the
> original right-holder disclaims all liability related to this Derivative Work.

---

## Files

| 文件 | 说明 | 大小 |
|------|------|------|
| `gpt.pth` | 微调主模型（LoRA step600） | 3.1 GB |
| `codec.pth` | 编解码器（来自原项目） | 579 MB |
| `s2mel.pth` | Mel 生成模块（来自原项目） | 396 MB |
| `hf_cache/bigvgan/bigvgan_generator.pt` | BigVGAN 声码器 | 428 MB |
| `hf_cache/campplus_cn_common.bin` | 说话人编码器 | 27 MB |
| `hf_cache/semantic_codec_model.safetensors` | 语义编解码器 | 169 MB |
| `hf_cache/semantic_codec/model.safetensors` | 语义编解码器（副本） | 169 MB |

小型辅助文件（`feat1.pt`, `feat2.pt`, `config.yaml`, `reference.ogg` 等）随代码仓库分发，无需从此处下载。

---

## Usage

### 下载

```bash
pip install huggingface_hub
hf download Noth3rn/murasame-index-tts-weights --local-dir ./checkpoints
```

### 推理

```bash
# 克隆代码并安装依赖
git clone https://github.com/Noth3rn/murasame-index-tts.git
cd murasame-index-tts
install.bat  # Windows
# bash install.sh  # Linux

# 命令行推理
python infer.py "ご主人、今日もよろしく。" -o out.wav
```

详细说明见 [GitHub 仓库](https://github.com/Noth3rn/murasame-index-tts)。

---

## Training Details

- **Base model**: IndexTTS 2.5 (`bilibili indextts2`)
- **Fine-tuning method**: LoRA (rank=8, alpha=16, last 8 Transformer layers)
- **Training data**: Character voice lines from the game featuring Murasame
- **Best checkpoint**: step600, training loss 5.76
- **Primary language**: Japanese (also supports Chinese)

---

## License

This model is a **Derivative Work** of `bilibili indextts2` and is subject to the
[bilibili Model Use License Agreement](https://github.com/index-tts/index-tts/blob/main/LICENSE).

- Non-commercial use only.
- The character voice data used for fine-tuning is the property of its respective copyright holders.
- The authors of this repository are not responsible for any misuse.

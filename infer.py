"""丛雨 (Murasame) TTS — 命令行推理脚本

用法
----
    python infer.py "ご主人、今日もよろしく。" -o out.wav
    python infer.py "主人，今天天气真好。" --lang ZH -o out.wav
    python infer.py "..." --ref my_ref.wav -o out.wav

参数
----
    text        要合成的文本（必填）
    --lang      ZH 或 JA（默认：自动检测，有假名则 JA，纯汉字则 ZH）
    --ref       参考音频路径（默认：checkpoints/reference.ogg）
    --out / -o  输出 WAV 路径（默认：output.wav）
    --model-dir 模型目录（默认：./checkpoints）
    --seed      随机种子（默认：42）
"""
import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
DEFAULT_MODEL_DIR = ROOT / 'checkpoints'


def detect_lang(text: str) -> str:
    """有假名 → JA；纯汉字 → ZH；其余 → JA。"""
    if re.search(r'[぀-ゟ゠-ヿ]', text):
        return 'JA'
    if re.search(r'[一-鿿]', text):
        return 'ZH'
    return 'JA'


def main():
    p = argparse.ArgumentParser(description='丛雨 TTS 推理')
    p.add_argument('text', help='要合成的文本')
    p.add_argument('--lang', choices=['ZH', 'JA', 'zh', 'ja'], default=None,
                   help='语言（默认：自动检测）')
    p.add_argument('--ref', default=None,
                   help='参考音频路径（默认：checkpoints/reference.ogg）')
    p.add_argument('--model-dir', default=str(DEFAULT_MODEL_DIR),
                   help='模型目录（默认：./checkpoints）')
    p.add_argument('--out', '-o', default='output.wav',
                   help='输出路径（默认：output.wav）')
    p.add_argument('--seed', type=int, default=42)
    args = p.parse_args()

    model_dir = Path(args.model_dir)
    if not model_dir.exists():
        sys.exit(f'模型目录不存在：{model_dir}')

    # 参考音频
    if args.ref:
        ref_audio = args.ref
    else:
        for name in ('reference.ogg', 'reference.wav', 'reference.flac'):
            candidate = model_dir / name
            if candidate.exists():
                ref_audio = str(candidate)
                break
        else:
            sys.exit('未找到参考音频，请使用 --ref <路径> 指定。')

    lang = (args.lang or detect_lang(args.text)).upper()

    import torch
    import numpy as np
    import soundfile as sf
    from indextts.infer_v2_5 import IndexTTS2

    tts = IndexTTS2(cfg_path=str(model_dir / 'config.yaml'),
                    model_dir=str(model_dir),
                    use_bf16=True,
                    use_cuda_kernel=False,
                    use_torch_compile=False,
                    use_qwen_emo=False)

    torch.manual_seed(args.seed)
    print(f'[{lang}] {args.text}')

    tts.infer(spk_audio_prompt=ref_audio,
              text=args.text,
              lang=lang,
              output_path=args.out)

    wav, sr = sf.read(args.out)
    dur = len(wav) / sr
    peak = float(np.max(np.abs(wav)))
    print(f'已保存：{args.out}  ({dur:.1f}s, peak={peak:.3f})')


if __name__ == '__main__':
    main()

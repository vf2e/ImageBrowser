#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Q-SiT-mini 摄影点评服务 — JSON 行协议，按需加载模型。"""
from __future__ import print_function

import json
import os
import sys
import traceback
import warnings

warnings.filterwarnings("ignore")

CRITIQUE_PROMPT = (
    "你是专业摄影评委。用中文写一段连贯点评：先概括画面主题与第一印象，"
    "再各用一句话分析构图、光影、色彩，最后给一句可操作的改进建议。"
    "全文250字以内，不要条目编号。"
)

SCORE_PROMPT = (
    "Assume you are an image quality evaluator.\n"
    "Your rating should be chosen from the following five categories: "
    "Excellent, Good, Fair, Poor, and Bad (from high to low).\n"
    "How would you rate the quality of this image?"
)

SCORE_PREFIX = "The quality of this image is "
RATING_TOKS = ["Excellent", "Good", "Fair", "Poor", "Bad"]
MAX_IMAGE_SIZE = 768
MAX_CRITIQUE_CHARS = 250
MAX_CRITIQUE_TOKENS = 320


def log(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def emit(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def aesthetics_dir():
    return os.path.dirname(os.path.abspath(__file__))


def read_config():
    cfg_path = os.path.join(aesthetics_dir(), "config.json")
    if os.path.isfile(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def resolve_settings():
    cfg = read_config()
    model_id = os.environ.get(
        "IMAGEBROWSER_QSIT_MODEL",
        cfg.get("qsit_model", "zhangzicheng/q-sit-mini"),
    ).strip()
    device_name = os.environ.get(
        "IMAGEBROWSER_QSIT_DEVICE",
        cfg.get("qsit_device", cfg.get("device", "cuda")),
    ).strip().lower()
    return model_id, device_name


def extract_assistant_text(decoded):
    text = decoded.strip()
    if "assistant" in text:
        text = text.split("assistant")[-1].strip()
    for prefix in ("Assistant:", "assistant:"):
        if text.startswith(prefix):
            text = text[len(prefix):].strip()
    return text


def trim_critique(text):
    text = text.strip()
    if len(text) <= MAX_CRITIQUE_CHARS:
        return text
    cut = text[:MAX_CRITIQUE_CHARS]
    for sep in ("。", "！", "？", "；", "\n", "，"):
        idx = cut.rfind(sep)
        if idx >= MAX_CRITIQUE_CHARS // 2:
            return cut[: idx + 1]
    return cut.rstrip() + "…"


def load_image(path):
    from PIL import Image

    image = Image.open(path).convert("RGB")
    image.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)
    return image


def load_model():
    import numpy as np
    import torch
    from transformers import AutoProcessor, AutoTokenizer, LlavaOnevisionForConditionalGeneration

    model_id, device_name = resolve_settings()
    use_cuda = device_name == "cuda" and torch.cuda.is_available()
    device = torch.device("cuda" if use_cuda else "cpu")
    dtype = torch.float16 if use_cuda else torch.float32

    log("loading Q-SiT model: %s on %s" % (model_id, device))
    model = LlavaOnevisionForConditionalGeneration.from_pretrained(
        model_id,
        torch_dtype=dtype,
        low_cpu_mem_usage=True,
    ).to(device)
    model.eval()
    processor = AutoProcessor.from_pretrained(model_id)
    tokenizer = AutoTokenizer.from_pretrained(model_id)
    rating_ids = [
        tokenizer(tok, add_special_tokens=False)["input_ids"][0]
        for tok in RATING_TOKS
    ]

    def move_inputs(inputs):
        moved = {}
        for key, value in inputs.items():
            if hasattr(value, "dtype") and value.dtype.is_floating_point:
                moved[key] = value.to(device, dtype)
            else:
                moved[key] = value.to(device)
        return moved

    def build_inputs(image, prompt_text):
        conversation = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt_text},
                    {"type": "image"},
                ],
            },
        ]
        prompt = processor.apply_chat_template(conversation, add_generation_prompt=True)
        return move_inputs(processor(images=image, text=prompt, return_tensors="pt"))

    def wa5_score(logits):
        logprobs = np.array([logits[tok] for tok in RATING_TOKS], dtype=np.float64)
        probs = np.exp(logprobs - np.max(logprobs))
        probs /= np.sum(probs)
        return float(np.inner(probs, np.array([1.0, 0.75, 0.5, 0.25, 0.0])) * 10.0)

    def score_image(image):
        inputs = build_inputs(image, SCORE_PROMPT)
        prefix_ids = tokenizer(SCORE_PREFIX, return_tensors="pt")["input_ids"].to(device)
        inputs["input_ids"] = torch.cat([inputs["input_ids"], prefix_ids], dim=-1)
        inputs["attention_mask"] = torch.ones_like(inputs["input_ids"])

        with torch.inference_mode():
            output = model.generate(
                **inputs,
                max_new_tokens=1,
                do_sample=False,
                output_logits=True,
                return_dict_in_generate=True,
            )

        last_logits = output.logits[-1][0]
        logits_dict = {tok: last_logits[idx].item() for tok, idx in zip(RATING_TOKS, rating_ids)}
        return round(wa5_score(logits_dict), 2)

    def generate_text(image):
        inputs = build_inputs(image, CRITIQUE_PROMPT)
        with torch.inference_mode():
            output = model.generate(
                **inputs,
                max_new_tokens=MAX_CRITIQUE_TOKENS,
                do_sample=False,
                num_beams=1,
            )
        decoded = processor.decode(output[0], skip_special_tokens=True)
        text = extract_assistant_text(decoded)
        if not text:
            raise RuntimeError("模型未返回有效点评")
        return trim_critique(text)

    def evaluate(path):
        image = load_image(path)
        score = score_image(image)
        text = generate_text(image)
        return text, score

    return evaluate


def main():
    evaluate = None
    try:
        evaluate = load_model()
    except Exception as exc:
        emit({"ready": False, "error": str(exc)})
        return 1

    emit({"ready": True})

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            path = req.get("path", "")
            if not path:
                emit({"ok": False, "error": "missing path"})
                continue
            if not os.path.isfile(path):
                emit({"path": path, "ok": False, "error": "file not found"})
                continue
            text, score = evaluate(path)
            emit({"path": path, "ok": True, "text": text, "score": score})
        except Exception as exc:
            emit({"ok": False, "error": str(exc), "trace": traceback.format_exc()})
    return 0


if __name__ == "__main__":
    sys.exit(main())

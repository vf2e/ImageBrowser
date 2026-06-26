#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EAT 美学评分服务 — 路径默认相对 aesthetics/ 目录，无需手动设环境变量。"""
from __future__ import print_function

import json
import os
import sys
import traceback
import warnings

warnings.filterwarnings("ignore")

IMAGE_NET_MEAN = [0.485, 0.456, 0.406]
IMAGE_NET_STD = [0.229, 0.224, 0.225]


def log(msg):
    sys.stderr.write(msg + "\n")
    sys.stderr.flush()


def emit(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()


def aesthetics_dir():
    return os.path.dirname(os.path.abspath(__file__))


def resolve_paths():
    base = aesthetics_dir()
    cfg = {}
    cfg_path = os.path.join(base, "config.json")
    if os.path.isfile(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)

    eat_root = os.environ.get("IMAGEBROWSER_EAT_ROOT", "").strip()
    weight_path = os.environ.get("IMAGEBROWSER_EAT_WEIGHT", "").strip()
    pretrain_path = os.environ.get("IMAGEBROWSER_EAT_PRETRAIN", "").strip()
    device_name = os.environ.get("IMAGEBROWSER_EAT_DEVICE", cfg.get("device", "cpu")).strip().lower()
    cfg_name = os.environ.get("IMAGEBROWSER_EAT_CFG", "configs/dat_base.yaml").strip()

    if not eat_root:
        for candidate in (
            os.path.join(base, "eat-repo", "AVA"),
            os.path.join(base, "AVA"),
        ):
            if os.path.isdir(candidate):
                eat_root = candidate
                break

    weights_dir = os.path.join(base, "weights")
    if not weight_path:
        for name in ("finetune.pth", "model.pth", "eat.pth"):
            p = os.path.join(weights_dir, name)
            if os.path.isfile(p):
                weight_path = p
                break
        if not weight_path and os.path.isdir(weights_dir):
            for name in sorted(os.listdir(weights_dir)):
                if name.endswith(".pth") and name != "pretrain.pth":
                    weight_path = os.path.join(weights_dir, name)
                    break

    if not pretrain_path:
        p = os.path.join(weights_dir, "pretrain.pth")
        if os.path.isfile(p):
            pretrain_path = p

    if not eat_root or not os.path.isdir(eat_root):
        raise RuntimeError(
            "未找到 EAT 代码，请先运行 scripts\\setup_aesthetics.bat"
        )
    if not weight_path or not os.path.isfile(weight_path):
        raise RuntimeError(
            "未找到微调权重，请将 .pth 放入 aesthetics\\weights\\ 并命名为 finetune.pth"
        )

    return eat_root, weight_path, pretrain_path, cfg_name, device_name


def load_model():
    eat_root, weight_path, pretrain_path, cfg_name, device_name = resolve_paths()

    os.chdir(eat_root)
    if eat_root not in sys.path:
        sys.path.insert(0, eat_root)

    import contextlib
    import io

    import torch
    from torchvision import transforms
    from PIL import Image
    from models import build_model
    from config import get_config

    class Args(object):
        cfg = cfg_name
        opts = None
        data_path = None
        resume = pretrain_path or ""
        amp = False
        output = "output"
        tag = "imagebrowser"
        eval = True
        pretrained = ""

    with contextlib.redirect_stdout(sys.stderr):
        config = get_config(Args())
        model = build_model(config)

        if pretrain_path and os.path.isfile(pretrain_path):
            checkpoint = torch.load(pretrain_path, map_location="cpu")
            pre_weights = checkpoint.get("model", checkpoint)
            pre_dict = {k: v for k, v in pre_weights.items() if "cls_head" not in k}
            model.load_state_dict(pre_dict, strict=False)

        state = torch.load(weight_path, map_location="cpu")
        model.load_state_dict(state, strict=False)

    device = torch.device(
        device_name if torch.cuda.is_available() and device_name == "cuda" else "cpu"
    )
    model.to(device)
    model.eval()

    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=IMAGE_NET_MEAN, std=IMAGE_NET_STD),
    ])
    weights = torch.linspace(1, 10, 10, dtype=torch.float32, device=device)

    def score_image(path):
        image = Image.open(path).convert("RGB").resize((224, 224))
        tensor = transform(image).unsqueeze(0).to(device)
        with torch.no_grad():
            y_pred, _, _ = model(tensor)
            score = (y_pred * weights).sum(dim=1).item()
        return float(score)

    return score_image


def main():
    try:
        score_image = load_model()
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
            score = score_image(path)
            emit({"path": path, "score": round(score, 2), "ok": True})
        except Exception as exc:
            emit({"ok": False, "error": str(exc), "trace": traceback.format_exc()})
    return 0


if __name__ == "__main__":
    sys.exit(main())

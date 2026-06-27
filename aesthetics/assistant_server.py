#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ImageBrowser 小助理 — JSON 行协议，FAQ 优先，可选本地 LLM 补充。"""
from __future__ import print_function

import json
import os
import re
import sys
import traceback

WELCOME = (
    "你好，我是 ImageBrowser 小助理。可以问我：快捷键、收藏导出、"
    "美学评分、AI 点评、安装构建、打包测试等问题。"
)

FALLBACK = (
    "抱歉，我暂时没有找到精确答案。你可以查看项目 README 或 "
    "docs 目录下的文档；也可在 GitHub Issues 反馈：https://github.com/vf2e/ImageBrowser/issues"
)


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


def load_knowledge():
    path = os.path.join(aesthetics_dir(), "assistant_knowledge.md")
    if not os.path.isfile(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    sections = []
    parts = re.split(r"\n(?=## )", text)
    for part in parts:
        part = part.strip()
        if not part.startswith("## "):
            continue
        lines = part.split("\n")
        title = lines[0][3:].strip()
        body_lines = lines[1:]
        keywords = []
        content_lines = []
        for line in body_lines:
            if line.startswith("关键词:") or line.startswith("关键词："):
                kw = line.split(":", 1)[-1].split("：", 1)[-1]
                keywords.extend(kw.split())
            else:
                content_lines.append(line)
        body = "\n".join(content_lines).strip()
        sections.append({"title": title, "keywords": keywords, "body": body})
    return sections


def tokenize(text):
    text = text.lower()
    tokens = set(re.findall(r"[\u4e00-\u9fff]+|[a-z0-9]+", text))
    bigrams = set()
    chars = re.findall(r"[\u4e00-\u9fff]", text)
    for i in range(len(chars) - 1):
        bigrams.add(chars[i] + chars[i + 1])
    tokens.update(bigrams)
    return tokens


def score_section(question, section):
    q_tokens = tokenize(question)
    if not q_tokens:
        return 0
    haystack = section["title"] + " " + " ".join(section["keywords"]) + " " + section["body"][:200]
    h_tokens = tokenize(haystack)
    overlap = len(q_tokens & h_tokens)
    title_bonus = sum(2 for kw in section["keywords"] if kw.lower() in question.lower())
    if section["title"] in question:
        title_bonus += 3
    return overlap + title_bonus


def answer_faq(question, sections):
    if not sections:
        return None
    scored = [(score_section(question, s), s) for s in sections]
    scored.sort(key=lambda x: x[0], reverse=True)
    best_score, best = scored[0]
    if best_score >= 2:
        reply = best["body"]
        if len(reply) > 800:
            reply = reply[:800].rstrip() + "…"
        return reply
    return None


class AssistantServer(object):
    def __init__(self):
        self.cfg = read_config()
        self.sections = load_knowledge()
        self.model = None
        self.tokenizer = None
        self.device = None
        self.model_id = self.cfg.get("assistant_model", "").strip()
        self.use_llm = bool(self.model_id) and self.cfg.get("assistant_use_llm", True)
        self.llm_loaded = False
        self.llm_failed = False

    def startup_mode(self):
        if self.use_llm and self.model_id:
            return "faq+llm"
        return "faq"

    def try_load_llm(self):
        if not self.use_llm or self.llm_loaded or self.llm_failed:
            return self.llm_loaded
        try:
            import torch
            from transformers import AutoModelForCausalLM, AutoTokenizer

            device_name = self.cfg.get(
                "assistant_device",
                self.cfg.get("device", "cpu"),
            ).strip().lower()
            if device_name == "cuda" and not torch.cuda.is_available():
                device_name = "cpu"
                log("CUDA unavailable for assistant, using CPU")

            cache_dir = os.path.join(aesthetics_dir(), "hf_cache")
            os.makedirs(cache_dir, exist_ok=True)

            log("Loading assistant model: %s" % self.model_id)
            self.tokenizer = AutoTokenizer.from_pretrained(
                self.model_id, trust_remote_code=True, cache_dir=cache_dir
            )
            dtype = torch.float16 if device_name == "cuda" else torch.float32
            self.model = AutoModelForCausalLM.from_pretrained(
                self.model_id,
                trust_remote_code=True,
                cache_dir=cache_dir,
                torch_dtype=dtype,
            )
            self.device = torch.device(device_name)
            self.model.to(self.device)
            self.model.eval()
            self.llm_loaded = True
            log("Assistant LLM ready on %s" % device_name)
        except Exception as exc:
            self.llm_failed = True
            log("Assistant LLM load failed: %s" % exc)
            traceback.print_exc(file=sys.stderr)
        return self.llm_loaded

    def build_system_prompt(self):
        chunks = []
        for sec in self.sections[:12]:
            chunks.append("【%s】\n%s" % (sec["title"], sec["body"][:400]))
        kb = "\n\n".join(chunks)
        return (
            "你是 ImageBrowser 图片浏览器的内置小助理，只回答与本软件相关的问题。"
            "回答简洁、准确、用中文。若知识库没有相关信息，请诚实说明并建议查看 README。\n\n"
            "知识库摘要：\n" + kb
        )

    def answer_llm(self, question, history):
        if not self.try_load_llm():
            return None
        import torch

        messages = [{"role": "system", "content": self.build_system_prompt()}]
        for item in history[-6:]:
            role = item.get("role", "user")
            if role not in ("user", "assistant"):
                continue
            messages.append({"role": role, "content": item.get("content", "")})
        messages.append({"role": "user", "content": question})

        try:
            if hasattr(self.tokenizer, "apply_chat_template"):
                prompt = self.tokenizer.apply_chat_template(
                    messages, tokenize=False, add_generation_prompt=True
                )
            else:
                prompt = self.build_system_prompt() + "\n\n用户：" + question + "\n助手："

            inputs = self.tokenizer(prompt, return_tensors="pt").to(self.device)
            max_new = int(self.cfg.get("assistant_max_tokens", 256))
            with torch.no_grad():
                out = self.model.generate(
                    **inputs,
                    max_new_tokens=max_new,
                    do_sample=True,
                    temperature=0.7,
                    top_p=0.9,
                    pad_token_id=self.tokenizer.eos_token_id,
                )
            decoded = self.tokenizer.decode(
                out[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True
            ).strip()
            for prefix in ("assistant:", "Assistant:", "助手：", "助手:"):
                if decoded.startswith(prefix):
                    decoded = decoded[len(prefix):].strip()
            return decoded[:600] if decoded else None
        except Exception as exc:
            log("LLM inference failed: %s" % exc)
            traceback.print_exc(file=sys.stderr)
            return None

    def answer(self, question, history):
        faq = answer_faq(question, sections=self.sections)
        if faq:
            return faq, "faq"
        if self.use_llm:
            llm = self.answer_llm(question, history)
            if llm:
                return llm, "llm"
        return FALLBACK, "fallback"


def main():
    server = AssistantServer()
    mode = server.startup_mode()
    emit({"ready": True, "mode": mode, "welcome": WELCOME})

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except ValueError:
            emit({"ok": False, "error": "invalid json"})
            continue

        message = (req.get("message") or "").strip()
        if not message:
            emit({"ok": False, "error": "empty message"})
            continue

        history = req.get("history") or []
        try:
            reply, source = server.answer(message, history)
            emit({"ok": True, "reply": reply, "source": source})
        except Exception as exc:
            log("request failed: %s" % exc)
            emit({"ok": False, "error": str(exc)})


if __name__ == "__main__":
    main()

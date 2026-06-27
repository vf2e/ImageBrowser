# 美学评分（已整合进项目）

ImageBrowser 已内置 EAT 美学评估接入，**无需手动配置环境变量**。按下面两步即可。

---

## 第一步：一键安装（只需一次）

在项目根目录执行：

```bat
scripts\setup_aesthetics.bat
```

脚本会自动：

1. 克隆 [EAT 官方仓库](https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment) 到 `aesthetics/eat-repo/`
2. 创建 Python 虚拟环境 `aesthetics/venv/`
3. 安装 PyTorch 等依赖

---

## 第二步：放入权重文件

从 EAT 官方 README 下载权重，放入 `aesthetics/weights/`：

| 文件名 | 必填 | 说明 |
|--------|------|------|
| `finetune.pth` | **是** | AVA 微调 checkpoint（Google Drive） |
| `pretrain.pth` | 否 | `dat_base_in1k_224.pth` 预训练权重 |

> 若下载的文件名不同，可重命名为 `finetune.pth`，或保留原名（程序会自动识别 weights 目录下第一个非 pretrain 的 `.pth`）。

---

## 使用

正常启动 ImageBrowser 即可（无需 set 环境变量）：

```bat
scripts\build_release.bat
build-release\ImageBrowser.exe
```

程序会自动查找：

- `aesthetics/eat_server.py`
- `aesthetics/venv/Scripts/python.exe`
- `aesthetics/eat-repo/AVA/`
- `aesthetics/weights/finetune.pth`

---

## 界面说明

| 显示 | 含义 |
|------|------|
| `评分中...` | 正在推理 |
| `美学 7.86` | 评分成功（1–10） |
| `美学 未就绪` | 鼠标悬停可看原因（如未安装、缺权重） |

点击左下角 **AI 点评** 可打开侧栏，由 Q-SiT-mini 本地生成摄影点评（首次需下载模型，约 1 GB）。

---

## AI 摄影点评（Q-SiT-mini）

- 按需加载，不影响浏览速度
- 首次点击会下载 HuggingFace 权重到 `aesthetics/hf_cache/`
- 4060 8GB 显卡上首次加载约 20–30 秒，之后每张约 3–5 秒

可选配置（复制 `config.json.example` 为 `config.json`）：

| 字段 | 适用 | 说明 |
|------|------|------|
| `device` | EAT | 美学评分设备，`cuda` / `cpu` |
| `qsit_model` | Q-SiT | 默认 `zhangzicheng/q-sit-mini` |
| `qsit_device` | Q-SiT | 点评模型设备，`cuda` / `cpu` |
| `assistant_model` | 小助理 | 留空则仅 FAQ；如 `Qwen/Qwen2.5-0.5B-Instruct` |
| `assistant_device` | 小助理 | LLM 设备，`cuda` / `cpu` |
| `assistant_use_llm` | 小助理 | FAQ 未命中时是否调用 LLM，默认 `true` |
| `assistant_max_tokens` | 小助理 | LLM 最大生成长度，默认 `256` |

---

## 小助理 AI

- 入口：右下角 💬 按钮
- 默认使用 `assistant_knowledge.md` 即时 FAQ，**无需配置模型**
- 配置 `assistant_model` 后可启用本地语言模型作为补充

---

## 目录结构

```
aesthetics/
├── eat_server.py            # EAT 评分服务
├── qsit_server.py           # Q-SiT 点评服务
├── assistant_server.py      # 小助理服务
├── assistant_knowledge.md   # 小助理知识库
├── requirements.txt         # EAT Python 依赖
├── requirements-qsit.txt    # Q-SiT 依赖
├── config.json.example      # 可选配置（复制为 config.json）
├── setup 后生成:
│   ├── eat-repo/            # EAT 源码（git clone）
│   ├── venv/                # Python 虚拟环境
│   ├── hf_cache/            # HuggingFace 模型缓存
│   └── weights/
│       ├── *.pth            # EAT 微调权重（自动识别）
│       └── pretrain.pth     # 可选
```

---

## 故障排查

| 现象 | 处理 |
|------|------|
| `美学 未就绪` + 提示运行 setup | 执行 `scripts\setup_aesthetics.bat` |
| 提示缺少 finetune.pth | 下载权重放入 `aesthetics\weights\` |
| 无法启动 Python | 确认 `aesthetics\venv` 存在；Windows 上若 `python` 命令无效，脚本已自动改用 `py -3` |
| 创建 venv 失败 | 通常是 Microsoft Store 的 python 占位符干扰；请安装 [python.org](https://www.python.org/downloads/) 版本，或手动执行 `py -3 -m venv aesthetics\venv` |
| 首次评分很慢 | 正常，模型加载需数十秒；之后切换图片会快很多 |

---

## 高级：环境变量（可选）

仍支持手动覆盖：

- `IMAGEBROWSER_EAT_ROOT`
- `IMAGEBROWSER_EAT_WEIGHT`
- `IMAGEBROWSER_EAT_PRETRAIN`
- `IMAGEBROWSER_EAT_DEVICE`（`cpu` / `cuda`）

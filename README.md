# ImageBrowser 项目说明文档

ImageBrowser 是一款基于 **Qt 5.15** 的沉浸式本地图片浏览器，采用 **C++ 后端 + QML 界面** 架构。除流畅的大图浏览、收藏筛选与导出外，还集成了三套本地 AI 能力：**EAT 美学评分**、**Q-SiT 摄影点评**、**小助理问答**——均可离线运行，无需联网。

<div align="center">
  <h3>✨ 沉浸式浏览体验</h3>
  <img src="https://github.com/vf2e/ImageBrowser/blob/main/assets/images/preview.png" alt="主界面预览" width="800"/>
</div>

---

## 目录

- [1. 核心特性](#1-核心特性)
- [2. 快速开始](#2-快速开始)
- [3. 界面与操作](#3-界面与操作)
- [4. AI 功能详解](#4-ai-功能详解)
- [5. 快捷键](#5-快捷键)
- [6. 技术栈与架构](#6-技术栈与架构)
- [7. 项目结构](#7-项目结构)
- [8. 下载与安装](#8-下载与安装)
- [9. 从源码构建](#9-从源码构建)
- [10. 自动化测试](#10-自动化测试)
- [11. 一键打包](#11-一键打包)
- [12. 配置参考](#12-配置参考)
- [13. 故障排查](#13-故障排查)
- [14. 版本历史](#14-版本历史)
- [15. 许可与联系](#15-许可与联系)

---

## 1. 核心特性

### 浏览与交互

| 特性 | 说明 |
|------|------|
| 沉浸式 UI | 顶部/底部工具栏采用悬浮岛屿式设计，最大化图片展示区域 |
| 异步加载 | 基于 `QtConcurrent` 解码大图，主线程不阻塞，切换带淡入动画 |
| 最近文件夹 | 自动记录最近 5 个文件夹，一键切换 |
| 浏览进度 | 按文件夹保存当前索引与文件名，重新打开可恢复位置 |
| 底部进度条 | 可拖拽 Slider 快速跳转到任意图片 |

### 收藏与导出

| 特性 | 说明 |
|------|------|
| 收藏标记 | 空格 / ↑ / ↓ / 右键切换收藏，顶部显示收藏数量 |
| 持久化 | 每个文件夹内生成 `favorites.txt`（UTF-8 文件名列表） |
| 一键导出 | 将收藏图片异步复制到导出目录（默认 `D:/收藏/<文件夹名>/`） |
| Toast 反馈 | 收藏/取消/导出完成均有色彩化即时提示 |

### 本地 AI（可选，需运行 `setup_aesthetics.bat`）

| 模块 | 入口 | 模型 | 输出 |
|------|------|------|------|
| **EAT 美学评分** | 图片左上角徽章 | [EAT](https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment) | 1–10 分美学分数 |
| **Q-SiT 摄影点评** | 图片左下角「AI 点评」 | [Q-SiT-mini](https://huggingface.co/zhangzicheng/q-sit-mini) | 中文点评 + 质量分 |
| **小助理** | 右下角 💬 浮动按钮 | 内置 FAQ 知识库（可选 LLM） | 软件使用问答 |

> **评分说明**：左上角「美学」为 EAT 专用评分；点评面板内「AI 质量评分」来自 Q-SiT，两者模型不同，分数可能不一致。

### 工程质量

- **CMake** 构建，支持 Qt Creator / 命令行
- **71** 条自动化测试（C++ 后端 + QML 组件 + 键盘集成）
- GitHub Actions CI（Windows + Qt 5.15.2）
- 一键打包：便携目录 / ZIP / Inno Setup 安装包

---

## 2. 快速开始

### 仅浏览图片（无需 AI）

1. 下载 [Release 安装包](#最新版本下载) 或自行编译
2. 启动 `ImageBrowser.exe`
3. 点击中央区域或顶部 📁 选择图片文件夹

### 启用 AI 功能（推荐）

在项目根目录执行一次：

```bat
scripts\setup_aesthetics.bat
```

然后：

1. 从 [EAT 官方 README](https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment) 下载 AVA 微调权重
2. 放入 `aesthetics\weights\`（**无需重命名**，程序自动识别第一个非 `pretrain.pth` 的 `.pth`）
3. 重新启动 `ImageBrowser.exe`

Q-SiT 与小助理会在首次使用时自动准备（Q-SiT 需从 HuggingFace 下载约 1 GB 模型到 `aesthetics\hf_cache\`）。

---

## 3. 界面与操作

```
┌─────────────────────────────────────────────────────────────┐
│  [美学 7.86]          ┌─ 顶部工具栏 ─┐                      │
│                       │ 📁 路径 ✨收藏 导出 │                  │
│                       └───────────────┘                      │
│                                                             │
│                      （全屏图片预览区）                        │
│                                                             │
│  [AI 点评]                              [💬 小助理]          │
│                       ┌─ 底部进度条 ─┐                      │
│                       │  3/120  ━━━●━━  快捷键提示  │        │
│                       └───────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

| 区域 | 功能 |
|------|------|
| 中央空白 / 📁 | 首次选文件夹；有历史记录时弹出最近列表 |
| 顶部工具栏 | 当前路径、收藏数、导出收藏 |
| 底部工具栏 | 页码计数、Slider 跳转、快捷键提示 |
| 左上角徽章 | EAT 美学评分（加载中显示「评分中…」） |
| 「AI 点评」 | 打开右侧点评侧栏（Q-SiT） |
| 右下角 💬 | 打开小助理对话窗口 |
| 侧栏 / 对话框 | 点击遮罩或 ✕ 关闭 |

**支持的图片格式**：`jpg` · `jpeg` · `png` · `bmp` · `gif` · `webp`

---

## 4. AI 功能详解

### 4.1 美学评分（EAT）

- **作用**：对当前图片给出 1–10 美学分数，显示在左上角
- **服务进程**：`aesthetics/eat_server.py`（JSON 行协议，长驻子进程）
- **C++ 桥接**：`AestheticEvaluator` → `ImageBrowserBackend`
- **缓存**：同一张图切换回来无需重新推理
- **权重**：`aesthetics/weights/*.pth`（见 [weights/README.md](aesthetics/weights/README.md)）

### 4.2 AI 摄影点评（Q-SiT-mini）

- **作用**：从构图、光影、色彩等角度生成 **250 字以内** 中文点评，并给出 Q-SiT 质量分
- **入口**：浏览图片时点击「AI 点评」，右侧滑出 `CritiquePanel`
- **服务进程**：`aesthetics/qsit_server.py`
- **C++ 桥接**：`CritiqueEvaluator` → `ImageBrowserBackend`
- **缓存**：同路径图片的点评文本与分数会缓存
- **性能参考**（RTX 4060 8GB + CUDA）：
  - 首次加载模型：约 20–30 秒
  - 之后每张：约 3–5 秒（含评分 + 文本生成两次推理）
  - CPU 模式会显著更慢

### 4.3 小助理 AI

- **作用**：回答关于 ImageBrowser 的使用问题（快捷键、安装、AI 模块、打包等）
- **入口**：右下角 💬 浮动按钮 → 居中对话框
- **服务进程**：`aesthetics/assistant_server.py`
- **知识库**：`aesthetics/assistant_knowledge.md`（FAQ 关键词匹配，**即时响应**）
- **可选 LLM**：在 `config.json` 配置 `assistant_model` 后，FAQ 未命中时可调用本地语言模型补充
- **对话**：支持多轮；「清空」重置会话；关闭软件后对话不保留

**内置常见问题快捷按钮**：

- 有哪些快捷键？
- 怎么收藏和导出？
- 美学评分怎么开启？
- AI 点评为什么很慢？

### 4.4 AI 架构概览

```mermaid
flowchart LR
    subgraph UI["QML 界面"]
        IV[ImageViewer]
        CP[CritiquePanel]
        AP[AssistantPanel]
    end

    subgraph Backend["C++ 后端"]
        BB[ImageBrowserBackend]
        AE[AestheticEvaluator]
        CE[CritiqueEvaluator]
        AS[AssistantEvaluator]
    end

    subgraph Python["Python 子进程 aesthetics/"]
        EAT[eat_server.py]
        QSIT[qsit_server.py]
        AST[assistant_server.py]
    end

    IV --> BB
    CP --> BB
    AP --> BB
    BB --> AE --> EAT
    BB --> CE --> QSIT
    BB --> AS --> AST
```

### 4.5 安装 AI 环境

详细步骤见 [docs/aesthetics.md](docs/aesthetics.md)。

```bat
scripts\setup_aesthetics.bat
```

脚本会自动：

1. 克隆 EAT 官方仓库 → `aesthetics/eat-repo/`
2. 创建 Python 虚拟环境 → `aesthetics/venv/`
3. 安装 PyTorch、transformers 等依赖
4. 检测到 NVIDIA 显卡时尝试安装 **CUDA 版 PyTorch**

**权重目录**（不纳入 Git，需自行下载）：

| 文件 | 必填 | 说明 |
|------|------|------|
| `*.pth`（除 pretrain） | 是 | EAT AVA 微调 checkpoint |
| `pretrain.pth` | 否 | EAT 预训练权重 |

---

## 5. 快捷键

| 操作 | 按键 |
|------|------|
| 下一张 / 上一张 | `→` / `←` |
| 收藏 / 取消收藏 | `Space` · `↑` · `↓` |
| 快速翻页 | 鼠标滚轮 |
| 切换收藏 | 鼠标右键点击图片 |
| 拖拽跳转 | 底部 Slider |

> 小助理或 AI 点评面板打开时，方向键与空格 **不会** 触发图片操作，避免误触。

---

## 6. 技术栈与架构

### 技术栈

| 层级 | 技术 |
|------|------|
| 应用框架 | Qt 5.15.2 · C++11 |
| 界面 | QML 2.15 · QtQuick Controls 2 · QtGraphicalEffects |
| 并发 | QtConcurrent |
| AI 推理 | Python 3.8+ · PyTorch · transformers · EAT · Q-SiT |
| 构建 | CMake 3.16+ |
| 测试 | Qt Test · Qt Quick Test |
| 部署 | windeployqt · Inno Setup 6 |
| CI | GitHub Actions（Windows） |

### 架构分层

```
┌──────────────────────────────────────────┐
│  qml/main.qml          窗口组装、快捷键分发  │
├──────────────────────────────────────────┤
│  qml/components/       独立 UI 组件        │
│    ImageViewer / TopToolbar / ...        │
├──────────────────────────────────────────┤
│  ImageBrowserBackend   QML 可调用业务 API   │
│    ├─ AestheticEvaluator                 │
│    ├─ CritiqueEvaluator                  │
│    └─ AssistantEvaluator                 │
├──────────────────────────────────────────┤
│  Python 服务 (QProcess + JSON 行协议)      │
└──────────────────────────────────────────┘
```

- **C++ 后端**（`src/backend/`）：文件夹扫描、索引、收藏、进度、导出、AI 进程管理
- **QML 组件**（`qml/components/`）：纯 UI，通过全局 `backend` 对象通信
- **Python 服务**（`aesthetics/*_server.py`）：模型加载与推理，stdin/stdout JSON 通信

程序从 `exe` 所在目录向上查找 `aesthetics/` 文件夹（开发目录与打包后的 `dist` 目录均适用）。

---

## 7. 项目结构

```
ImageBrowser/
├── aesthetics/                      # AI 模块（setup 后含 venv、eat-repo）
│   ├── eat_server.py                # EAT 美学评分服务
│   ├── qsit_server.py               # Q-SiT 摄影点评服务
│   ├── assistant_server.py          # 小助理 FAQ / LLM 服务
│   ├── assistant_knowledge.md       # 小助理内置知识库
│   ├── requirements.txt             # EAT Python 依赖
│   ├── requirements-qsit.txt        # Q-SiT 额外依赖
│   ├── config.json.example          # 可选配置模板
│   ├── weights/                     # EAT 权重（本地，gitignore）
│   ├── venv/                        # Python 虚拟环境（gitignore）
│   ├── eat-repo/                    # EAT 源码 clone（gitignore）
│   └── hf_cache/                    # HuggingFace 模型缓存（gitignore）
├── src/
│   ├── main.cpp                     # 入口，注册 backend 到 QML
│   └── backend/
│       ├── ImageBrowserBackend.*    # 核心业务 + QML 属性
│       ├── AestheticEvaluator.*     # EAT 进程桥接
│       ├── CritiqueEvaluator.*      # Q-SiT 进程桥接
│       └── AssistantEvaluator.*     # 小助理进程桥接
├── qml/
│   ├── main.qml
│   └── components/
│       ├── ImageViewer.qml          # 图片预览 + 美学徽章 + AI 点评入口
│       ├── CritiquePanel.qml        # AI 摄影点评侧栏
│       ├── AssistantPanel.qml       # 小助理对话框
│       ├── AssistantFab.qml         # 小助理浮动按钮
│       ├── TopToolbar.qml
│       ├── BottomToolbar.qml
│       ├── EmptyPlaceholder.qml
│       ├── RecentFolderPopup.qml
│       ├── ToastMessage.qml
│       └── BackgroundGradient.qml
├── assets/
│   ├── icons/logo.ico
│   └── images/preview.png
├── docs/                            # 详细文档
├── tests/                           # 自动化测试
├── scripts/                         # 构建 / 测试 / 打包脚本
├── installer/ImageBrowser.iss       # Inno Setup 安装脚本
├── .github/workflows/ci.yml         # GitHub Actions
├── pack.bat                         # 打包快捷入口
├── CMakeLists.txt
└── qml.qrc
```

### 数据持久化（按文件夹）

| 文件 | 内容 |
|------|------|
| `<文件夹>/favorites.txt` | 收藏文件名列表（UTF-8） |
| `<文件夹>/browser_config.ini` | 上次浏览索引与文件名 |
| `%AppData%/WangChang/ImageBrowser/` | 最近文件夹列表（最多 5 条） |

---

## 8. 下载与安装

### 最新版本下载

[⬇️ 点击下载 ImageBrowser v1.0.1 安装包 (Windows)](https://github.com/vf2e/ImageBrowser/releases/download/V1.0.1/ImageBrowser_v1.0.1_Setup.exe)

> Release 安装包不含 AI 权重与 Python 环境。启用 AI 需在安装目录运行 `aesthetics\setup_aesthetics.bat`（或从源码复制已配置好的 `aesthetics\` 目录）。

### 环境要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Windows 10 / 11 |
| 运行库 | [Visual C++ 2019 Redistributable](https://learn.microsoft.com/zh-cn/cpp/windows/latest-supported-vc-redist) |
| AI（可选） | Python 3.8+（setup 脚本自动创建 venv） |
| GPU 加速（可选） | NVIDIA 显卡 + CUDA 版 PyTorch |

### 安装步骤

1. 下载并运行 `ImageBrowser_v*_Setup.exe`
2. 按向导完成安装，可选创建桌面快捷方式
3. （可选）运行 `aesthetics\setup_aesthetics.bat` 并放入 EAT 权重
4. 从开始菜单或桌面启动

---

## 9. 从源码构建

### 开发环境

- Windows 10/11
- **Qt 5.15.2**（MSVC 2019 64-bit）
- **CMake 3.16+**
- Visual Studio 2019/2022（「使用 C++ 的桌面开发」工作负载）
- Qt Creator（推荐）
- Inno Setup 6（打包时需要）
- Git、Python 3.8+（AI 模块需要）

### 方式一：Qt Creator

```bat
git clone https://github.com/vf2e/ImageBrowser.git
cd ImageBrowser
```

1. 用 Qt Creator 打开 `CMakeLists.txt`
2. 选择 Kit：`Desktop Qt 5.15.2 MSVC2019 64bit`
3. 构建并运行

> QML 类型无法识别时，将 QML 导入路径设为项目下的 `qml/`。

### 方式二：命令行

```bat
scripts\build_release.bat
```

或手动：

```bat
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
cmake -S . -B build-release -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%QT_DIR%
cmake --build build-release --config Release
```

产物：`build-release\ImageBrowser.exe`

### 手动部署 Qt 依赖

```bat
windeployqt --release --qmldir qml build-release\ImageBrowser.exe
```

> qmake → CMake 迁移记录：[docs/qmake-to-cmake-migration.md](docs/qmake-to-cmake-migration.md)

---

## 10. 自动化测试

项目包含 **三层测试，共 71 条用例**：

| 套件 | 框架 | 用例数 | 覆盖范围 |
|------|------|--------|----------|
| `tst_imagebrowserbackend` | Qt Test | 50 | 后端逻辑、收藏/导出/进度、AI mock、信号 |
| `tst_keyboard_integration` | Qt Test + QML | 4 | `main.qml` 快捷键与真实后端 |
| `tst_qml` | Qt Quick Test | 17 | QML 组件属性绑定 |

### 常用命令

```bat
scripts\run_tests.bat                    :: 运行全部测试
scripts\run_tests.bat --report           :: 测试 + 生成 HTML 报告
scripts\generate_test_report.bat --open  :: 构建、测试并打开报告
scripts\run_coverage.bat                 :: C++ 覆盖率（需 OpenCppCoverage）
```

成功时控制台显示 `[OK] All tests passed`。

### 文档索引

| 文档 | 内容 |
|------|------|
| [docs/testing.md](docs/testing.md) | 测试总览、运行方式速查、故障排查 |
| [docs/testing-testcases.md](docs/testing-testcases.md) | 全量用例明细 |
| [docs/testing-report.md](docs/testing-report.md) | HTML 报告生成 |
| [docs/coverage.md](docs/coverage.md) | 代码覆盖率 |
| [docs/development-log.md](docs/development-log.md) | 开发历程与技术决策 |

---

## 11. 一键打包

在项目根目录：

```bat
pack.bat
```

等价于 `scripts\package.bat`，自动完成：

1. **Release 构建** — 编译 `ImageBrowser.exe`
2. **依赖部署** — `windeployqt --qmldir qml`
3. **复制 AI 模块** — `eat_server.py`、`qsit_server.py`、`assistant_server.py`、知识库、权重（若存在）等
4. **便携 ZIP** — `output\ImageBrowser_v*_portable.zip`
5. **安装包** — Inno Setup 编译 `installer\ImageBrowser.iss`

### 输出目录

| 路径 | 说明 |
|------|------|
| `dist\ImageBrowser\` | 可直接运行的便携目录 |
| `output\ImageBrowser_v*_portable.zip` | 便携压缩包 |
| `output\ImageBrowser_v*_Setup.exe` | Windows 安装包 |

### 环境变量（可选）

```bat
set SKIP_BUILD=1       REM 跳过编译，仅重新部署/打包
set SKIP_INSTALLER=1   REM 不生成 Setup.exe
set SKIP_ZIP=1         REM 不生成便携 ZIP
set INCLUDE_VENV=1     REM 将 aesthetics\venv 打入 dist（体积很大，约 2GB+）
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
pack.bat
```

Inno Setup 默认搜索路径：

- `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- `C:\Program Files\Inno Setup 6\ISCC.exe`

---

## 12. 配置参考

复制 `aesthetics/config.json.example` 为 `aesthetics/config.json`（该文件已在 `.gitignore` 中，不会提交）。

```json
{
  "device": "cuda",
  "qsit_model": "zhangzicheng/q-sit-mini",
  "qsit_device": "cuda",
  "assistant_model": "",
  "assistant_device": "cuda",
  "assistant_use_llm": true,
  "assistant_max_tokens": 256
}
```

| 字段 | 适用模块 | 说明 |
|------|----------|------|
| `device` | EAT | 美学评分设备：`cuda` / `cpu` |
| `qsit_model` | Q-SiT | HuggingFace 模型 ID |
| `qsit_device` | Q-SiT | 点评模型设备 |
| `assistant_model` | 小助理 | 留空则仅 FAQ；如 `Qwen/Qwen2.5-0.5B-Instruct` |
| `assistant_device` | 小助理 | LLM 推理设备 |
| `assistant_use_llm` | 小助理 | 是否在 FAQ 未命中时调用 LLM |
| `assistant_max_tokens` | 小助理 | LLM 最大生成长度 |

### 环境变量（高级覆盖）

| 变量 | 说明 |
|------|------|
| `IMAGEBROWSER_PYTHON` | 指定 Python 可执行文件 |
| `IMAGEBROWSER_EAT_ROOT` | EAT 源码根目录 |
| `IMAGEBROWSER_EAT_WEIGHT` | EAT 权重路径 |
| `IMAGEBROWSER_EAT_DEVICE` | EAT 设备 |
| `IMAGEBROWSER_QSIT_MODEL` | Q-SiT 模型 ID |
| `IMAGEBROWSER_QSIT_DEVICE` | Q-SiT 设备 |

---

## 13. 故障排查

### 浏览与 UI

| 现象 | 处理 |
|------|------|
| 打不开文件夹 | 确认文件夹内有 jpg/png 等支持格式 |
| 进度未恢复 | 检查文件夹内是否有 `browser_config.ini` |

### AI 通用

| 现象 | 处理 |
|------|------|
| 提示运行 setup | 执行 `scripts\setup_aesthetics.bat` |
| 找不到 Python | 确认 `aesthetics\venv` 存在；或设置 `IMAGEBROWSER_PYTHON` |
| venv 创建失败 | 安装 [python.org](https://www.python.org/downloads/) 版 Python，避开 Microsoft Store 占位符 |

### EAT 美学评分

| 现象 | 处理 |
|------|------|
| 左上角「美学 未就绪」 | 检查权重是否在 `aesthetics\weights\` |
| 一直「评分中…」 | 首次加载模型较慢；检查 Python 进程是否崩溃 |
| CUDA 不生效 | 见下方 GPU 排查 |

### Q-SiT 摄影点评

| 现象 | 处理 |
|------|------|
| 首次很慢 | 需下载约 1 GB 模型到 `hf_cache\`，正常 |
| 点评失败 | 查看是否缺 transformers；重新运行 setup |
| 分数与 EAT 不一致 | **正常现象**，两者是不同模型 |

### 小助理

| 现象 | 处理 |
|------|------|
| 无法回答 | 确认 `assistant_server.py` 与 `assistant_knowledge.md` 在 `aesthetics\` 下 |
| 输入无响应 | 更新到最新版（已修复焦点冲突） |

### GPU / CUDA 排查

在 `aesthetics\venv` 中验证：

```bat
aesthetics\venv\Scripts\python.exe -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

- 若 `cuda_available` 为 `False`：当前是 CPU 版 PyTorch，需重装 CUDA 版
- 确认 `config.json` 中 `device` / `qsit_device` 为 `cuda`
- 重新运行 `scripts\setup_aesthetics.bat`（检测到 `nvidia-smi` 时会尝试安装 CUDA torch）

### Git 与大文件

模型权重（`.pth`）与 `venv/`、`hf_cache/` **不应提交到 Git**（已在 `.gitignore` 中）。若误提交大文件，可使用 `git filter-repo` 清理历史。

---

## 14. 版本历史

### v1.2.0（开发中）

- 新增 **小助理 AI**：FAQ 知识库 + 可选本地 LLM，对话式软件问答
- 新增 **Q-SiT 摄影点评**侧栏：中文点评 + 质量评分
- 集成 **EAT 美学评分**：左上角 1–10 分徽章
- AI 模块一键安装脚本 `setup_aesthetics.bat`
- 测试用例扩展至 71 条；`.gitignore` 优化（排除权重与 IDE 配置）

### v1.0.1

- 发布 Windows 安装包
- 文档与 README 更新

### v1.0.0（2024-03-03）

- 初始版本：沉浸式悬浮工具栏、收藏与导出、快捷键、异步加载

---

## 15. 许可与联系

### 许可协议

本项目采用 [MIT License](LICENSE) 开源协议。

### 开发者

- **作者**：Wang Chang
- **项目主页**：https://github.com/vf2e/ImageBrowser
- **问题反馈**：[GitHub Issues](https://github.com/vf2e/ImageBrowser/issues)

### 相关链接

| 资源 | 链接 |
|------|------|
| EAT 模型 | https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment |
| Q-SiT-mini | https://huggingface.co/zhangzicheng/q-sit-mini |
| AI 接入详细文档 | [docs/aesthetics.md](docs/aesthetics.md) |

---

<p align="center">如果这个项目对你有帮助，欢迎 ⭐ Star</p>

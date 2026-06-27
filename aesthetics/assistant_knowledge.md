# ImageBrowser 小助理知识库

## 软件简介
关键词: 是什么 介绍 功能 特性 ImageBrowser 图片浏览器

ImageBrowser 是一款基于 Qt 5.15 的沉浸式本地图片浏览器，采用 C++ 后端 + QML 界面。
核心能力：文件夹浏览、收藏筛选、一键导出、AI 美学评分（EAT）、AI 摄影点评（Q-SiT）、小助理问答。
界面采用悬浮岛屿式工具栏，最大化图片展示区域，支持异步加载大图不卡顿。

## 快捷键
关键词: 快捷键 按键 键盘 操作 怎么切换 怎么收藏

| 操作 | 按键 |
|------|------|
| 上一张 / 下一张 | ← / → |
| 收藏 / 取消收藏 | 空格 Space、↑、↓ |
| 快速翻页 | 鼠标滚轮 |
| 切换收藏 | 鼠标右键点击图片 |

## 打开文件夹
关键词: 打开 文件夹 选择 目录 加载 最近

- 首次启动：点击中央「请选择一个图片文件夹」区域，或顶部 📁 按钮。
- 若已有最近记录：点击中央区域或 📁 会弹出最近文件夹列表，点选即可打开。
- 支持格式：jpg、jpeg、png、bmp、gif、webp。
- 浏览进度与收藏记录会按文件夹分别保存。

## 收藏与导出
关键词: 收藏 导出 精选 星星  favorites 保存

- 空格 / ↑ / ↓ / 右键：切换当前图片收藏状态，顶部显示收藏数量 ✨。
- 点击顶部「导出」：将当前文件夹内所有收藏图片复制到导出目录（默认 D:/收藏，可在代码或后续设置中修改）。
- 导出在后台异步进行，完成后右下角 Toast 提示。

## 美学评分 EAT
关键词: 美学 评分 分数 左上角 EAT 多少分

- 打开含图片的文件夹后，左上角显示「美学 X.X / 10」徽章。
- 由 EAT 模型本地推理，无需联网。
- 首次需运行 `scripts\setup_aesthetics.bat` 安装 Python 环境与权重。
- 权重文件放入 `aesthetics\weights\finetune.pth`。
- 若显示「评分中…」较久，可能是 CPU 推理或模型首次加载，请耐心等待。
- 可在 `aesthetics\config.json` 设置 `"device": "cuda"` 使用显卡加速（需 CUDA 版 PyTorch）。

## AI 摄影点评 Q-SiT
关键词: AI 点评 摄影 点评 Q-SiT 质量 文字 分析

- 浏览图片时点击「AI 点评」按钮，右侧滑出点评面板。
- 使用 Q-SiT-mini 本地大模型，从构图、光影、色彩等角度生成中文点评（约 250 字以内）。
- 面板内「AI 质量评分」为 Q-SiT 的质量分；左上角「美学」为 EAT 专用评分，两者模型不同、分数可能不一致。
- 同一张图片的点评会缓存，切换回来无需重新生成。
- 首次使用需完成美学环境安装（与 EAT 共用 venv）；模型缓存在 `aesthetics\hf_cache\`。
- 可在 `aesthetics\config.json` 设置 `"qsit_device": "cuda"` 加速。

## 小助理 AI
关键词: 小助理 助手 对话框 问答 帮助

- 点击右下角「小助理」浮动按钮打开对话窗口。
- 可询问本软件的功能、快捷键、安装、AI 模块等问题。
- 优先从内置知识库即时回答；若配置了 `assistant_model` 还可调用本地语言模型补充回答。
- 对话记录仅在本次会话保留，关闭软件后清空。

## 安装与运行
关键词: 安装 下载 运行 启动 exe 环境要求

- 系统：Windows 10/11，需 Visual C++ 2019 运行库。
- 下载安装包后按向导安装，可从开始菜单或桌面快捷方式启动。
- 便携版：解压 `ImageBrowser_v*.zip` 后直接运行目录内 `ImageBrowser.exe`。

## 从源码构建
关键词: 编译 构建 源码 CMake Qt Creator 开发

- 需要 Qt 5.15.2（MSVC 2019 64-bit）、CMake 3.16+、Visual Studio 2019/2022。
- Qt Creator 打开根目录 `CMakeLists.txt`，选择 Desktop Qt 5.15.2 MSVC2019 64bit Kit 构建。
- 或运行 `scripts\build_release.bat`。
- 产物：`build-release\ImageBrowser.exe`。
- 手动部署依赖：`windeployqt --release --qmldir qml path\to\ImageBrowser.exe`。

## 美学环境安装
关键词: setup_aesthetics Python venv 依赖 安装 collection

1. 在项目根目录运行 `scripts\setup_aesthetics.bat`。
2. 脚本创建 `aesthetics\venv`、克隆 EAT 代码、安装 PyTorch 与依赖。
3. 将下载的 EAT 权重放到 `aesthetics\weights\finetune.pth`。
4. 有 NVIDIA 显卡时脚本会尝试安装 CUDA 版 PyTorch。
5. 详见 `docs\aesthetics.md`。

## 打包发布
关键词: 打包 pack 安装包 zip 便携 Inno Setup

- 根目录运行 `pack.bat`（等同 `scripts\package.bat`）。
- 自动：Release 构建 → windeployqt 部署 → 复制 aesthetics → 生成便携 ZIP 与 Setup.exe。
- 输出：`dist\ImageBrowser\`（便携目录）、`output\*.zip`、`output\*_Setup.exe`。
- 环境变量：`SKIP_BUILD=1` 跳过编译；`SKIP_INSTALLER=1` 不生成安装包；`INCLUDE_VENV=1` 打包 Python 虚拟环境（体积很大）。

## 测试
关键词: 测试 test 单元测试 报告

- 运行 `scripts\run_tests.bat` 执行全部自动化测试。
- `scripts\run_tests.bat --report` 生成 HTML 测试报告。
- 文档见 `docs\testing.md`。

## 常见问题
关键词: 慢 卡顿 CUDA 不显示 报错 无法 失败 问题

**AI 点评或美学评分很慢？**
可能是 CPU 版 PyTorch。检查 `aesthetics\venv` 中 `python -c "import torch; print(torch.cuda.is_available())"` 是否为 True；若为 False 需重装 CUDA 版 torch，并确保 config.json 中 device/qsit_device 为 cuda。

**左上角没有美学分数？**
确认已运行 setup_aesthetics.bat、权重文件存在，且 aesthetics 目录与 exe 同级（打包后会自动复制）。

**找不到 Python / 模型加载失败？**
在开发目录运行 setup 脚本；便携包需在目标机器运行 `aesthetics\setup_aesthetics.bat` 或设置 INCLUDE_VENV=1 打包 venv。

**GitHub / 反馈**
项目主页：https://github.com/vf2e/ImageBrowser
问题反馈：https://github.com/vf2e/ImageBrowser/issues

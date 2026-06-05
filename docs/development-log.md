# ImageBrowser 项目开发日志

本文档记录 ImageBrowser 从立项到当前版本的**完整开发历程**，包括功能演进、架构决策、问题修复、测试与构建体系建设。面向维护者与贡献者，便于追溯「为什么这样设计」以及「某次改动解决了什么问题」。

**维护约定**：每次发布版本或完成重要里程碑时，在文末「变更记录」追加条目。

---

## 目录

1. [项目概览](#1-项目概览)
2. [技术栈与仓库结构](#2-技术栈与仓库结构)
3. [开发时间线](#3-开发时间线)
4. [架构演进](#4-架构演进)
5. [功能模块开发记录](#5-功能模块开发记录)
6. [问题修复日志](#6-问题修复日志)
7. [测试体系建设](#7-测试体系建设)
8. [构建与发布演进](#8-构建与发布演进)
9. [已知限制与后续规划](#9-已知限制与后续规划)
10. [变更记录（Changelog）](#10-变更记录changelog)

---

## 1. 项目概览

| 项 | 内容 |
|----|------|
| 项目名称 | ImageBrowser（图片浏览器） |
| 作者 | Wang Chang |
| 仓库 | https://github.com/vf2e/ImageBrowser |
| 当前版本 | v1.0.0（README 发布说明）/ v1.0.1（Release 下载链接） |
| 定位 | Windows 桌面沉浸式图片浏览、收藏与导出工具 |
| 许可证 | MIT |

### 1.1 产品目标

- 最大化图片展示区域（悬浮工具栏，非传统菜单栏）
- 流畅浏览大量本地图片（异步解码、双缓冲切换）
- 轻量收藏工作流（快捷键 + 持久化 + 一键导出）
- 记住最近打开的文件夹与浏览进度

### 1.2 非目标（当前版本）

- 图片编辑、EXIF 信息面板
- 网络相册、云同步
- 跨平台官方支持（代码可移植，但脚本与安装包以 Windows 为主）

---

## 2. 技术栈与仓库结构

### 2.1 核心技术

| 层级 | 技术 |
|------|------|
| 语言 | C++11 |
| UI | QML 2.15 / Qt Quick Controls 2.15 |
| 特效 | QtGraphicalEffects（阴影、渐变、OpacityMask） |
| 异步 | QtConcurrent（导出复制） |
| 持久化 | QSettings（最近目录）、INI（浏览进度）、UTF-8 文本（收藏列表） |
| 构建 | CMake 3.16+（由 qmake 迁移） |
| 部署 | windeployqt + Inno Setup 6 |

### 2.2 当前目录结构（2026-06）

```
ImageBrowser/
├── src/
│   ├── main.cpp
│   └── backend/ImageBrowserBackend.{h,cpp}
├── qml/
│   ├── main.qml
│   └── components/          # 7 个 UI 组件
├── tests/                   # C++ 与 QML 自动化测试
├── docs/                    # 迁移、测试、开发日志
├── scripts/                 # build_release / run_tests / package
├── installer/               # Inno Setup 脚本与中文语言包
├── assets/                  # 图标与预览图
├── CMakeLists.txt
└── qml.qrc
```

---

## 3. 开发时间线

以下按 Git 历史与开发阶段整理（`git log --oneline`）。

### 阶段一：项目启动与基础浏览（早期提交）

| 提交 / 阶段 | 内容 |
|-------------|------|
| `e6b1eb0` | 添加 README，确立项目说明与构建指引 |
| `d64e908` | 完善 README 构建与部署说明 |
| `e38b7d1` | 添加预览图与 README 展示区块 |
| 初始架构 | 单文件 `main.qml` + `ImageBrowserBackend`，实现文件夹选择与图片列表 |

**成果**：可打开本地文件夹、浏览图片的基础能力。

### 阶段二：体验打磨与最近目录（2024 Q1 前后）

| 提交 | 内容 |
|------|------|
| `4a1f38c` | **最近文件夹菜单** + QSettings 持久化（最多 5 条、去重、前置） |
| `ab2a140` | 资源目录整理，更新 Qt Creator 工程配置 |
| `ff64352` | **双缓冲图片切换**（oldImage / newImage 交叉淡入） |
| `33f857e` | UI 重构：常驻顶/底工具栏、Slider 进度条、动画 |
| `5996b6a` | Qt Creator 工程更新、信号发射顺序调整 |
| `ed4b03e` | 禁用图片淡入淡出动画（改为即时切换，减少卡顿感） |

**成果**：现代悬浮 UI、浏览进度可感知、最近目录可快速回访。

### 阶段三：收藏、导出与语义化反馈

| 功能 | 实现要点 |
|------|----------|
| 收藏 | `QSet<QString>` 内存集合 + `favorites.txt`（UTF-8 文件名） |
| 浏览进度 | `browser_config.ini`：`LastIndex` + `LastFileName` 双重恢复 |
| 导出 | `QtConcurrent::run` 异步复制到 `D:/收藏/{文件夹名}/` |
| Toast | `ToastMessage.qml`：`fav` / `unfav` / `info` 三色语义 |
| 快捷键 | `main.qml` 统一分发：←→ 翻页，Space/↑/↓ 收藏，滚轮/右键 |

### 阶段四：工程化重构（2024–2026）

| 日期 / 事件 | 内容 |
|-------------|------|
| `e157d06` | **QML 组件化**：879 行 `main.qml` 拆为 7 个 `components/*.qml` |
| 同阶段 | 添加 **Inno Setup** 一键打包（`installer/ImageBrowser.iss`） |
| `ea0d317` | **qmake → CMake** 迁移，删除 `ImageBrowser.pro` |
| 2026-06 | 编写 `docs/qmake-to-cmake-migration.md` 完整迁移文档 |
| 2026-06 | 建立 **Qt Test + Qt Quick Test** 双层测试（48→63 用例） |
| 2026-06 | 添加 GitHub Actions CI（Windows + Qt 5.15.2） |
| 2026-06 | 本文档 `development-log.md` 与测试文档体系 |

---

## 4. 架构演进

### 4.1 后端（ImageBrowserBackend）

```
QML (controller/backend)
        │ 属性绑定 / 槽调用
        ▼
ImageBrowserBackend (QObject)
        ├── 文件夹扫描 (QDir + 扩展名过滤)
        ├── 索引导航 (循环 next/prev)
        ├── 收藏 (QSet + favorites.txt)
        ├── 进度 (browser_config.ini)
        ├── 最近目录 (QSettings RecentFolders)
        └── 导出 (QtConcurrent + notifyExportComplete)
```

**可测试性扩展**（不影响生产默认行为）：

| 接口 | 用途 |
|------|------|
| 构造注入 `settingsOrganization/Application` | 测试隔离 QSettings |
| `setExportDestRoot()` | 导出目录重定向到临时路径 |
| `setSettingsScope()` | 运行时切换 settings 作用域 |
| `setFolderPicker()` | 替换 `QFileDialog`，使 `selectFolder()` 可单测 |

### 4.2 前端（QML 组件化）

| 组件 | 职责 |
|------|------|
| `main.qml` | `ApplicationWindow`、键盘事件、`Connections` → Toast |
| `BackgroundGradient` | 全屏径向渐变背景 |
| `ImageViewer` | 图片显示、双缓冲、收藏角标、滚轮/右键 |
| `EmptyPlaceholder` | 无图时占位，点击打开最近菜单或选文件夹 |
| `TopToolbar` | 路径、收藏计数、导出按钮 |
| `BottomToolbar` | 页码与 Slider |
| `RecentFolderPopup` | 最近目录 Popup + 浏览本地 |
| `ToastMessage` | 底部浮层消息 |

**组件通信约定**：

- 统一使用 `required property var controller`（避免 `backend: backend` 绑定循环）
- 子组件通过 `signal requestFocus()` 将焦点还给 `mainContainer`（保证快捷键生效）

### 4.3 构建系统迁移摘要

详见 [qmake-to-cmake-migration.md](qmake-to-cmake-migration.md)。

| 项目 | qmake | CMake |
|------|-------|-------|
| 入口 | `ImageBrowser.pro` | `CMakeLists.txt` |
| 测试 | 无 | `tests/` + `IMAGEBROWSER_BUILD_TESTS` |
| 产物路径 | `build-release/release/` | `build-release/`（NMake） |
| UTF-8 | `/utf-8` 编译选项 | 同等配置 |

---

## 5. 功能模块开发记录

### 5.1 文件夹加载

- 支持扩展名：`jpg/jpeg/png/bmp/gif/webp`
- 不存在目录：Toast 提示 + 从最近列表移除
- 加载时：清空内存收藏 → 读 `favorites.txt` → 读 `browser_config.ini` 恢复索引

### 5.2 导航与进度

- `nextImage` / `previousImage` 循环索引
- `setCurrentIndex` 忽略越界与重复索引（不重复发信号）
- 进度优先按 **文件名** 匹配，失败则回退 **保存的索引**

### 5.3 收藏系统

- 切换当前图收藏状态，写入 `favorites.txt`（仅文件名，UTF-8）
- 重新加载时按文件名拼绝对路径，跳过已删除文件
- **文件夹隔离**：切换相册后收藏集合独立（各相册自己的 `favorites.txt`）

### 5.4 最近目录

- 每次成功 `loadFolder`：去重 → `prepend` → 截断至 5 条
- 持久化键：`QSettings("WangChang", "ImageBrowser")` / `RecentFolders`

### 5.5 导出

- 无收藏：同步 `showMessage(info)`
- 有收藏：`mkpath` 目标目录 → 后台线程复制（跳过已存在文件）→ `notifyExportComplete`
- 默认目标：`D:/收藏/{当前文件夹名}/`

### 5.6 打包发布

`scripts/package.bat` 流程：

1. `build_release.bat` → CMake Release 构建
2. `windeployqt --qmldir qml` → `dist/ImageBrowser/`
3. `ISCC.exe installer/ImageBrowser.iss` → `output/*_Setup.exe`

---

## 6. 问题修复日志

开发过程中遇到的主要问题与解决方案：

| 问题 | 现象 | 根因 | 修复 |
|------|------|------|------|
| QML 类型未找到 | `ApplicationWindow` / `RadialGradient` 报错 | 缺少 Controls / GraphicalEffects 导入或部署 | 补全 import；`windeployqt --qmldir` |
| 中文 Toast 乱码 | 收藏提示显示异常 | 字符串编码与 `tr()` 混用 | 使用 `QString::fromUtf8(u8"...")` + `showMessage` |
| `backend` 为 null | QML 绑定失败 | 上下文注入时机或绑定循环 | 组件改用 `controller`；`main.cpp` 堆分配 backend |
| QML 绑定循环 | 控制台警告、性能问题 | `backend: backend` 自引用 | 重命名为 `controller` 必填属性 |
| 打包脚本路径错误 | 找不到 exe / 目录错位 | `PROJECT_ROOT` 多写 `..\` | 统一 `%~dp0..` + 子路径拼接 |
| 测试 recentFolders 失败 | 跨实例持久化断言失败 | 第二个 `TestFixture` 执行 `settings.clear()` | 增加 `clearSettings=false` 参数 |
| QML 测试无输出崩溃 | `tst_qml` 退出码 1 | 缺少 `QT_PLUGIN_PATH`；Windows 宏路径 `\t` 转义 | 配置插件路径；CMake 正斜杠；offscreen 平台 |
| QML `visible` 断言失败 | headless 下 visible 为 false | `layer.effect` 在 offscreen 不可靠 | 改断言绑定表达式（`imageCount > 0` 等） |

---

## 7. 测试体系建设

详见 [testing.md](testing.md) 与 [testing-testcases.md](testing-testcases.md)。

### 7.1 演进阶段

| 阶段 | 内容 |
|------|------|
| v0 | 无自动化测试，手工验证 |
| v1 | Qt Test 覆盖 `ImageBrowserBackend`（38 用例） |
| v2 | 修复 TestFixture 隔离、导出异步 spy 时序 |
| v3 | Qt Quick Test + MockBackend（10→15 用例） |
| v4 | 补强边界/信号/集成用例；`setFolderPicker`；CI 上线 |
| v5 | 键盘 C++ 集成测试 + BackgroundGradient + 覆盖率脚本 |
| **当前** | **C++ 52 + QML 17 = 69 业务用例** |

### 7.2 测试命令

```bat
scripts\run_tests.bat
cd build-release && ctest -C Release --output-on-failure
```

### 7.3 仍未自动化覆盖

- 真实 `QFileDialog` UI 交互（已用 `setFolderPicker` 绕过）
- `Image` 解码与双缓冲动画视觉效果
- `main.qml` 键盘快捷键端到端
- 安装包与安装后首次启动冒烟

---

## 8. 构建与发布演进

| 时期 | 构建方式 | 打包 |
|------|----------|------|
| 早期 | qmake + nmake | 手动 windeployqt |
| 当前 | CMake + NMake / Ninja | `package.bat` + Inno Setup |
| CI | GitHub Actions `windows-latest` | 仅跑测试，不产安装包 |

### 8.1 环境变量

| 变量 | 说明 |
|------|------|
| `QT_DIR` | Qt 5.15.2 msvc2019_64 根目录 |
| `QT_PLUGIN_PATH` | 测试运行需要（`run_tests.bat` 已设置） |
| `QT_QPA_PLATFORM` | 测试使用 `offscreen` |

### 8.2 关键脚本

| 脚本 | 作用 |
|------|------|
| `scripts/build_release.bat` | Release 构建主程序 |
| `scripts/run_tests.bat` | 构建并运行全部测试 |
| `scripts/package.bat` | 构建 + 部署 + 安装包 |

---

## 9. 已知限制与后续规划

### 9.1 当前限制

- 导出默认路径写死为 `D:/收藏`（Windows 盘符假设）
- 图片列表顺序依赖 `QDir::entryInfoList` 默认排序，未提供 UI 排序选项
- 单元测试无代码覆盖率报告（gcov/OpenCppCoverage 未接入）
- QML 测试不覆盖视觉回归（截图对比）

### 9.2 建议路线图

| 优先级 | 项 |
|--------|-----|
| P1 | 导出路径可配置（设置页或首次导出选择） |
| P1 | `main.qml` 快捷键 Qt Quick Test 或 GUI 自动化 |
| P2 | 覆盖率报告接入 CI |
| P2 | Linux/macOS 构建脚本与 CI matrix |
| P3 | 缩略图模式 / 筛选仅收藏 |

---

## 10. 变更记录（Changelog）

### 2026-06-06 — 键盘集成与覆盖率

**测试**

- `tst_keyboard_integration`（4 用例）：`KeyboardHarness.qml` + 真实后端 + `QTest::keyClick`
- `tst_backgroundgradient.qml`（2 用例）：补全第 7 个 QML 组件
- `scripts/run_coverage.bat` + `docs/coverage.md`（OpenCppCoverage）
- CMake 选项 `IMAGEBROWSER_ENABLE_COVERAGE`

---

### 2026-06-06 — 测试补强与开发日志

**测试（C++ 新增 10 用例）**

- `selectFolder_usesInjectedPicker` / `selectFolder_emptyPickerResult_doesNothing`
- `favorites_multipleImages_trackedIndependently` / `favorites_isolatedPerFolder`
- `loadFolder_emitsRecentFoldersChanged` / `toggleFavorite_emitsIsCurrentFavoriteChanged` / `loadFolder_emitsCurrentIndexChanged`
- `exportFavorites_mkpathFailure_emitsMessage`
- `workflow_loadNavigateFavoriteAndExport`（端到端工作流）

**测试（QML 新增 5 用例）**

- `tst_imageviewer.qml`（3）
- `tst_recentfolderpopup.qml`（2）

**后端**

- 新增 `setFolderPicker(std::function<QString()>)` 用于可测试的 `selectFolder()`

**文档**

- 新增 `docs/development-log.md`（本文档）
- 更新 `testing.md`、`testing-testcases.md`、README

---

### 2026-06-06 — 测试体系初建

- 38 个 C++ 后端用例 + 10 个 QML 用例
- `TestFixture` 测试夹具与 QSettings 隔离
- `scripts/run_tests.bat`、GitHub Actions CI
- `docs/testing.md`、`docs/testing-testcases.md`

---

### 2026-06 — CMake 迁移

- 删除 `ImageBrowser.pro`，新增 `CMakeLists.txt`
- `docs/qmake-to-cmake-migration.md`
- 更新 `build_release.bat`

---

### 2024 — QML 组件化与安装包

- 拆分 7 个 QML 组件
- Inno Setup 安装脚本与 `package.bat`
- 修复打包路径、中文编码、绑定循环等问题

---

### 2024 Q1 — 核心体验版本

- 最近目录、双缓冲浏览、悬浮工具栏
- 收藏 / 导出 / Toast 反馈
- 快捷键与鼠标交互

---

### 项目 inception

- README、预览资源、初始 ImageBrowser 实现

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [README.md](../README.md) | 用户向项目说明 |
| [testing.md](testing.md) | 测试运行与架构 |
| [testing-testcases.md](testing-testcases.md) | 全量用例明细 |
| [coverage.md](coverage.md) | C++ 覆盖率指南 |
| [qmake-to-cmake-migration.md](qmake-to-cmake-migration.md) | 构建迁移记录 |

---

*最后更新：2026-06-06*

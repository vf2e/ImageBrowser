# ImageBrowser 项目说明文档

## 1. 项目简介

ImageBrowser 是一款基于 Qt 5.15 框架开发的沉浸式图片浏览器。本项目采用 C++ 与 QML 结合的架构，专注于提供极简且高效的视觉体验。通过异步加载机制与着色器特效，在保证大尺寸图像流畅预览的同时，提供了具有现代感的 UI 交互。

<div align="center">
  <h3>✨ 沉浸式浏览体验</h3>
  <img src="https://github.com/vf2e/ImageBrowser/blob/main/assets/images/preview.png" alt="主界面预览" width="800"/>
</div>

## 2. 核心特性

- **沉浸式 UI 交互**：工具栏与进度条采用悬浮岛屿式设计，最大化图片展示区域。
- **语义化反馈系统**：针对收藏与取消操作，设计了基于色彩心理学的 Toast 提示组件，提供即时的视觉确认。
- **高性能渲染**：基于 QtConcurrent 异步加载技术，避免图像解码过程阻塞主界面，支持平滑的透明度切换动画。
- **高效筛选机制**：集成收藏夹功能，支持一键精选导出，优化摄影后期或素材整理的工作流。

## 3. 快捷键指南

| 操作项目 | 对应按键 |
|---------|---------|
| 切换下一张 / 上一张 | 方向键右 (→) / 方向键左 (←) |
| 收藏 / 取消收藏当前图片 | 空格键 (Space) / 方向键上 (↑) / 方向键下 (↓) |
| 快速翻页 | 鼠标滚轮 |
| 切换收藏状态 | 鼠标右键点击图片区域 |

## 4. 技术栈

- **核心框架**：Qt 5.15.2 (C++ 11)
- **界面技术**：QML / QtQuick 2.15 / QtGraphicalEffects
- **异步处理**：QtConcurrent
- **构建系统**：CMake 3.16+
- **部署工具**：windeployqt + Inno Setup 6 (Windows 安装程序)

## 5. 项目结构

```
ImageBrowser/
├── src/                        # C++ 源码
│   ├── main.cpp                # 程序入口，注册 QML 上下文
│   └── backend/
│       ├── ImageBrowserBackend.h
│       └── ImageBrowserBackend.cpp
├── qml/                        # QML 界面
│   ├── main.qml                # 应用入口（窗口组装与信号连接）
│   └── components/             # UI 组件
│       ├── BackgroundGradient.qml
│       ├── ImageViewer.qml
│       ├── EmptyPlaceholder.qml
│       ├── TopToolbar.qml
│       ├── BottomToolbar.qml
│       ├── RecentFolderPopup.qml
│       └── ToastMessage.qml
├── assets/                     # 静态资源
│   └── icons/logo.ico
├── installer/
│   └── ImageBrowser.iss        # Inno Setup 安装脚本
├── docs/
│   ├── qmake-to-cmake-migration.md  # qmake 转 CMake 迁移文档
│   ├── testing.md                   # 测试体系总览与运行指南
│   ├── testing-testcases.md         # 全量用例明细（69 条）
│   ├── testing-report.md            # HTML 测试报告生成指南
│   ├── coverage.md                  # C++ 覆盖率报告指南
│   └── development-log.md           # 项目开发日志（详细）
├── tests/
│   ├── tst_imagebrowserbackend.cpp  # C++ 后端单元测试（38 用例）
│   ├── tst_qml.cpp                  # QML 组件测试入口
│   ├── TestFixture.h                # C++ 测试夹具
│   └── qml/                         # QML 测试用例与 MockBackend
├── scripts/
│   ├── build_release.bat       # CMake Release 构建
│   ├── run_tests.bat           # 一键运行全部测试（--report 生成 HTML）
│   ├── generate_test_report.bat # 构建 + 测试 + HTML 报告
│   ├── run_coverage.bat        # C++ 覆盖率（OpenCppCoverage）
│   └── package.bat             # 一键打包（构建 + 部署 + 安装包）
├── CMakeLists.txt
└── qml.qrc
```

### 架构说明

- **C++ 后端**（`src/backend/`）：负责文件夹扫描、图片索引、收藏持久化、进度保存、异步导出等业务逻辑，通过 `backend` 全局对象暴露给 QML。
- **QML 入口**（`qml/main.qml`）：仅负责窗口布局、键盘事件分发和组件间信号连接，不包含具体 UI 实现。
- **QML 组件**（`qml/components/`）：按功能拆分的独立 UI 模块，各组件通过 `backend` 属性和信号与后端通信。

## 6. 下载与安装

### 最新版本下载

[⬇️ 点击下载 ImageBrowser v1.0.1 安装包 (Windows)](https://github.com/vf2e/ImageBrowser/releases/download/V1.0.1/ImageBrowser_v1.0.1_Setup.exe)

### 环境要求

- 操作系统：Windows 10/11
- 依赖运行库：Microsoft Visual C++ 2019 Redistributable

### 安装说明

1. 下载安装包后双击运行
2. 按照安装向导提示完成安装
3. 可选择创建桌面快捷方式
4. 安装完成后即可从开始菜单或桌面快捷方式启动

## 7. 从源码构建

### 开发环境要求

- Windows 10/11
- Qt 5.15.2（推荐使用 MSVC 2019 64-bit 编译器）
- CMake 3.16+
- Visual Studio 2019/2022（含 C++ 桌面开发工作负载）
- Qt Creator（可选，但推荐）
- Inno Setup 6（打包安装包时需要）

### 方式一：Qt Creator（推荐）

1. 克隆源码仓库：
   ```bash
   git clone https://github.com/vf2e/ImageBrowser.git
   cd ImageBrowser
   ```
2. 使用 Qt Creator 打开 `CMakeLists.txt`
3. 选择 Kit：`Desktop Qt 5.15.2 MSVC2019 64bit`
4. 构建并运行

> 若 IDE 提示 QML 类型无法识别，可在 Qt Creator 中将 QML 导入路径配置为项目下的 `qml/` 目录。

### 方式二：命令行构建（CMake）

```bat
scripts\build_release.bat
```

或手动执行：

```bat
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
cmake -S . -B build-release -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%QT_DIR%
cmake --build build-release --config Release
```

构建产物位于 `build-release\ImageBrowser.exe`（NMake/Ninja）或 `build-release\Release\ImageBrowser.exe`（Visual Studio 生成器）。

> qmake 转 CMake 的完整过程见 [docs/qmake-to-cmake-migration.md](docs/qmake-to-cmake-migration.md)。

### 单元测试

项目包含三层自动化测试，合计 **69** 个用例：

| 套件 | 框架 | 用例数 | 覆盖范围 |
|------|------|--------|----------|
| `tst_imagebrowserbackend` | Qt Test | 48 | 后端业务逻辑、信号、集成工作流 |
| `tst_keyboard_integration` | Qt Test + QML | 4 | `main.qml` 快捷键与真实后端联动 |
| `tst_qml` | Qt Quick Test | 17 | 全部 7 个 QML 组件绑定 |

**常用命令（防忘）：**

```bat
scripts\run_tests.bat                  :: 跑完全部测试
scripts\run_tests.bat --report         :: 跑测试 + 生成 HTML 报告
scripts\generate_test_report.bat --open :: 构建、测试并打开报告
scripts\run_coverage.bat              :: C++ 覆盖率（需 OpenCppCoverage）
```

成功时控制台显示 `[OK] All tests passed`。报告与日志在 `build-release/tests/`、`build-release/test-report/`。

**文档：**

- **运行方式速查（推荐收藏）**：[docs/testing.md#运行方式速查](docs/testing.md#运行方式速查)
- 测试总览与故障排查：[docs/testing.md](docs/testing.md)
- HTML 测试报告：[docs/testing-report.md](docs/testing-report.md)
- 逐用例前置条件与断言：[docs/testing-testcases.md](docs/testing-testcases.md)
- 代码覆盖率：[docs/coverage.md](docs/coverage.md)
- 开发历程与技术决策：[docs/development-log.md](docs/development-log.md)

手动部署 Qt 依赖：

```bat
windeployqt --release --qmldir qml path\to\ImageBrowser.exe
```

## 8. 一键打包

项目内置 Inno Setup 打包流程，执行：

```bat
scripts\package.bat
```

脚本自动完成以下步骤：

1. **Release 构建** — 编译生成 `ImageBrowser.exe`
2. **依赖部署** — 调用 `windeployqt --qmldir qml` 收集 Qt 运行时和 QML 模块
3. **生成安装包** — 调用 Inno Setup 编译 `installer\ImageBrowser.iss`

输出目录：

| 路径 | 说明 |
|------|------|
| `dist\ImageBrowser\` | 可直接运行的便携部署目录 |
| `output\ImageBrowser_v1.0.0_Setup.exe` | Windows 安装包 |

### 环境变量（可选）

若 Qt 或 Inno Setup 不在默认路径，可通过环境变量覆盖：

```bat
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
```

Inno Setup 默认搜索路径：

- `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- `C:\Program Files\Inno Setup 6\ISCC.exe`

若未检测到 Inno Setup，`package.bat` 仍会完成构建和 `dist` 部署，并提示手动编译 `installer\ImageBrowser.iss`。

## 9. 版本历史

### v1.0.0 (2024-03-03)

- 初始版本发布
- 实现沉浸式悬浮工具栏
- 支持图片收藏与导出功能
- 完整的键盘快捷键支持
- 异步加载保证流畅体验

## 10. 许可协议

本项目采用 MIT License 开源协议。详情请参阅项目根目录下的 LICENSE 文件。

## 11. 开发者信息

- 作者：Wang Chang
- 项目主页：https://github.com/vf2e/ImageBrowser
- 问题反馈：[Issues](https://github.com/vf2e/ImageBrowser/issues)

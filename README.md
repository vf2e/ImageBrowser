# ImageBrowser 项目说明文档

## 1. 项目简介

ImageBrowser 是一款基于 Qt 5.15 框架开发的沉浸式图片浏览器。本项目采用 C++ 与 QML 结合的架构，专注于提供极简且高效的视觉体验。通过异步加载机制与着色器特效，在保证大尺寸图像流畅预览的同时，提供了具有现代感的 UI 交互。

## 2. 核心特性

- **沉浸式 UI 交互**：工具栏与进度条采用悬浮岛屿式设计，支持边缘触发自动显隐，最大化图片展示区域。

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
| 唤醒工具栏 | 鼠标移动至窗口顶部或底部边缘 |

## 4. 技术栈

- **核心框架**：Qt 5.15.2 (C++ 11)
- **界面技术**：QML / QtQuick 2.15 / QtGraphicalEffects
- **异步处理**：QtConcurrent
- **部署工具**：Inno Setup 6 (Windows 安装程序)

## 5. 下载与安装

### 最新版本下载

[⬇️ 点击下载 ImageBrowser v1.0.0 安装包 (Windows)](https://github.com/vf2e/ImageBrowser/releases/download/V1.0.0/ImageBrowser_v1.0.0_Setup.exe)

### 环境要求

- 操作系统：Windows 10/11
- 依赖运行库：Microsoft Visual C++ 2019 Redistributable

### 安装说明

1. 下载安装包后双击运行
2. 按照安装向导提示完成安装
3. 可选择创建桌面快捷方式和文件关联
4. 安装完成后即可从开始菜单或桌面快捷方式启动

## 6. 从源码构建

### 开发环境要求

- Windows 10/11
- Qt 5.15.2 (推荐使用 MSVC 2019 编译器)
- Qt Creator (可选，但推荐)

### 构建步骤

1. 克隆源码仓库：
   ```bash
   git clone https://github.com/vf2e/ImageBrowser.git
   ```
使用 Qt Creator 打开 ImageBrowser.pro 工程文件

执行构建并生成二进制文件

部署依赖：

bash
windeployqt --qmldir <QML目录路径> ImageBrowser.exe

版本历史
v1.0.0 (2024-03-03)
✨ 初始版本发布

🎨 实现沉浸式悬浮工具栏

⭐ 支持图片收藏与导出功能

⌨️ 完整的键盘快捷键支持

🚀 异步加载保证流畅体验

## 7. 许可协议
本项目采用 MIT License 开源协议。详情请参阅项目根目录下的 LICENSE 文件。

## 8. 开发者信息
作者：Wang Chang

项目主页：https://github.com/vf2e/ImageBrowser

问题反馈：Issues

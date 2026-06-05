# ImageBrowser：qmake 转 CMake 迁移记录

本文档详细记录 ImageBrowser 项目从 **qmake（`.pro`）** 迁移到 **CMake（`CMakeLists.txt`）** 的完整过程，包括配置对照、构建方式变更、验证步骤与常见问题。

---

## 1. 迁移背景

### 1.1 为什么要迁移

| 维度 | qmake | CMake |
|------|-------|-------|
| 跨平台构建 | 依赖 Qt 生态 | 行业标准，IDE/CI 广泛支持 |
| 依赖管理 | 手工维护 `.pro` | `find_package` 更清晰 |
| CI/CD 集成 | 需额外适配 | GitHub Actions、Azure Pipelines 等原生支持 |
| Qt Creator | 支持 | 原生支持，且为推荐方式 |
| 现代工具链 | 逐渐边缘化 | 与 Ninja、VS、Clang 配合更好 |

ImageBrowser 作为开源项目，迁移到 CMake 有利于：

- 统一命令行与 IDE 构建流程
- 降低新贡献者上手成本
- 为后续引入更多模块（如 AI 筛选）预留扩展空间

### 1.2 迁移原则

- **功能不变**：不修改业务逻辑与 QML 界面行为
- **产物一致**：仍生成 `ImageBrowser.exe`，打包流程不变
- **最小改动**：仅替换构建系统，不重写源码结构

---

## 2. 迁移前项目状态（qmake）

### 2.1 原有 `ImageBrowser.pro` 完整内容

```qmake
QT += quick widgets concurrent

CONFIG += c++11

win32-msvc*: QMAKE_CXXFLAGS += /utf-8
win32-g++*: QMAKE_CXXFLAGS += -finput-charset=UTF-8 -fexec-charset=UTF-8

RC_ICONS = assets/icons/logo.ico

DEFINES += QT_DEPRECATED_WARNINGS

INCLUDEPATH += src/backend

SOURCES += \
        src/main.cpp \
        src/backend/ImageBrowserBackend.cpp

HEADERS += \
        src/backend/ImageBrowserBackend.h

RESOURCES += qml.qrc

QML_IMPORT_PATH =
QML_DESIGNER_IMPORT_PATH =

qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
```

### 2.2 原有构建方式

```bat
qmake ImageBrowser.pro -spec win32-msvc "CONFIG+=release"
nmake release
```

产物路径（qmake + MSVC）：

```
build-release/release/ImageBrowser.exe
```

### 2.3 原有资源与依赖

- **Qt 模块**：Quick、Widgets、Concurrent
- **C++ 标准**：C++11
- **资源文件**：`qml.qrc`（QML 组件 + 图标）
- **Windows 图标**：`RC_ICONS = assets/icons/logo.ico`
- **头文件搜索路径**：`src/backend`

---

## 3. qmake → CMake 配置对照表

| qmake 配置 | CMake 等价写法 | 说明 |
|------------|----------------|------|
| `QT += quick widgets concurrent` | `find_package(Qt5 ... Quick Widgets Concurrent)` + `target_link_libraries(... Qt5::Quick Qt5::Widgets Qt5::Concurrent)` | 显式声明并链接模块 |
| `CONFIG += c++11` | `set(CMAKE_CXX_STANDARD 11)` | 全局 C++ 标准 |
| `SOURCES += ...` | `set(IMAGEBROWSER_SOURCES ...)` + `add_executable(...)` | 源文件列表 |
| `HEADERS += ...` | 加入 `add_executable` 参数 | 触发 AUTOMOC |
| `RESOURCES += qml.qrc` | 加入 `add_executable` 参数 | 配合 `CMAKE_AUTORCC ON` |
| `INCLUDEPATH += src/backend` | `target_include_directories(... PRIVATE src/backend)` | 仅本目标生效，更精确 |
| `DEFINES += QT_DEPRECATED_WARNINGS` | `target_compile_definitions(... PRIVATE QT_DEPRECATED_WARNINGS)` | 编译宏 |
| `win32-msvc*: QMAKE_CXXFLAGS += /utf-8` | `if(MSVC) target_compile_options(... /utf-8)` | MSVC UTF-8 源文件 |
| `win32-g++*: QMAKE_CXXFLAGS += ...` | `elseif(MINGW) target_compile_options(...)` | MinGW UTF-8 |
| `RC_ICONS = assets/icons/logo.ico` | 生成 `ImageBrowser.rc` 并 `target_sources` | 见下文第 4.3 节 |
| `TARGET = ImageBrowser`（默认） | `project(ImageBrowser)` + `add_executable(ImageBrowser ...)` | 目标名一致 |
| `QML_IMPORT_PATH`（空） | 无需配置 | 运行时由 `qrc:/` 加载 |
| `INSTALLS`（Linux 安装路径） | 暂未迁移 | Windows 项目以 Inno Setup 打包为主 |

---

## 4. 新 CMake 工程详解

### 4.1 根目录 `CMakeLists.txt`

迁移后的核心结构：

```cmake
cmake_minimum_required(VERSION 3.16)
project(ImageBrowser VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 5.15 REQUIRED COMPONENTS Core Quick Widgets Concurrent)

add_executable(ImageBrowser WIN32
    src/main.cpp
    src/backend/ImageBrowserBackend.cpp
    src/backend/ImageBrowserBackend.h
    qml.qrc
)

target_include_directories(ImageBrowser PRIVATE src/backend)
target_compile_definitions(ImageBrowser PRIVATE QT_DEPRECATED_WARNINGS)

# UTF-8、Windows 图标、链接 Qt 库 ...
```

### 4.2 关键 CMake 选项说明

#### `CMAKE_AUTOMOC ON`

等价于 qmake 对含 `Q_OBJECT` 头文件自动运行 `moc`。  
`ImageBrowserBackend.h` 含有 `Q_OBJECT`，必须开启。

#### `CMAKE_AUTORCC ON`

等价于 qmake 的 `RESOURCES += qml.qrc`，自动调用 `rcc` 编译资源。

#### `add_executable` + `Qt5::*` 链接

使用标准 `add_executable` 配合 `target_link_libraries(... Qt5::Widgets Qt5::Quick ...)`，由 imported target 自动传递依赖（含 Windows 下的 `qtmain`）。

#### `WIN32` 子系统

生成 Windows GUI 程序（无控制台窗口），与原先 qmake 默认行为一致。

### 4.3 Windows 图标迁移

qmake 写法：

```qmake
RC_ICONS = assets/icons/logo.ico
```

CMake 无一行等价指令，需在配置阶段生成 `.rc` 资源脚本：

```cmake
if(WIN32)
    set(IMAGEBROWSER_RC_FILE ${CMAKE_CURRENT_BINARY_DIR}/ImageBrowser.rc)
    file(WRITE ${IMAGEBROWSER_RC_FILE}
        "IDI_ICON1 ICON \"${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/logo.ico\"\n"
    )
    target_sources(ImageBrowser PRIVATE ${IMAGEBROWSER_RC_FILE})
endif()
```

构建时由 MSVC 资源编译器 `rc.exe` 将图标嵌入可执行文件。

### 4.4 `qml.qrc` 保持不变

资源文件内容未修改，仍通过 `qrc:/qml/main.qml` 加载界面：

```xml
<RCC>
    <qresource prefix="/">
        <file>qml/main.qml</file>
        <file>qml/components/...</file>
        <file>assets/icons/logo.ico</file>
    </qresource>
</RCC>
```

CMake 不需要单独列出每个 QML 文件，只要 `qml.qrc` 已包含即可。

---

## 5. 构建方式变更

### 5.1 命令行构建（推荐）

#### 配置 + 编译（NMake，与原有 MSVC 工具链一致）

```bat
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
call "%VCVARS64%"   REM Visual Studio 环境

mkdir build-release
cd build-release
cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=%QT_DIR%
cmake --build . --config Release
```

产物：

```
build-release/ImageBrowser.exe
```

#### 一键脚本

```bat
scripts\build_release.bat
scripts\package.bat
```

### 5.2 Qt Creator 打开方式

| 迁移前 | 迁移后 |
|--------|--------|
| 打开 `ImageBrowser.pro` | 打开 `CMakeLists.txt` |
| Kit: Desktop Qt 5.15.2 MSVC2019 64bit | 同一 Kit，CMake 自动配置 |
| 构建目录 `build/` | 建议 `build/` 或 `build-release/` |

步骤：

1. **文件 → 打开文件或项目** → 选择 `CMakeLists.txt`
2. 选择 Kit：`Desktop Qt 5.15.2 MSVC2019 64bit`
3. 点击 **构建** → **运行**

### 5.3 生成器选择说明

| 生成器 | 产物路径 | 适用场景 |
|--------|----------|----------|
| `NMake Makefiles` | `build-release/ImageBrowser.exe` | 与现有 `vcvars + nmake` 流程一致（脚本默认） |
| `Ninja` | `build-release/ImageBrowser.exe` | 需安装 Ninja，编译更快 |
| `Visual Studio 17 2022` | `build-release/Release/ImageBrowser.exe` | 多配置，适合 VS IDE 用户 |

可通过环境变量切换：

```bat
set CMAKE_GENERATOR=Ninja
scripts\build_release.bat
```

---

## 6. 脚本改动记录

### 6.1 `scripts/build_release.bat`

| 项目 | qmake 版 | CMake 版 |
|------|----------|----------|
| 配置命令 | `qmake ImageBrowser.pro` | `cmake -S .. -B build-release` |
| 编译命令 | `nmake release` | `cmake --build build-release` |
| 依赖工具 | qmake | cmake + Qt CMake 模块 |
| 产物检测 | 固定 `release/ImageBrowser.exe` | 兼容 `ImageBrowser.exe` 与 `Release/ImageBrowser.exe` |

### 6.2 `scripts/package.bat`

仅更新了可执行文件查找逻辑，以适配 CMake 输出路径；`windeployqt` 与 Inno Setup 流程不变。

---

## 7. 目录结构变化

```diff
 ImageBrowser/
+├── CMakeLists.txt              # 新增：主构建文件
+├── docs/
+│   └── qmake-to-cmake-migration.md
 ├── src/
 ├── qml/
 ├── assets/
 ├── installer/
 ├── scripts/
-│   └── (qmake 构建)
+│   └── (CMake 构建)
-├── ImageBrowser.pro            # 已弃用，可删除
 └── qml.qrc
```

> **说明**：`ImageBrowser.pro` 在迁移完成后已不再作为构建入口。本文档保留其完整内容供查阅，确认 CMake 构建稳定后可从仓库删除。

---

## 8. 迁移操作步骤（复盘）

以下为实际执行的迁移顺序，可供其他 Qt 项目参考：

### 步骤 1：创建 `CMakeLists.txt`

1. 声明 `project(ImageBrowser)`
2. `find_package(Qt5 5.15 REQUIRED COMPONENTS ...)`
3. 列出 `SOURCES`、`HEADERS`、`qml.qrc`
4. `add_executable(ImageBrowser WIN32 ...)`
5. 迁移编译选项（UTF-8、DEFINES、include path）
6. 处理 Windows 图标 `.rc`

### 步骤 2：本地验证

```bat
scripts\build_release.bat
build-release\ImageBrowser.exe
```

确认：

- [ ] 程序正常启动
- [ ] QML 界面加载无报错
- [ ] 文件夹选择、翻页、收藏、导出功能正常
- [ ]  exe 图标正确显示

### 步骤 3：更新脚本与文档

- 修改 `scripts/build_release.bat`
- 修改 `scripts/package.bat` 可执行文件路径
- 更新 `README.md` 构建说明
- 编写本文档

### 步骤 4：验证打包

```bat
scripts\package.bat
```

确认 `dist/ImageBrowser/` 与 `output/*.exe` 正常生成。

### 步骤 5：清理（可选）

- 删除 `ImageBrowser.pro`
- 删除旧 qmake 构建缓存 `build/`、`build-release/Makefile*` 等
- 在 Qt Creator 中改为打开 `CMakeLists.txt`

---

## 9. 常见问题

### Q1：`Could not find a package configuration file provided by "Qt5"`

**原因**：CMake 找不到 Qt 安装路径。

**解决**：

```bat
cmake -B build-release -DCMAKE_PREFIX_PATH=C:\qt5.15.2\5.15.2\msvc2019_64
```

或在 Qt Creator 中确保 Kit 绑定了正确的 Qt 版本。

### Q2：`Project ERROR: Cannot run compiler 'cl'`

**原因**：未加载 Visual Studio 编译环境。

**解决**：先执行 `vcvars64.bat`，或使用已集成 VS 环境的「x64 Native Tools Command Prompt」。

### Q3：MOC 相关链接错误（`undefined reference to vtable`）

**原因**：未开启 `CMAKE_AUTOMOC` 或未将含 `Q_OBJECT` 的头文件加入目标。

**解决**：确认 `ImageBrowserBackend.h` 在 `add_executable` 源文件列表中，且 `CMAKE_AUTOMOC ON`。

### Q4：QML 资源加载失败

**原因**：`qml.qrc` 未加入目标，或 `CMAKE_AUTORCC` 未开启。

**解决**：确认 `qml.qrc` 在 `add_executable` 中，重新 CMake 配置并全量编译。

### Q5：CMake 与 qmake 构建目录冲突

**原因**：同一 `build-release/` 目录混用两套构建系统。

**解决**：清空构建目录后重新配置：

```bat
rmdir /s /q build-release
scripts\build_release.bat
```

### Q6：多配置生成器找不到 exe

**原因**：Visual Studio 生成器输出在 `Release/` 子目录。

**解决**：使用 `build-release/Release/ImageBrowser.exe`，或改用 `NMake Makefiles` 单配置生成器。

### Q7：批处理脚本中 CMake 参数被截断

**原因**：Windows 批处理里，路径末尾的反斜杠会转义闭合引号，例如 `"D:\proj\"` 会导致 `-G "NMake Makefiles"` 解析失败。

**解决**：

- `PROJECT_ROOT` 使用 `%~dp0..`，**不要**写成 `%~dp0..\`
- 子目录拼接使用 `%PROJECT_ROOT%\build-release`，确保中间有反斜杠

---

## 10. 后续可扩展方向

CMake 迁移完成后，可进一步：

```cmake
# 示例：后续添加 AI 筛选模块
# add_subdirectory(src/ai)
# target_link_libraries(ImageBrowser PRIVATE AiSelection)
```

```cmake
# 示例：安装规则（替代 qmake INSTALLS）
# install(TARGETS ImageBrowser RUNTIME DESTINATION bin)
```

```cmake
# 示例：CPack 生成安装包（与 Inno Setup 二选一或并存）
# include(CPack)
```

---

## 11. 总结

| 项目 | 结论 |
|------|------|
| 迁移范围 | 仅构建系统，源码与 QML 无改动 |
| 新构建入口 | `CMakeLists.txt` |
| 推荐生成器 | `NMake Makefiles`（Windows + MSVC） |
| 一键构建 | `scripts\build_release.bat` |
| 一键打包 | `scripts\package.bat` |
| 旧文件 | `ImageBrowser.pro` 已弃用，内容归档于本文档第 2.1 节 |

迁移完成后，ImageBrowser 具备了更通用的构建基础设施，同时保持了原有的功能、资源加载与 Windows 打包流程。

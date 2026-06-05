# ImageBrowser 代码覆盖率指南

本文档说明如何为 **C++ 后端**（`src/backend/`）生成测试覆盖率报告。QML 覆盖率需借助 Qt Quick Test 与手工评估，OpenCppCoverage 仅统计本机代码。

> **单元测试怎么跑**（`run_tests.bat`、单用例、HTML 报告等）见 [testing.md § 运行方式速查](testing.md#运行方式速查)。

---

## 前置条件

| 工具 | 用途 | 安装 |
|------|------|------|
| OpenCppCoverage | Windows/MSVC 覆盖率 | [GitHub Releases](https://github.com/OpenCppCoverage/OpenCppCoverage/releases) |
| Qt 5.15.2 MSVC 64-bit | 运行测试 | 与主项目相同 |
| Visual Studio 2019/2022 | 编译 | 与 `build_release.bat` 相同 |

---

## 一键生成报告（Windows）

```bat
scripts\run_coverage.bat
```

脚本会：

1. 在 `build-coverage/` 以 `IMAGEBROWSER_ENABLE_COVERAGE=ON` 配置 CMake（MSVC 下加 `/Zi` 调试符号）
2. 构建 `tst_imagebrowserbackend`、`tst_keyboard_integration`
3. 用 OpenCppCoverage 运行测试并导出 HTML + Cobertura XML
4. 输出到 `coverage-report/`

打开报告：

```
coverage-report\backend\index.html
coverage-report\keyboard\index.html   （若存在）
```

---

## 手动步骤

```bat
set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
cmake -S . -B build-coverage -G "NMake Makefiles" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=%QT_DIR% ^
  -DIMAGEBROWSER_BUILD_TESTS=ON ^
  -DIMAGEBROWSER_ENABLE_COVERAGE=ON

cmake --build build-coverage --target tst_imagebrowserbackend

"C:\Program Files\OpenCppCoverage\OpenCppCoverage.exe" ^
  --sources D:\opensource\ImageBrowser\src ^
  --export_type html:D:\opensource\ImageBrowser\coverage-report ^
  -- build-coverage\tests\tst_imagebrowserbackend.exe
```

---

## CMake 选项

| 选项 | 默认 | 说明 |
|------|------|------|
| `IMAGEBROWSER_BUILD_TESTS` | ON | 构建测试目标 |
| `IMAGEBROWSER_ENABLE_COVERAGE` | OFF | 为测试目标启用覆盖率友好编译选项 |

MSVC：`/Zi`（调试信息）  
GCC/Clang：`--coverage`（`run_coverage.bat` 当前仅集成 OpenCppCoverage）

---

## 覆盖范围说明

### 会被统计

- `src/backend/ImageBrowserBackend.cpp` 中由测试触发的路径
- 通过 `tst_imagebrowserbackend` 与 `tst_keyboard_integration` 间接执行的代码

### 通常不统计 / 偏低

| 部分 | 原因 |
|------|------|
| `src/main.cpp` | 无单元测试加载完整应用 |
| `selectFolder()` 中 `QFileDialog` 分支 | 生产路径；测试走 `setFolderPicker` |
| QML 文件 | OpenCppCoverage 不分析 QML |
| MOC / 资源编译代码 | 工具默认过滤 |

### 目标参考（非硬性 KPI）

| 模块 | 建议行覆盖率 |
|------|-------------|
| `ImageBrowserBackend.cpp` | ≥ 85% |
| 整体 `src/` | ≥ 70%（含未测 `main.cpp` 会拉低） |

---

## CI 集成（可选）

在 GitHub Actions 中安装 OpenCppCoverage 后：

```yaml
- name: Coverage
  run: scripts\run_coverage.bat
- uses: actions/upload-artifact@v4
  with:
    name: coverage-report
    path: coverage-report/
```

---

## 相关文档

- [testing.md](testing.md) — 测试运行
- [development-log.md](development-log.md) — 测试体系演进

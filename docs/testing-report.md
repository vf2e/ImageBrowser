# 测试报告生成指南

本文说明如何为 ImageBrowser 自动生成**可读性较强**的 HTML 单元测试报告。

> **跑测试命令速查**（含普通测试、覆盖率、单用例等）见 [testing.md § 运行方式速查](testing.md#运行方式速查)。

## 报告内容

报告汇总三套 Qt Test 套件的结果：

| 套件 | 说明 |
|------|------|
| C++ 后端单元测试 | `ImageBrowserBackend` 业务逻辑 |
| QML 组件测试 | UI 组件与 `controller` 绑定 |
| 键盘集成测试 | `main.qml` 快捷键逻辑 |

HTML 报告包含：

- **总体通过率**与进度条
- **按套件分组的卡片**（通过数 / 业务用例数）
- **失败摘要**（若有失败，置顶展示断言信息）
- **可折叠的用例列表**（PASS/FAIL 标签、搜索过滤）
- 原始 **JUnit XML** 链接（`build-release/tests/reports/*.xml`）

生成位置：

```
build-release/test-report/index.html
```

> `build-release` 已在 `.gitignore` 中，报告默认不会进入版本库。CI 可将该目录作为 artifact 上传。

---

## 方式一：测试 + 报告（推荐）

跑完全部测试后，根据 JUnit XML 生成 HTML：

```bat
scripts\run_tests.bat --report
```

等价于：执行 `run_tests.bat` 的全部流程，并在结束时调用 `generate_test_report.ps1 -GenerateOnly`。

---

## 方式二：一键构建、测试、打开报告

单独脚本会完成 CMake 配置、编译、运行测试并生成报告：

```bat
scripts\generate_test_report.bat
```

在浏览器中自动打开报告：

```bat
scripts\generate_test_report.bat --open
```

若测试已跑过且 `build-release/tests/reports/*.xml` 已存在，仅重新生成 HTML：

```bat
scripts\generate_test_report.bat --html-only
scripts\generate_test_report.bat --html-only --open
```

---

## 技术原理

1. **Qt Test 双格式输出**  
   每个测试可执行文件同时写出：
   - 人类可读的 `test-result-*.txt`（`-o file,txt`）
   - 机器可解析的 JUnit XML（`-o file,junitxml`）

2. **PowerShell 汇总**  
   `scripts/generate_test_report.ps1` 解析 XML，排除 `initTestCase` / `cleanupTestCase` 后统计业务用例，再渲染为自包含 HTML（内联 CSS/JS，无外部依赖）。

3. **与覆盖率报告区分**  
   - **测试报告**：用例通过/失败、断言信息 → `test-report/index.html`  
   - **覆盖率报告**：代码行覆盖 → `scripts/run_coverage.bat` → `coverage-report/`（见 [coverage.md](coverage.md)）

---

## CI 集成示例

在 GitHub Actions 中可在测试步骤后生成并上传报告：

```yaml
- name: Run tests with report
  run: scripts\run_tests.bat --report

- name: Upload test report
  uses: actions/upload-artifact@v4
  with:
    name: test-report
    path: build-release/test-report/
```

---

## 故障排查

| 现象 | 处理 |
|------|------|
| 提示找不到 `backend.xml` | 先运行 `run_tests.bat --report` 或 `generate_test_report.bat`（不要用 `--html-only`） |
| PowerShell 执行策略限制 | 脚本已使用 `-ExecutionPolicy Bypass`；若仍失败，以管理员运行 `Set-ExecutionPolicy RemoteSigned` |
| 报告用例数为 0 | 检查 `build-release/tests/reports/*.xml` 是否为空或测试未真正执行 |
| 键盘套件在 CI 失败 | 键盘集成需 `QT_QPA_PLATFORM=windows`；无头 Linux 环境可只跑 backend + qml 再 `--html-only` 合并本地 keyboard 结果 |

---

## 相关文档

- [testing.md](testing.md) — 测试体系与运行方式
- [testing-testcases.md](testing-testcases.md) — 全量用例明细
- [coverage.md](coverage.md) — 代码覆盖率（与测试报告互补）

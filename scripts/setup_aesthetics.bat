@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

set "PROJECT_ROOT=%~dp0.."
set "AEST_DIR=%PROJECT_ROOT%\aesthetics"
set "EAT_REPO=%AEST_DIR%\eat-repo"
set "VENV=%AEST_DIR%\venv"
set "WEIGHTS=%AEST_DIR%\weights"

echo ========================================
echo  ImageBrowser 美学模型一键安装
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 未找到 git，请先安装 Git for Windows
    exit /b 1
)

REM --- 选择可用的 Python（避开 WindowsApps 占位符）---
set "PYTHON_EXE="
where py >nul 2>&1
if not errorlevel 1 (
    py -3 -c "import sys" >nul 2>&1
    if not errorlevel 1 set "PYTHON_EXE=py -3"
)

if not defined PYTHON_EXE (
    for /f "delims=" %%P in ('dir /b /ad "%LocalAppData%\Programs\Python\Python3*" 2^>nul') do (
        if exist "%LocalAppData%\Programs\Python\%%P\python.exe" (
            set "PYTHON_EXE=%LocalAppData%\Programs\Python\%%P\python.exe"
            goto :python_found
        )
    )
)

:python_found
if not defined PYTHON_EXE (
    where python >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%P in ('where python 2^>nul') do (
            echo %%P | findstr /i "WindowsApps" >nul
            if errorlevel 1 (
                set "PYTHON_EXE=%%P"
                goto :python_validate
            )
        )
    )
)

:python_validate
if not defined PYTHON_EXE (
    echo [ERROR] 未找到可用的 Python 3.8+
    echo.
    echo 请从 https://www.python.org/downloads/ 安装 Python，
    echo 安装时勾选 "Add python.exe to PATH"。
    echo.
    echo 若已安装仍报错，可能是 Microsoft Store 占位符干扰，
    echo 请使用: py -3 -m venv aesthetics\venv 手动创建。
    exit /b 1
)

echo [INFO] 使用 Python: !PYTHON_EXE!
!PYTHON_EXE! --version
if errorlevel 1 (
    echo [ERROR] Python 无法运行
    exit /b 1
)

if not exist "%AEST_DIR%" mkdir "%AEST_DIR%"
if not exist "%WEIGHTS%" mkdir "%WEIGHTS%"

echo.
echo [STEP 1/3] 克隆 EAT 官方仓库...
if exist "%EAT_REPO%\.git" (
    echo [INFO] eat-repo 已存在，跳过克隆
) else (
    git clone --depth 1 https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment.git "%EAT_REPO%"
    if errorlevel 1 (
        echo [ERROR] git clone 失败，请检查网络
        exit /b 1
    )
)

if not exist "%EAT_REPO%\AVA\models" (
    echo [ERROR] 克隆不完整，缺少 AVA/models
    exit /b 1
)
echo [OK] EAT 代码: %EAT_REPO%\AVA

echo.
echo [STEP 2/3] 创建 Python 虚拟环境并安装依赖...
if exist "%VENV%\Scripts\python.exe" (
    echo [INFO] venv 已存在，跳过创建
) else (
    if exist "%VENV%" (
        echo [INFO] 清理不完整的 venv 目录...
        rmdir /s /q "%VENV%"
    )
    echo [INFO] 正在创建 venv...
    !PYTHON_EXE! -m venv "%VENV%"
    if errorlevel 1 (
        echo [ERROR] 创建 venv 失败
        echo.
        echo 可手动尝试:
        echo   py -3 -m venv "%VENV%"
        exit /b 1
    )
)

if not exist "%VENV%\Scripts\python.exe" (
    echo [ERROR] venv 创建后找不到 python.exe
    exit /b 1
)

"%VENV%\Scripts\python.exe" -m pip install --upgrade pip -q
if errorlevel 1 (
    echo [ERROR] pip 升级失败
    exit /b 1
)

"%VENV%\Scripts\pip.exe" install -r "%AEST_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERROR] pip install 失败
    echo 可尝试手动: "%VENV%\Scripts\pip.exe" install -r "%AEST_DIR%\requirements.txt"
    exit /b 1
)
echo [OK] Python 环境: %VENV%

echo.
echo [STEP 3/3] 检查模型权重...
set "HAS_WEIGHT=0"
if exist "%WEIGHTS%\finetune.pth" set "HAS_WEIGHT=1"
if exist "%WEIGHTS%\pretrain.pth" echo [OK] 预训练权重 pretrain.pth 已就绪

if "%HAS_WEIGHT%"=="0" (
    echo.
    echo [WARN] 尚未放置微调权重 finetune.pth
    echo.
    echo 请从 EAT 官方仓库下载权重后，放入：
    echo   %WEIGHTS%\
    echo.
    echo 文件命名:
    echo   finetune.pth  - 必填，AVA 微调 checkpoint
    echo   pretrain.pth  - 可选，dat_base_in1k_224.pth
    echo.
    echo 下载地址见：
    echo   https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment
    echo.
    start "" "%WEIGHTS%"
) else (
    echo [OK] 微调权重 finetune.pth 已就绪
)

if not exist "%AEST_DIR%\config.json" (
    copy /y "%AEST_DIR%\config.json.example" "%AEST_DIR%\config.json" >nul
)

echo.
echo ========================================
if "%HAS_WEIGHT%"=="1" (
    echo [OK] 安装完成，可直接运行 ImageBrowser
) else (
    echo [OK] 代码与环境已就绪，放入 finetune.pth 后即可使用
)
echo ========================================
exit /b 0

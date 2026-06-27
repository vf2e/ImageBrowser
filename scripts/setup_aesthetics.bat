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
echo [STEP 2/4] 创建 Python 虚拟环境并安装依赖...
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

set "USE_CUDA=0"
where nvidia-smi >nul 2>&1
if not errorlevel 1 set "USE_CUDA=1"

if "%USE_CUDA%"=="1" (
    echo [INFO] 检测到 NVIDIA GPU，安装 CUDA 版 PyTorch...
    "%VENV%\Scripts\pip.exe" install torch torchvision --index-url https://download.pytorch.org/whl/cu124
) else (
    echo [INFO] 未检测到 NVIDIA GPU，安装 CPU 版 PyTorch...
    "%VENV%\Scripts\pip.exe" install torch torchvision
)
if errorlevel 1 (
    echo [ERROR] PyTorch 安装失败
    exit /b 1
)

"%VENV%\Scripts\pip.exe" install -r "%AEST_DIR%\requirements.txt"
if errorlevel 1 (
    echo [ERROR] EAT 依赖安装失败
    exit /b 1
)

echo [INFO] 安装 Q-SiT 点评模型依赖...
"%VENV%\Scripts\pip.exe" install -r "%AEST_DIR%\requirements-qsit.txt"
if errorlevel 1 (
    echo [ERROR] Q-SiT 依赖安装失败
    exit /b 1
)
echo [OK] Python 环境: %VENV%

echo.
echo [STEP 3/4] 检查模型权重...
set "HAS_WEIGHT=0"
set "FINETUNE_FILE="

if exist "%WEIGHTS%\finetune.pth" (
    set "HAS_WEIGHT=1"
    set "FINETUNE_FILE=finetune.pth"
) else (
    for %%F in ("%WEIGHTS%\*.pth") do (
        set "NAME=%%~nxF"
        if /i not "!NAME!"=="pretrain.pth" (
            if "!HAS_WEIGHT!"=="0" (
                set "HAS_WEIGHT=1"
                set "FINETUNE_FILE=!NAME!"
            )
        )
    )
)

if exist "%WEIGHTS%\pretrain.pth" echo [OK] 预训练权重 pretrain.pth 已就绪

if "%HAS_WEIGHT%"=="1" (
    echo [OK] 微调权重已就绪: !FINETUNE_FILE!
) else (
    echo.
    echo [WARN] 尚未放置 AVA 微调权重
    echo.
    echo 请从 EAT 官方仓库下载 checkpoint 后，放入：
    echo   %WEIGHTS%\
    echo.
    echo 支持任意 .pth 文件名（除 pretrain.pth 外），例如：
    echo   finetune.pth
    echo   AVA_AOT_vacc_0.8259_srcc_0.7596_vlcc_0.7710.pth
    echo.
    echo pretrain.pth 为可选预训练权重
    echo.
    echo 下载地址见：
    echo   https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment
    echo.
    start "" "%WEIGHTS%"
)

echo.
echo [STEP 4/4] 写入配置...
if not exist "%AEST_DIR%\config.json" (
    copy /y "%AEST_DIR%\config.json.example" "%AEST_DIR%\config.json" >nul
)
if "%USE_CUDA%"=="1" (
    echo [OK] 已启用 CUDA 加速（EAT 评分 + Q-SiT 点评）
) else (
    echo [INFO] 当前为 CPU 模式，可在 config.json 中调整 device
)

echo.
echo ========================================
if "%HAS_WEIGHT%"=="1" (
    echo [OK] 安装完成，可直接运行 ImageBrowser
) else (
    echo [OK] 代码与环境已就绪，放入 AVA 微调 .pth 后即可使用
)
echo ========================================
exit /b 0

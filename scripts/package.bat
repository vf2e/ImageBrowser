@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM 一键打包：Release 构建 -> windeployqt 部署 -> 便携目录 / ZIP / Inno Setup 安装包
REM
REM 可选环境变量：
REM   QT_DIR           Qt 安装目录
REM   SKIP_BUILD=1     跳过编译，仅重新部署/打包
REM   SKIP_INSTALLER=1 不生成 Setup.exe（仍会生成 dist 与 ZIP）
REM   SKIP_ZIP=1       不生成便携 ZIP

set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build-release"
set "DIST_DIR=%PROJECT_ROOT%\dist\ImageBrowser"
set "OUTPUT_DIR=%PROJECT_ROOT%\output"
set "APP_VERSION=1.0.0"

if "%QT_DIR%"=="" (
    if exist "C:\qt5.15.2\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64"
    ) else if exist "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\Qt\5.15.2\msvc2019_64"
    ) else (
        echo [ERROR] 未找到 Qt，请设置 QT_DIR 环境变量。
        echo   示例: set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
        exit /b 1
    )
)

set "PATH=%QT_DIR%\bin;%PATH%"

echo.
echo ========================================
echo   ImageBrowser 一键打包
echo ========================================
echo [INFO] 项目: %PROJECT_ROOT%
echo [INFO] Qt:   %QT_DIR%
echo.

if not "%SKIP_BUILD%"=="1" (
    echo [STEP 1/5] Release 构建...
    call "%~dp0build_release.bat" "%BUILD_DIR%"
    if errorlevel 1 exit /b 1
) else (
    echo [STEP 1/5] 跳过构建 ^(SKIP_BUILD=1^)
)

set "EXE_PATH="
if exist "%BUILD_DIR%\ImageBrowser.exe" set "EXE_PATH=%BUILD_DIR%\ImageBrowser.exe"
if exist "%BUILD_DIR%\Release\ImageBrowser.exe" set "EXE_PATH=%BUILD_DIR%\Release\ImageBrowser.exe"

if "%EXE_PATH%"=="" (
    echo [ERROR] 未找到 ImageBrowser.exe: %BUILD_DIR%
    exit /b 1
)

echo [STEP 2/5] 准备 dist 目录...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"
copy /y "%EXE_PATH%" "%DIST_DIR%\" >nul

set "QML_DIR=%PROJECT_ROOT%\qml"
if not exist "%QML_DIR%" (
    echo [ERROR] QML 目录不存在: %QML_DIR%
    exit /b 1
)

echo [STEP 3/5] 部署 Qt 依赖 ^(windeployqt^)...
windeployqt --release --qmldir "%QML_DIR%" "%DIST_DIR%\ImageBrowser.exe"
if errorlevel 1 (
    echo [ERROR] windeployqt 失败
    exit /b 1
)

set "DEPLOY_OK=1"
for %%F in (D3Dcompiler_47.dll Qt5Core.dll Qt5Qml.dll Qt5Quick.dll platforms\qwindows.dll) do (
    if not exist "%DIST_DIR%\%%F" (
        echo [ERROR] 部署缺失: %%F
        set "DEPLOY_OK=0"
    )
)
if "!DEPLOY_OK!"=="0" (
    echo [ERROR] windeployqt 输出不完整，请检查 Qt PATH 与 QML 导入。
    exit /b 1
)
echo [OK] Qt 运行时已部署: %DIST_DIR%

echo [STEP 4/5] 复制美学评分模块...
if exist "%PROJECT_ROOT%\aesthetics\eat_server.py" (
    if not exist "%DIST_DIR%\aesthetics" mkdir "%DIST_DIR%\aesthetics"
    copy /y "%PROJECT_ROOT%\aesthetics\eat_server.py" "%DIST_DIR%\aesthetics\" >nul
    copy /y "%PROJECT_ROOT%\aesthetics\requirements.txt" "%DIST_DIR%\aesthetics\" >nul
    if exist "%PROJECT_ROOT%\aesthetics\config.json.example" (
        copy /y "%PROJECT_ROOT%\aesthetics\config.json.example" "%DIST_DIR%\aesthetics\" >nul
    )
    if not exist "%DIST_DIR%\aesthetics\weights" mkdir "%DIST_DIR%\aesthetics\weights"
    for %%W in ("%PROJECT_ROOT%\aesthetics\weights\*.pth") do (
        if exist "%%~fW" copy /y "%%~fW" "%DIST_DIR%\aesthetics\weights\" >nul
    )
    if exist "%PROJECT_ROOT%\aesthetics\venv" (
        echo [INFO] 复制 Python 虚拟环境 ^(体积较大^)...
        xcopy /E /I /Y /Q "%PROJECT_ROOT%\aesthetics\venv" "%DIST_DIR%\aesthetics\venv" >nul
    )
    if exist "%PROJECT_ROOT%\aesthetics\eat-repo" (
        echo [INFO] 复制 EAT 模型代码...
        xcopy /E /I /Y /Q "%PROJECT_ROOT%\aesthetics\eat-repo" "%DIST_DIR%\aesthetics\eat-repo" >nul
    )
    echo [OK] 美学模块已复制
) else (
    echo [WARN] 未找到 aesthetics\eat_server.py，跳过美学模块
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

if not "%SKIP_ZIP%"=="1" (
    set "ZIP_PATH=%OUTPUT_DIR%\ImageBrowser_v%APP_VERSION%_portable.zip"
    echo [INFO] 生成便携 ZIP...
    if exist "!ZIP_PATH!" del /f /q "!ZIP_PATH!"
    powershell -NoProfile -Command "Compress-Archive -Path '%DIST_DIR%\*' -DestinationPath '!ZIP_PATH!' -Force"
    if errorlevel 1 (
        echo [WARN] ZIP 生成失败
    ) else (
        echo [OK] 便携包: !ZIP_PATH!
    )
)

echo [STEP 5/5] 生成安装包 ^(Inno Setup^)...
if "%SKIP_INSTALLER%"=="1" (
    echo [INFO] 跳过安装包 ^(SKIP_INSTALLER=1^)
    goto :done
)

set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if "%ISCC%"=="" (
    echo [WARN] 未找到 Inno Setup 6，已跳过 Setup.exe。
    echo        可手动编译: installer\ImageBrowser.iss
    goto :done
)

"%ISCC%" "%PROJECT_ROOT%\installer\ImageBrowser.iss"
if errorlevel 1 (
    echo [ERROR] Inno Setup 编译失败
    exit /b 1
)

:done
echo.
echo ========================================
echo   打包完成
echo ========================================
echo   便携目录: %DIST_DIR%
if not "%SKIP_ZIP%"=="1" echo   便携 ZIP: %OUTPUT_DIR%\ImageBrowser_v%APP_VERSION%_portable.zip
if not "%SKIP_INSTALLER%"=="1" (
    if not "%ISCC%"=="" (
        for %%F in ("%OUTPUT_DIR%\ImageBrowser_v*_Setup.exe") do echo   安装包:   %%~fF
    )
)
echo ========================================
echo.
exit /b 0

@echo off
chcp 65001 >nul
setlocal

REM Package script: CMake build -> windeployqt -> Inno Setup

set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build-release"
set "DIST_DIR=%PROJECT_ROOT%\dist\ImageBrowser"
set "OUTPUT_DIR=%PROJECT_ROOT%\output"

if "%QT_DIR%"=="" (
    if exist "C:\qt5.15.2\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64"
    ) else if exist "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\Qt\5.15.2\msvc2019_64"
    ) else (
        echo [ERROR] Qt not found. Set QT_DIR env var.
        exit /b 1
    )
)

set "PATH=%QT_DIR%\bin;%PATH%"

echo [STEP 1/4] Release build...
call "%~dp0build_release.bat" "%BUILD_DIR%"
if errorlevel 1 exit /b 1

set "EXE_PATH="
if exist "%BUILD_DIR%\ImageBrowser.exe" set "EXE_PATH=%BUILD_DIR%\ImageBrowser.exe"
if exist "%BUILD_DIR%\Release\ImageBrowser.exe" set "EXE_PATH=%BUILD_DIR%\Release\ImageBrowser.exe"

if "%EXE_PATH%"=="" (
    echo [ERROR] Executable not found under %BUILD_DIR%
    exit /b 1
)

echo [STEP 2/4] Preparing dist directory...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"
copy /y "%EXE_PATH%" "%DIST_DIR%\" >nul

echo [STEP 3/4] Deploying Qt dependencies (windeployqt)...
windeployqt --release --qmldir "%PROJECT_ROOT%qml" "%DIST_DIR%\ImageBrowser.exe"
if errorlevel 1 (
    echo [ERROR] windeployqt failed
    exit /b 1
)

echo [STEP 4/4] Building installer (Inno Setup)...
set "ISCC="
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if "%ISCC%"=="" (
    echo [WARN] Inno Setup 6 not found. Dist is ready, compile manually:
    echo   installer\ImageBrowser.iss
    echo [OK] Dist directory: %DIST_DIR%
    exit /b 0
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
"%ISCC%" "%PROJECT_ROOT%installer\ImageBrowser.iss"
if errorlevel 1 (
    echo [ERROR] Inno Setup compile failed
    exit /b 1
)

echo [OK] Installer output: %OUTPUT_DIR%
dir /b "%OUTPUT_DIR%\ImageBrowser_v*_Setup.exe" 2>nul
exit /b 0

@echo off
chcp 65001 >nul
setlocal

REM Release build script
REM Optional env vars: QT_DIR, BUILD_DIR

set "PROJECT_ROOT=%~dp0..\"
set "BUILD_DIR=%PROJECT_ROOT%build-release"
if not "%~1"=="" set "BUILD_DIR=%~1"

if "%QT_DIR%"=="" (
    if exist "C:\qt5.15.2\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64"
    ) else if exist "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe" (
        set "QT_DIR=C:\Qt\5.15.2\msvc2019_64"
    ) else (
        echo [ERROR] Qt not found. Set QT_DIR env var, e.g.:
        echo   set QT_DIR=C:\qt5.15.2\5.15.2\msvc2019_64
        exit /b 1
    )
)

set "PATH=%QT_DIR%\bin;%PATH%"

where qmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] qmake not in PATH. Check QT_DIR: %QT_DIR%
    exit /b 1
)

set "VCVARS="
if exist "D:\software\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=D:\software\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VCVARS=%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
)

if not defined VCVARS (
    echo [ERROR] Visual Studio vcvars64.bat not found
    exit /b 1
)

echo [INFO] Project: %PROJECT_ROOT%
echo [INFO] Build dir: %BUILD_DIR%
echo [INFO] Qt dir: %QT_DIR%
echo [INFO] Loading VS environment...

call "%VCVARS%" >nul 2>&1

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

echo [INFO] Running qmake...
qmake "%PROJECT_ROOT%ImageBrowser.pro" -spec win32-msvc "CONFIG+=release"
if errorlevel 1 (
    echo [ERROR] qmake failed
    exit /b 1
)

echo [INFO] Building Release...
nmake release
if errorlevel 1 (
    echo [ERROR] Build failed
    exit /b 1
)

echo [OK] Build done: %BUILD_DIR%\release\ImageBrowser.exe
exit /b 0

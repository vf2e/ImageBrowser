@echo off
chcp 65001 >nul
setlocal

set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build-release"

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
set "QT_PLUGIN_PATH=%QT_DIR%\plugins"

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

call "%VCVARS%" >nul 2>&1

if /i "%~1"=="--html-only" goto :html_only

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"
echo [INFO] Configuring CMake with tests...
cmake "%PROJECT_ROOT%" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_DIR%" -DIMAGEBROWSER_BUILD_TESTS=ON
if errorlevel 1 (
    popd
    exit /b 1
)
popd

echo [INFO] Building tests...
cmake --build "%BUILD_DIR%" --target tst_imagebrowserbackend tst_qml tst_keyboard_integration --config Release
if errorlevel 1 (
    echo [ERROR] Test build failed
    exit /b 1
)

:html_only
set "REPORT_MODE="
set "OPEN_MODE="
if /i "%~1"=="--html-only" set "REPORT_MODE=-GenerateOnly"
if /i "%~2"=="--html-only" set "REPORT_MODE=-GenerateOnly"
if /i "%~1"=="--open" set "OPEN_MODE=-OpenReport"
if /i "%~2"=="--open" set "OPEN_MODE=-OpenReport"

echo [INFO] Generating HTML test report...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_test_report.ps1" -ProjectRoot "%PROJECT_ROOT%" -BuildDir "%BUILD_DIR%" %REPORT_MODE% %OPEN_MODE%
exit /b %ERRORLEVEL%

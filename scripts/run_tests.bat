@echo off
chcp 65001 >nul
setlocal

set "GENERATE_REPORT=0"
if /i "%~1"=="--report" set "GENERATE_REPORT=1"

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
set "QT_QPA_PLATFORM=offscreen"

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

set "TEST_DIR=%BUILD_DIR%\tests"
set "REPORT_DIR=%TEST_DIR%\reports"
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"
set "BACKEND_EXE=%TEST_DIR%\tst_imagebrowserbackend.exe"
set "QML_EXE=%TEST_DIR%\tst_qml.exe"
set "KEYBOARD_EXE=%TEST_DIR%\tst_keyboard_integration.exe"

if not exist "%BACKEND_EXE%" (
    echo [ERROR] Backend test executable not found
    exit /b 1
)
if not exist "%QML_EXE%" (
    echo [ERROR] QML test executable not found
    exit /b 1
)
if not exist "%KEYBOARD_EXE%" (
    echo [ERROR] Keyboard integration test executable not found
    exit /b 1
)

set "TEST_RESULT=0"

echo.
echo [INFO] Running C++ backend tests...
set "TEST_LOG=%TEST_DIR%\test-result-backend.txt"
pushd "%TEST_DIR%"
if "%GENERATE_REPORT%"=="1" (
    "%BACKEND_EXE%" -o "%TEST_LOG%,txt" -o "%REPORT_DIR%\backend.xml,junitxml"
) else (
    "%BACKEND_EXE%" -o "%TEST_LOG%,txt"
)
if errorlevel 1 set "TEST_RESULT=1"
type "%TEST_LOG%"
popd

echo.
echo [INFO] Running QML component tests...
set "TEST_LOG=%TEST_DIR%\test-result-qml.txt"
pushd "%TEST_DIR%"
if "%GENERATE_REPORT%"=="1" (
    "%QML_EXE%" -o "%TEST_LOG%,txt" -o "%REPORT_DIR%\qml.xml,junitxml"
) else (
    "%QML_EXE%" -o "%TEST_LOG%,txt"
)
if errorlevel 1 set "TEST_RESULT=1"
type "%TEST_LOG%"
popd

echo.
echo [INFO] Running keyboard integration tests...
set "TEST_LOG=%TEST_DIR%\test-result-keyboard.txt"
pushd "%TEST_DIR%"
set "QT_QPA_PLATFORM=windows"
if "%GENERATE_REPORT%"=="1" (
    "%KEYBOARD_EXE%" -o "%TEST_LOG%,txt" -o "%REPORT_DIR%\keyboard.xml,junitxml"
) else (
    "%KEYBOARD_EXE%" -o "%TEST_LOG%,txt"
)
if errorlevel 1 set "TEST_RESULT=1"
type "%TEST_LOG%"
popd
set "QT_QPA_PLATFORM=offscreen"

if %TEST_RESULT%==0 (
    echo.
    echo [OK] All tests passed
) else (
    echo.
    echo [ERROR] One or more test suites failed
)

if "%GENERATE_REPORT%"=="1" (
    echo.
    echo [INFO] Generating HTML test report...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_test_report.ps1" -ProjectRoot "%PROJECT_ROOT%" -BuildDir "%BUILD_DIR%" -GenerateOnly
)

exit /b %TEST_RESULT%

@echo off
chcp 65001 >nul
setlocal

set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build-coverage"
set "REPORT_DIR=%PROJECT_ROOT%\coverage-report"

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

set "OPENCPPCOVERAGE="
if exist "C:\Program Files\OpenCppCoverage\OpenCppCoverage.exe" (
    set "OPENCPPCOVERAGE=C:\Program Files\OpenCppCoverage\OpenCppCoverage.exe"
) else if exist "%ProgramFiles%\OpenCppCoverage\OpenCppCoverage.exe" (
    set "OPENCPPCOVERAGE=%ProgramFiles%\OpenCppCoverage\OpenCppCoverage.exe"
)

if "%OPENCPPCOVERAGE%"=="" (
    echo [ERROR] OpenCppCoverage not found.
    echo         Install from: https://github.com/OpenCppCoverage/OpenCppCoverage/releases
    echo         Or use GCC --coverage with lcov on Linux/macOS.
    exit /b 1
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"
cmake "%PROJECT_ROOT%" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_DIR%" -DIMAGEBROWSER_BUILD_TESTS=ON -DIMAGEBROWSER_ENABLE_COVERAGE=ON
if errorlevel 1 (
    popd
    exit /b 1
)
popd

cmake --build "%BUILD_DIR%" --target tst_imagebrowserbackend tst_keyboard_integration
if errorlevel 1 (
    echo [ERROR] Coverage build failed
    exit /b 1
)

set "BACKEND_TEST=%BUILD_DIR%\tests\tst_imagebrowserbackend.exe"
set "KEYBOARD_TEST=%BUILD_DIR%\tests\tst_keyboard_integration.exe"

if not exist "%BACKEND_TEST%" (
    echo [ERROR] tst_imagebrowserbackend.exe not found
    exit /b 1
)

if exist "%REPORT_DIR%" rmdir /s /q "%REPORT_DIR%"
mkdir "%REPORT_DIR%"

echo [INFO] Running backend tests with OpenCppCoverage...
"%OPENCPPCOVERAGE%" ^
    --sources "%PROJECT_ROOT%\src" ^
    --export_type html:"%REPORT_DIR%\backend" ^
    --export_type cobertura:"%REPORT_DIR%\backend.xml" ^
    -- "%BACKEND_TEST%"

if errorlevel 1 (
    echo [ERROR] Backend coverage run failed
    exit /b 1
)

if exist "%KEYBOARD_TEST%" (
    echo [INFO] Running keyboard integration tests with OpenCppCoverage...
    "%OPENCPPCOVERAGE%" ^
        --sources "%PROJECT_ROOT%\src" ^
        --export_type html:"%REPORT_DIR%\keyboard" ^
        -- "%KEYBOARD_TEST%"
)

echo.
echo [OK] Coverage report generated:
echo      %REPORT_DIR%\backend\index.html
if exist "%REPORT_DIR%\keyboard\index.html" (
    echo      %REPORT_DIR%\keyboard\index.html
)

exit /b 0

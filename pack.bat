@echo off
chcp 65001 >nul
REM 项目根目录一键打包入口
call "%~dp0scripts\package.bat" %*
exit /b %ERRORLEVEL%

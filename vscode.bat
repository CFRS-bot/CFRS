@echo off
cd /D %~dp0
call setenv.bat
start "" /D "%~dp0" "%INTERNAL%\VSCode\Code.exe" --disable-workspace-trust "project.code-workspace"

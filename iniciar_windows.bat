@echo off
REM Requer o LÖVE instalado e love.exe disponível no PATH.
where love >nul 2>nul
if errorlevel 1 (
  echo LÖVE nao encontrado no PATH.
  echo Instale em https://love2d.org/ e arraste esta pasta para love.exe.
  pause
  exit /b 1
)
cd /d "%~dp0"
start "" love .

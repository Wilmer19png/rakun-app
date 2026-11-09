@echo off
rem RAKUN Studio - abre el prototipo del diseno (doble clic)
cd /d "%~dp0"
where node >nul 2>nul || (echo No se encontro Node.js. Instalalo desde https://nodejs.org y vuelve a intentar. & pause & exit /b 1)
start "" "http://localhost:5173"
node servir.mjs
pause

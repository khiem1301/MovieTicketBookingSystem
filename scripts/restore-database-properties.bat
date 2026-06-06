@echo off
setlocal
cd /d "%~dp0.."

set "SRC=src\main\resources\database.properties"
set "BACKUP=src\main\resources\database.properties.backup"
set "EXAMPLE=src\main\resources\database.properties.example"

if exist "%BACKUP%" (
    copy /Y "%BACKUP%" "%SRC%" >nul
    echo [OK] Da khoi phuc tu %BACKUP%
    exit /b 0
)

if exist "%EXAMPLE%" (
    copy /Y "%EXAMPLE%" "%SRC%" >nul
    echo [OK] Da tao tu %EXAMPLE%
    echo      Hay sua db.server va db.password.
    exit /b 0
)

echo [LOI] Khong tim thay backup hoac file example.
exit /b 1

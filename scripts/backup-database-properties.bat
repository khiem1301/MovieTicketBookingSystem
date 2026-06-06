@echo off
setlocal
cd /d "%~dp0.."

set "SRC=src\main\resources\database.properties"
set "BACKUP=src\main\resources\database.properties.backup"

if not exist "%SRC%" (
    echo [LOI] Khong tim thay %SRC%
    exit /b 1
)

copy /Y "%SRC%" "%BACKUP%" >nul
echo [OK] Da luu backup: %BACKUP%
echo      Chay scripts\restore-database-properties.bat sau pull neu can.
exit /b 0

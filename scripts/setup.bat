@echo off
setlocal
cd /d "%~dp0.."

set "SRC=src\main\resources\database.properties"
set "EXAMPLE=src\main\resources\database.properties.example"

if exist "%SRC%" (
    echo [OK] %SRC% da ton tai - khong ghi de.
    exit /b 0
)

if not exist "%EXAMPLE%" (
    echo [LOI] Khong tim thay %EXAMPLE%
    exit /b 1
)

copy "%EXAMPLE%" "%SRC%" >nul
echo [OK] Da tao %SRC%
echo      Hay mo file va sua db.server, db.password cho dung may ban.
exit /b 0

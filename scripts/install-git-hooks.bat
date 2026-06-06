@echo off
setlocal
cd /d "%~dp0.."

git config core.hooksPath scripts/githooks

echo [OK] Da cau hinh Git hooks: scripts/githooks
echo      Hook post-merge se tu tao/khoi phuc database.properties sau pull.
echo.
echo Luu y: moi thanh vien chi can chay file nay MOT LAN sau khi clone.
exit /b 0

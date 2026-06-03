$ProjectRoot = Split-Path -Parent $PSScriptRoot
$src = Join-Path $ProjectRoot "src\main\resources\database.properties"
$example = Join-Path $ProjectRoot "src\main\resources\database.properties.example"

if (Test-Path $src) {
    Write-Host "[OK] $src da ton tai - khong ghi de."
    exit 0
}

if (-not (Test-Path $example)) {
    Write-Error "Khong tim thay $example"
    exit 1
}

Copy-Item $example $src
Write-Host "[OK] Da tao $src"
Write-Host "     Hay mo file va sua db.server, db.password cho dung may ban."

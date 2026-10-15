$ErrorActionPreference = "Stop"

function Stop-OnNativeCommandFailure {
    param(
        [string]$Step,
        [int]$ExitCode
    )

    if ($ExitCode -eq 0) {
        return
    }

    Write-Error "$Step 失败，退出码：$ExitCode" -ErrorAction Continue
    exit $ExitCode
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $projectRoot

$venvPython = Join-Path $projectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host "正在创建项目独立 Python 环境..."
    python -m venv .venv
    Stop-OnNativeCommandFailure -Step "创建项目独立 Python 环境" -ExitCode $LASTEXITCODE
}

Write-Host "正在确认站点依赖..."
& $venvPython -m pip install --disable-pip-version-check --quiet -r requirements.txt
Stop-OnNativeCommandFailure -Step "安装站点依赖" -ExitCode $LASTEXITCODE

Write-Host "站点将在 http://127.0.0.1:8000 打开，按 Ctrl+C 停止。"
& $venvPython -m mkdocs serve --dev-addr 127.0.0.1:8000
Stop-OnNativeCommandFailure -Step "启动 MkDocs 预览服务" -ExitCode $LASTEXITCODE

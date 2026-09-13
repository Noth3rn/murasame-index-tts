#Requires -Version 5.1
<#
.SYNOPSIS
    丛雨 TTS — WebUI 快捷启动（Windows / PowerShell）

.DESCRIPTION
    优先使用项目自带的 .venv 运行 webui.py，所有参数原样透传给 webui.py。

.EXAMPLE
    .\webui.ps1
#>
# 注意：同 infer.ps1，不声明 param 块，参数原样透传给 webui.py。

$venvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
$webuiPy    = Join-Path $PSScriptRoot 'webui.py'

try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
    # 输出被重定向时没有控制台句柄，忽略即可
}

Write-Host '正在启动丛雨 TTS WebUI...'
Write-Host '启动后请在浏览器打开 http://localhost:7860'
Write-Host '按 Ctrl+C 退出'
Write-Host ''

if (Test-Path -LiteralPath $venvPython) {
    & $venvPython $webuiPy @args
} else {
    # 排除 Microsoft Store 的 python.exe 占位符，它无法真正执行脚本
    $systemPython = Get-Command python -ErrorAction SilentlyContinue
    if ($systemPython -and $systemPython.Source -notlike '*\WindowsApps\*') {
        Write-Host '[警告] 未找到 .venv，尝试使用系统 Python'
        & $systemPython.Source $webuiPy @args
    } else {
        Write-Host '[错误] 未找到 .venv，也未找到可用的系统 Python。'
        Write-Host '请先运行 .\install.ps1 安装依赖。'
        exit 1
    }
}

exit $LASTEXITCODE

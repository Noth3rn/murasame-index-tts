#Requires -Version 5.1
<#
.SYNOPSIS
    丛雨 TTS — 命令行推理快捷脚本（Windows / PowerShell）

.DESCRIPTION
    优先使用项目自带的 .venv 运行 infer.py，所有参数原样透传给 infer.py。
    输出路径相对于当前工作目录，建议在项目根目录下运行。

.EXAMPLE
    .\infer.ps1 "ご主人、今日もよろしく。" -o out.wav

.EXAMPLE
    .\infer.ps1 "主人，今天天气真好。" --lang ZH -o zh.wav
#>
# 注意：本脚本刻意不声明 param 块。
# 一旦声明，PowerShell 会先做参数绑定，infer.py 自己的 -o / --lang 会被当成脚本参数，
# 报“找不到匹配的参数”或“参数名 'o' 不明确”；不声明 param 时参数全部落入 $args 原样透传。

# 控制台切到 UTF-8，否则输出的日文 / 中文可能乱码
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
    # 输出被重定向时没有控制台句柄，忽略即可
}

$venvPython = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
$inferPy    = Join-Path $PSScriptRoot 'infer.py'

if (Test-Path -LiteralPath $venvPython) {
    & $venvPython $inferPy @args
} else {
    # 排除 Microsoft Store 的 python.exe 占位符，它无法真正执行脚本
    $systemPython = Get-Command python -ErrorAction SilentlyContinue
    if ($systemPython -and $systemPython.Source -notlike '*\WindowsApps\*') {
        Write-Host '[警告] 未找到 .venv，尝试使用系统 Python（可能缺少依赖）'
        & $systemPython.Source $inferPy @args
    } else {
        Write-Host '[错误] 未找到 .venv，也未找到可用的系统 Python。'
        Write-Host '请先运行 .\install.ps1 安装依赖。'
        exit 1
    }
}

exit $LASTEXITCODE

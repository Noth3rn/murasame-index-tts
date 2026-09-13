#Requires -Version 5.1
<#
.SYNOPSIS
    丛雨 TTS — 安装脚本（Windows / PowerShell）

.DESCRIPTION
    在项目根目录创建 .venv 虚拟环境，安装 PyTorch 2.8 (CUDA 12.8)
    以及 requirements.txt 中的全部推理依赖，首次约需 10-20 分钟。

    若提示“无法加载文件……因为在此系统上禁止运行脚本”，请改用：
        powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    .\install.ps1

.EXAMPLE
    .\install.ps1 -NoPause
#>
[CmdletBinding()]
param(
    # 结束后不等待回车（在终端里手动运行时更顺手）
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

$Root       = $PSScriptRoot
$VenvDir    = Join-Path $Root '.venv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

# 控制台切到 UTF-8，否则输出的日文 / 中文可能乱码
try {
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
} catch {
    # 输出被重定向时没有控制台句柄，忽略即可
}

# 抓取外部命令的输出与退出码。
# 不能直接写 `& python --version 2>&1`：PS 5.1 会把 stderr 包装成错误记录，
# 在 $ErrorActionPreference = 'Stop' 下直接变成终止错误；碰到 Microsoft Store 的
# python.exe 占位符时更是会抛 ApplicationFailedException。
function Invoke-Capture {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $text = (& $FilePath @ArgumentList 2>&1 | ForEach-Object { "$_" }) -join "`n"
        return [pscustomobject]@{ Text = $text.Trim(); ExitCode = $LASTEXITCODE }
    } catch {
        return [pscustomobject]@{ Text = $_.Exception.Message; ExitCode = -1 }
    } finally {
        $ErrorActionPreference = $saved
    }
}

# 执行外部命令，失败即中断安装
function Invoke-Checked {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory)][string]$FailMessage
    )
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) { throw "$FailMessage（退出码 $LASTEXITCODE）" }
}

function Wait-Exit {
    if (-not $NoPause) { [void](Read-Host '按 Enter 键退出') }
}

Write-Host '============================================================'
Write-Host ' 丛雨 TTS — 安装脚本 (Windows / PowerShell)'
Write-Host '============================================================'
Write-Host ''

try {
    # ---- 检查 Python ----
    # 依次尝试 `python`、`py -3.11`、`py -3.10`、`py -3`，并把版本号抓出来；
    # Store 占位符只会输出一段提示而没有版本号，会被这里排除掉。
    $PythonExe     = $null
    $PythonPrefix  = @()
    $PythonVersion = $null

    foreach ($candidate in @(@('python'), @('py', '-3.11'), @('py', '-3.10'), @('py', '-3'))) {
        $exe    = $candidate[0]
        $prefix = @($candidate | Select-Object -Skip 1)
        if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { continue }

        $probe = Invoke-Capture -FilePath $exe -ArgumentList ($prefix + '--version')
        if ($probe.ExitCode -eq 0 -and $probe.Text -match 'Python (\d+)\.(\d+)') {
            $PythonExe     = $exe
            $PythonPrefix  = $prefix
            $PythonVersion = "$($Matches[1]).$($Matches[2])"
            break
        }
    }

    if (-not $PythonExe) {
        Write-Host '[错误] 未找到可用的 Python，请先安装 Python 3.10 或 3.11。'
        Write-Host '下载地址：https://www.python.org/downloads/'
        Write-Host '（若已安装却仍报错，可能是被 Microsoft Store 的占位符拦截，请在'
        Write-Host '  “设置 → 应用 → 高级应用设置 → 应用执行别名”中关闭 python.exe）'
        Wait-Exit
        exit 1
    }

    Write-Host "检测到 Python $PythonVersion"
    if ($PythonVersion -notin @('3.10', '3.11')) {
        Write-Host "[警告] 本项目要求 Python 3.10 / 3.11，当前为 $PythonVersion，依赖可能装不上。"
    }

    # ---- 创建虚拟环境 ----
    Write-Host ''
    Write-Host '[1/4] 创建虚拟环境 .venv ...'
    Invoke-Checked -FilePath $PythonExe -ArgumentList ($PythonPrefix + @('-m', 'venv', $VenvDir)) `
                   -FailMessage '创建虚拟环境失败'

    # ---- 升级 pip ----
    Write-Host ''
    Write-Host '[2/4] 升级 pip ...'
    Invoke-Checked -FilePath $VenvPython -ArgumentList @('-m', 'pip', 'install', '--upgrade', 'pip', 'setuptools', 'wheel') `
                   -FailMessage '升级 pip 失败'

    # ---- 安装 PyTorch (CUDA 12.8) ----
    Write-Host ''
    Write-Host '[3/4] 安装 PyTorch 2.8 (CUDA 12.8) ...'
    Write-Host '正在从 PyTorch 官方源下载，文件较大（约 2-3 GB），请耐心等待...'
    Invoke-Checked -FilePath $VenvPython `
                   -ArgumentList @('-m', 'pip', 'install', 'torch', 'torchaudio',
                                   '--index-url', 'https://download.pytorch.org/whl/cu128') `
                   -FailMessage 'PyTorch 安装失败，请检查网络连接'

    # ---- 安装其余依赖 ----
    Write-Host ''
    Write-Host '[4/4] 安装其余依赖 ...'
    Invoke-Checked -FilePath $VenvPython `
                   -ArgumentList @('-m', 'pip', 'install', '-r', (Join-Path $Root 'requirements.txt')) `
                   -FailMessage '依赖安装失败'

    Write-Host ''
    Write-Host '============================================================'
    Write-Host ' 安装完成！'
    Write-Host ''
    Write-Host ' 使用方式：'
    Write-Host '   .\infer.ps1 "ご主人、今日もよろしく。" -o out.wav'
    Write-Host '   .\webui.ps1'
    Write-Host '============================================================'
} catch {
    Write-Host ''
    Write-Host "[错误] $($_.Exception.Message)"
    Wait-Exit
    exit 1
}

Wait-Exit
exit 0

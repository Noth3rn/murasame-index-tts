#Requires -Version 5.1
<#
.SYNOPSIS
    丛雨 TTS — 安装脚本（Windows / PowerShell）

.DESCRIPTION
    在项目根目录创建 .venv 虚拟环境，安装 PyTorch (CUDA 12.8)
    以及 requirements.txt 中的全部推理依赖，首次约需 10-20 分钟。

    若提示“无法加载文件……因为在此系统上禁止运行脚本”，请改用：
        powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
    .\install.ps1

.EXAMPLE
    # 用指定解释器安装（路径或命令名）
    .\install.ps1 -Python "C:\Python311\python.exe"

.EXAMPLE
    # .venv 由别的 Python 版本创建时，删掉重建
    .\install.ps1 -RecreateVenv
#>
[CmdletBinding()]
param(
    # 结束后不等待回车（在终端里手动运行时更顺手）
    [switch]$NoPause,

    # 显式指定 Python 解释器（路径或命令名），跳过自动探测
    [string]$Python,

    # .venv 由其他版本的 Python 创建时，删除并重建
    [switch]$RecreateVenv,

    # 允许用 3.10 / 3.11 以外的 Python 继续安装
    [switch]$AllowUnsupportedPython
)

$ErrorActionPreference = 'Stop'

$Root       = $PSScriptRoot
$VenvDir    = Join-Path $Root '.venv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

# 本项目的依赖在 3.12+ 上没有完整的预编译 wheel，会退回源码编译并失败
$SupportedPython = @('3.10', '3.11')

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

# uv 托管的 Python 不在 py launcher 的版本标签里（`py -3.11` 找不到它们），
# 只能按目录名去找。
function Get-UvPython {
    $roots = @()
    if ($env:APPDATA)      { $roots += (Join-Path $env:APPDATA 'uv\python') }
    if ($env:LOCALAPPDATA) { $roots += (Join-Path $env:LOCALAPPDATA 'uv\python') }
    # 先 3.11 再 3.10
    foreach ($pattern in @('cpython-3.11*', 'cpython-3.10*')) {
        foreach ($root in $roots) {
            if (-not (Test-Path -LiteralPath $root)) { continue }
            foreach ($dir in Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue) {
                if ($dir.Name -notlike $pattern) { continue }
                $exe = Join-Path $dir.FullName 'python.exe'
                if (Test-Path -LiteralPath $exe) { $exe }
            }
        }
    }
}

function Wait-Exit {
    if (-not $NoPause) { [void](Read-Host '按 Enter 键退出') }
}

Write-Host '============================================================'
Write-Host ' 丛雨 TTS — 安装脚本 (Windows / PowerShell)'
Write-Host '============================================================'
Write-Host ''

try {
    # ---- 找到可用的 Python ----
    $candidates = @()
    if ($Python) {
        $candidates += [pscustomobject]@{ Label = "指定的 -Python"; Exe = $Python; Args = @() }
    } else {
        $candidates += [pscustomobject]@{ Label = 'python';  Exe = 'python'; Args = @() }
        $candidates += [pscustomobject]@{ Label = 'py -3.11'; Exe = 'py'; Args = @('-3.11') }
        $candidates += [pscustomobject]@{ Label = 'py -3.10'; Exe = 'py'; Args = @('-3.10') }
        foreach ($uvPython in Get-UvPython) {
            $candidates += [pscustomobject]@{ Label = "uv 的 $uvPython"; Exe = $uvPython; Args = @() }
        }
        $candidates += [pscustomobject]@{ Label = 'py -3'; Exe = 'py'; Args = @('-3') }
    }

    $PythonExe     = $null
    $PythonPrefix  = @()
    $PythonVersion = $null
    $ProbedVersion = $null   # 探测到的第一个解释器的版本，用于报错时提示

    # 把版本号抓出来；Store 占位符只会输出一段提示而没有版本号，会被这里排除掉
    foreach ($candidate in $candidates) {
        if (-not (Get-Command $candidate.Exe -ErrorAction SilentlyContinue)) { continue }

        $probe = Invoke-Capture -FilePath $candidate.Exe -ArgumentList ($candidate.Args + '--version')
        if ($probe.ExitCode -ne 0 -or $probe.Text -notmatch 'Python (\d+)\.(\d+)') { continue }

        $version = "$($Matches[1]).$($Matches[2])"
        if (-not $ProbedVersion) { $ProbedVersion = $version }

        # 版本合适就用它；不合适则继续找，实在没有才报错
        $PythonExe     = $candidate.Exe
        $PythonPrefix  = $candidate.Args
        $PythonVersion = $version
        if ($version -in $SupportedPython) { break }
    }

    if (-not $PythonExe) {
        Write-Host '[错误] 未找到可用的 Python，请先安装 Python 3.10 或 3.11。'
        Write-Host '下载地址：https://www.python.org/downloads/'
        Write-Host '（若已安装却仍报错，可能是被 Microsoft Store 的占位符拦截，请在'
        Write-Host '  “设置 → 应用 → 高级应用设置 → 应用执行别名”中关闭 python.exe）'
        Wait-Exit
        exit 1
    }

    if ($PythonVersion -notin $SupportedPython) {
        if (-not $AllowUnsupportedPython) {
            Write-Host "[错误] 需要 Python $($SupportedPython -join ' 或 ')，但只找到 $PythonVersion。"
            Write-Host '       本项目的部分依赖（pydantic-core、kaldifst）在更新的 Python 上没有'
            Write-Host '       预编译 wheel，会退回源码编译并失败。装好 3.10 / 3.11 后重跑即可：'
            Write-Host '         winget install Python.Python.3.11'
            Write-Host '         uv python install 3.11'
            Write-Host ''
            Write-Host "       确实要用 $PythonVersion 硬装（不推荐）：.\install.ps1 -AllowUnsupportedPython"
            if ($Python) { Write-Host "       也可以换一个解释器：.\install.ps1 -Python <python.exe 路径>" }
            Wait-Exit
            exit 1
        }
        Write-Host "[警告] 允许使用不受支持的 Python $PythonVersion 继续安装。"
    }

    Write-Host "使用 $($PythonExe) (Python $PythonVersion)"

    # ---- 检查已有的 .venv ----
    # 用 A 版本的 Python 建出来的 .venv 再用 B 版本去装包，会得到一个混合的坏环境，
    # 所以版本对不上时必须先删掉。删目录是有破坏性的，只在显式给了 -RecreateVenv 时做。
    $VenvConfig = Join-Path $VenvDir 'pyvenv.cfg'
    $VenvReady  = $false   # 复用已有 .venv，还是需要重新创建
    if (Test-Path -LiteralPath $VenvConfig) {
        $VenvVersion = $null
        if ((Get-Content -LiteralPath $VenvConfig -Raw) -match '(?m)^\s*version\s*=\s*(\d+\.\d+)') {
            $VenvVersion = $Matches[1]
        }
        if ($VenvVersion -and $VenvVersion -ne $PythonVersion) {
            if (-not $RecreateVenv) {
                Write-Host ''
                Write-Host "[错误] .venv 是用 Python $VenvVersion 创建的，而这次选中的是 $PythonVersion。"
                Write-Host '       两个版本混装会得到一个坏掉的环境，必须先删掉重建：'
                Write-Host ''
                Write-Host '         .\install.ps1 -RecreateVenv'
                Write-Host ''
                Write-Host "      （该开关会删除 $VenvDir 后重新创建）"
                Wait-Exit
                exit 1
            }
            Write-Host "[1/5] 删除由 Python $VenvVersion 创建的旧 .venv ..."
            Remove-Item -LiteralPath $VenvDir -Recurse -Force
        } else {
            $VenvReady = $true
        }
    }

    # ---- 创建虚拟环境 ----
    if ($VenvReady) {
        # 重复运行安装时不要再去覆盖 Scripts\python.exe：那个文件可能仍被上一次
        # 崩溃的推理进程或杀毒软件短暂占用，会报 [Errno 13] Permission denied。
        Write-Host ''
        Write-Host '[2/5] 虚拟环境 .venv 已存在且版本一致，跳过创建'
    } else {
        Write-Host ''
        Write-Host '[2/5] 创建虚拟环境 .venv ...'
        Invoke-Checked -FilePath $PythonExe -ArgumentList ($PythonPrefix + @('-m', 'venv', $VenvDir)) `
                       -FailMessage '创建虚拟环境失败'
    }

    # ---- 升级 pip ----
    Write-Host ''
    Write-Host '[3/5] 升级 pip ...'
    Invoke-Checked -FilePath $VenvPython -ArgumentList @('-m', 'pip', 'install', '--upgrade', 'pip', 'setuptools', 'wheel') `
                   -FailMessage '升级 pip 失败'

    # ---- 安装 PyTorch (CUDA 12.8) ----
    Write-Host ''
    # 必须钉在 2.8：torchaudio 从 2.9 起 save() 强制走 TorchCodec，
    # 而 TorchCodec 在 Windows 上需要 FFmpeg 的共享库 DLL（普通 full_build 只有 exe），
    # 装不上就会在最后保存 wav 时抛 RuntimeError，前面几十秒的推理全白跑。
    Write-Host '[4/5] 安装 PyTorch 2.8 (CUDA 12.8) ...'
    Write-Host '正在从 PyTorch 官方源下载，文件较大（约 2-3 GB），请耐心等待...'
    Invoke-Checked -FilePath $VenvPython `
                   -ArgumentList @('-m', 'pip', 'install', 'torch==2.8.0', 'torchaudio==2.8.0',
                                   '--index-url', 'https://download.pytorch.org/whl/cu128') `
                   -FailMessage 'PyTorch 安装失败，请检查网络连接'

    # ---- 安装其余依赖 ----
    Write-Host ''
    Write-Host '[5/5] 安装其余依赖 ...'
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
    Write-Host '      安装日志往上翻，pip 的报错通常在几十行之前。'
    Wait-Exit
    exit 1
}

Wait-Exit
exit 0

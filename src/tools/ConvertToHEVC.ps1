param(
    [string]$Source = $args[0],
    [string]$Output = $args[1],
    [int]$MaxJobs = 4,
    [string]$Preset = "slow",
    [int]$Crf = 23,
    [switch]$ReplaceWs,
    [switch]$DryRun,
    [switch]$Help
)

function Format-Stem {
    param (
        [string]$stem
    )
    $pattern = '[\s，,（）！!.。？?@$、【】▌❤️_★#%&*：:‘’“”;；<>《》''""/「」『』]+'
    $result = [regex]::Replace($stem, $pattern, '_')

    # 去除前缀下划线（如果有）
    if ($result.StartsWith('_')) {
        $result = $result.Substring(1)
    }

    return $result
}

function Show-Help {
    Write-Host "用法: .\ConvertToHEVC-LimitedConcurrent.ps1 -Source <源目录> -Output <目标目录> [-MaxJobs <并发数>] [-Preset <预设>] [-Crf <0-51>] [-ReplaceWs] [-DryRun] [-Help]" -ForegroundColor Cyan
    Write-Host "参数："
    Write-Host "  -Source       源视频目录（必需）"
    Write-Host "  -Output       转码后目录（必需）"
    Write-Host "  -MaxJobs      最大并发任务数，默认4（可选）"
    Write-Host "  -Preset       x265编码预设，取值范围 [ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow]，默认 slow（可选）"
    Write-Host "  -Crf          恒定质量参数，取值范围 0-51，数值越小质量越高，默认23（可选）"
    Write-Host "  -ReplaceWs    将文件名中的空白字符替换为下划线（可选）"
    Write-Host "  -DryRun       显示将执行的ffmpeg命令，但不实际转码（可选）"
    Write-Host "  -Help         显示此帮助并退出"
}

if ($Help -or -not $Source -or -not $Output) {
    Show-Help
    exit 0
}

if (-not (Test-Path $Source)) {
    Write-Host "❌ 源目录不存在：$Source" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output -Force | Out-Null
}

$logFile = Join-Path $Output "transcode_log.txt"
"=== 转码开始：$(Get-Date) ===`n" | Out-File $logFile -Encoding utf8

$videoExts = @("*.mp4","*.mkv","*.avi","*.mov","*.flv","*.wmv")
$jobs = @()
$srcFull = [IO.Path]::GetFullPath($Source)

# 收集视频文件
$files = foreach ($ext in $videoExts) { Get-ChildItem -Path $srcFull -Recurse -Filter $ext }

foreach ($f in $files) {
    $inPath = $f.FullName
    $relDir = [IO.Path]::GetRelativePath($srcFull, $f.DirectoryName)
    $outDir = Join-Path $Output $relDir
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $name = $f.BaseName
    if ($ReplaceWs)  { $name = Format-Stem $name }
    $outPath = Join-Path $outDir ("${name}_hevc.mp4")

    # 构造ffmpeg命令
    $cmd = "ffmpeg -i `"$inPath`" -c:v libx265 -preset $Preset -crf $Crf -c:a copy `"$outPath`" -y"

    if ($DryRun) {
        Write-Host "DRYRUN: $cmd"
        "$inPath => DRYRUN: $cmd" | Out-File $logFile -Append
        continue
    }

    # 跳过已存在
    if (Test-Path $outPath) {
        "$inPath => 已存在，跳过" | Out-File $logFile -Append
        continue
    }

    # 并发控制
    while ((Get-Job -State Running).Count -ge $MaxJobs) { Start-Sleep 1 }

    $job = Start-Job -ScriptBlock {
        param($inP,$outP,$lg,$c,$preset,$crf)
        try {
            $origSize = (Get-Item $inP).Length
            $st = Get-Date
            & ffmpeg -i "$inP" -c:v libx265 -preset $preset -crf $crf -c:a copy "$outP" -y 2>&1 | Out-Null
            $dur = (Get-Date) - $st
            $newSize = (Get-Item $outP).Length
            $ratio = (($origSize - $newSize)/$origSize*100)
            "{0} => 转码成功（耗时：{1:N1} 分钟，压缩比：{2:N1}%）" -f $inP,$dur.TotalMinutes,$ratio | Out-File $lg -Append
        } catch {
            "{0} => 转码失败：{1}" -f $inP,$_.Exception.Message | Out-File $lg -Append
        }
    } -ArgumentList $inPath,$outPath,$logFile,$null,$Preset,$Crf
    $jobs += $job
}

Write-Host "▶ 等待所有任务完成..." -ForegroundColor Yellow
$jobs | ForEach-Object { Wait-Job $_; Receive-Job $_ > $null; Remove-Job $_ }

"=== 转码完成：$(Get-Date) ===`n" | Out-File $logFile -Append
Write-Host "✅ 全部完成，日志：$logFile" -ForegroundColor Green
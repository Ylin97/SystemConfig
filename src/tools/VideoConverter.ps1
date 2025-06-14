param(
    [string]$Source = $args[0],
    [string]$Output = $args[1],
    [int]$MaxJobs = 4,
    [string]$Preset = $null,
    [int]$Crf = 23,
    [string]$Codec = "hevc",  # [hevc|av1]，默认hevc
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
    if ($result.StartsWith('_')) { $result = $result.Substring(1) }
    return $result
}

function Show-Help {
    Write-Host "用法: .\VideoConverter.ps1 -Source <源目录> -Output <目标目录> [-MaxJobs <并发数>] [-Preset <预设>] [-Crf <0-51>] [-Codec <编码器>] [-ReplaceWs] [-DryRun] [-Help]" -ForegroundColor Cyan
    Write-Host "参数："
    Write-Host "  -Source       源视频目录（必需）"
    Write-Host "  -Output       转码后目录（必需）"
    Write-Host "  -MaxJobs      最大并发任务数，默认4（可选）"
    Write-Host "  -Preset       编码预设（可选）"
    Write-Host "                * HEVC: [ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow]（默认slow）"
    Write-Host "                * AV1:  整数0-13 (0=最快/压缩率最低, 13=最慢/压缩率最高，默认8)，如非法自动转8"
    Write-Host "  -Crf          恒定质量参数"
    Write-Host "                * HEVC: 0-51（默认23，值越小质量越高）"
    Write-Host "                * AV1:  0-63（建议25-35，默认30）"
    Write-Host "  -Codec        视频编码器 [hevc|av1]（默认hevc）（可选）"
    Write-Host "  -ReplaceWs    将文件名中的空白字符替换为下划线（可选）"
    Write-Host "  -DryRun       仅显示ffmpeg命令，不实际转码（可选）"
    Write-Host "  -Help         显示此帮助并退出"
    Write-Host "`n示例："
    Write-Host "  .\VideoConverter.ps1 -Source .\input -Output .\output"
    Write-Host "  .\VideoConverter.ps1 -Source .\input -Output .\output -Codec av1 -Preset 8 -Crf 32"
}

if ($Help -or -not $Source -or -not $Output) {
    Show-Help
    exit 0
}

# 验证编码器参数
if ($Codec -notin @("hevc", "av1")) {
    Write-Host "❌ 无效的编码器: $Codec，仅支持 hevc 或 av1" -ForegroundColor Red
    exit 1
}

# 自动智能Preset/Crf判断
if ($Codec -eq "av1") {
    if (-not $Preset -or $Preset -eq "slow") { $Preset = 8 }
    if ($Preset -notmatch '^\d+$' -or [int]$Preset -lt 0 -or [int]$Preset -gt 13) {
        Write-Host "⚠️ AV1 (svt-av1) 预设应为0-13的整数，当前'$Preset'非法，已自动设为8。" -ForegroundColor Yellow
        $Preset = 8
    }
    if ($Crf -eq 23) { $Crf = 30 }
} else {
    if (-not $Preset) { $Preset = "slow" }
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
"编码器: $Codec | 预设: $Preset | CRF: $Crf`n" | Out-File $logFile -Append

$videoExts = @("*.mp4","*.mkv","*.avi","*.mov","*.flv","*.wmv","*.ts","*.webm","*.mpg","*.mpeg","*.m2ts","*.vob","*.3gp")
$jobs = @()
$srcFull = [IO.Path]::GetFullPath($Source)

# 收集视频文件（防止重复，去重）
$files = @()
foreach ($ext in $videoExts) { $files += Get-ChildItem -Path $srcFull -Recurse -Filter $ext }
$files = $files | Sort-Object FullName -Unique

foreach ($f in $files) {
    $inPath = $f.FullName
    $relDir = [IO.Path]::GetRelativePath($srcFull, $f.DirectoryName)
    $outDir = Join-Path $Output $relDir
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $name = $f.BaseName
    if ($ReplaceWs)  { $name = Format-Stem $name }
    
    # 输出后缀区分编码器
    $outExt = if ($Codec -eq "av1") { "_av1.mkv" } else { "_hevc.mkv" }
    $outPath = Join-Path $outDir ("${name}${outExt}")

    # 构造ffmpeg命令（音频编码：hevc copy，av1转aac）
    $cmd = switch ($Codec) {
        "hevc" { 
            "ffmpeg -hide_banner -y -i `"$inPath`" -c:v libx265 -preset $Preset -crf $Crf -c:a copy `"$outPath`""
        }
        "av1" {
            "ffmpeg -hide_banner -y -i `"$inPath`" -c:v libsvtav1 -preset $Preset -crf $Crf -c:a aac -b:a 128k `"$outPath`""
        }
    }

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
        param($inP, $outP, $lg, $codec, $preset, $crf)
        try {
            $origSize = (Get-Item $inP).Length
            $st = Get-Date
            if ($codec -eq "hevc") {
                & ffmpeg -hide_banner -y -i "$inP" -c:v libx265 -preset $preset -crf $crf -c:a copy "$outP" 2>&1 | Out-Null
            }
            else {
                & ffmpeg -hide_banner -y -i "$inP" -c:v libsvtav1 -preset $preset -crf $crf -c:a aac -b:a 128k "$outP" 2>&1 | Out-Null
            }
            $dur = (Get-Date) - $st
            $newSize = if (Test-Path $outP) { (Get-Item $outP).Length } else { 0 }
            if ($newSize -gt 0) {
                $ratio = ($origSize - $newSize) / $origSize * 100
                "{0} => {1}转码成功（耗时：{2:N1} 分钟，压缩比：{3:N1}%）" -f $inP, $codec.ToUpper(), $dur.TotalMinutes, $ratio | Out-File $lg -Append
            } else {
                "{0} => {1}转码失败：输出文件未生成" -f $inP, $codec.ToUpper() | Out-File $lg -Append
            }
        } catch {
            "{0} => {1}转码失败：{2}" -f $inP, $codec.ToUpper(), $_.Exception.Message | Out-File $lg -Append
        }
    } -ArgumentList $inPath, $outPath, $logFile, $Codec, $Preset, $Crf
    $jobs += $job
}

Write-Host "▶ 等待所有任务完成（编码器：$Codec）..." -ForegroundColor Yellow
$jobs | ForEach-Object { Wait-Job $_; Receive-Job $_ > $null; Remove-Job $_ }

"=== 转码完成：$(Get-Date) ===`n" | Out-File $logFile -Append
Write-Host "✅ $($jobs.Count)个文件$($Codec.ToUpper())转码完成，日志：$logFile" -ForegroundColor Green

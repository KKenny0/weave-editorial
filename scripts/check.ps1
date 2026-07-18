#requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SourceArticle,
    [string]$OutputArticle,
    [ValidateSet('faithful', 'publication')]
    [string]$Mode = 'faithful',
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Warnings = [System.Collections.Generic.List[string]]::new()

function Pass([string]$Message) { Write-Host "[PASS] $Message" -ForegroundColor Green }
function Fail([string]$Message) { $script:Failures.Add($Message); Write-Host "[FAIL] $Message" -ForegroundColor Red }
function Warn([string]$Message) { $script:Warnings.Add($Message); Write-Host "[WARN] $Message" -ForegroundColor Yellow }

function Get-Frontmatter([string]$Text) {
    if ($Text -match '(?s)\A---\s*\r?\n(.*?)\r?\n---\s*(?:\r?\n|\z)') { return $Matches[1] }
    return $null
}

function Get-Body([string]$Text) {
    return [regex]::Replace($Text, '(?s)\A---\s*\r?\n.*?\r?\n---\s*(?:\r?\n|\z)', '')
}

function Get-FrontmatterValue([string]$Frontmatter, [string]$Key) {
    $pattern = '(?m)^{0}:\s*["'']?(.*?)["'']?\s*$' -f [regex]::Escape($Key)
    if ($null -ne $Frontmatter -and $Frontmatter -match $pattern) {
        return $Matches[1].Trim()
    }
    return $null
}

function Get-Set([string[]]$Values) {
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($value in $Values) { if ($value) { [void]$set.Add($value.Trim()) } }
    return ,$set
}

function Compare-ExactSet($Expected, $Actual, [string]$Label) {
    $missing = @($Expected | Where-Object { -not $Actual.Contains($_) })
    $added = @($Actual | Where-Object { -not $Expected.Contains($_) })
    if ($missing.Count -eq 0 -and $added.Count -eq 0) {
        Pass "$Label 集合一致（$($Expected.Count) 项）"
    } else {
        Fail "$Label 集合不一致：缺失 $($missing.Count) 项，新增 $($added.Count) 项"
        foreach ($item in $missing) { Write-Host "       missing: $item" }
        foreach ($item in $added) { Write-Host "       added:   $item" }
    }
}

function Compare-Subset($Allowed, $Actual, [string]$Label) {
    $added = @($Actual | Where-Object { -not $Allowed.Contains($_) })
    if ($added.Count -eq 0) {
        Pass "$Label 均来自源稿（输出 $($Actual.Count) / 源稿 $($Allowed.Count) 项）"
    } else {
        Fail "$Label 包含源稿中不存在的内容：新增 $($added.Count) 项"
        foreach ($item in $added) { Write-Host "       added:   $item" }
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$required = @(
    'SKILL.md',
    'README.md',
    'references/editorial-protocol.md',
    'scripts/check.ps1',
    'evals/evals.json',
    'evals/smoke.md',
    'evals/files/survey.md',
    'evals/files/deep-read.md',
    'evals/files/source-dive.md'
)

foreach ($relative in $required) {
    $path = Join-Path $repoRoot $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) { Pass "存在 $relative" } else { Fail "缺少 $relative" }
}

$skillPath = Join-Path $repoRoot 'SKILL.md'
if (Test-Path -LiteralPath $skillPath) {
    $skillText = Get-Content -Raw -LiteralPath $skillPath
    $frontmatter = Get-Frontmatter $skillText
    if ((Get-FrontmatterValue $frontmatter 'name') -eq 'weave-editorial') { Pass 'SKILL.md name 正确' } else { Fail 'SKILL.md name 必须为 weave-editorial' }
    if (Get-FrontmatterValue $frontmatter 'description') { Pass 'SKILL.md description 存在' } else { Fail 'SKILL.md 缺少 description' }
    if (($skillText -split "`n").Count -lt 500) { Pass 'SKILL.md 少于 500 行' } else { Fail 'SKILL.md 应少于 500 行' }
    foreach ($requiredContract in @('faithful', 'publication', 'Publication Gate', 'Accurate retellability', 'Natural transmission reason', 'Durable retrieval anchor')) {
        if ($skillText -notmatch [regex]::Escape($requiredContract)) { Fail "SKILL.md 缺少双模式或发布门契约：$requiredContract" }
    }
}

$protocolPath = Join-Path $repoRoot 'references/editorial-protocol.md'
if (Test-Path -LiteralPath $protocolPath) {
    $protocolText = Get-Content -Raw -LiteralPath $protocolPath
    foreach ($requiredProtocol in @('## 1. 选择模式', '## 2. 模式化内容账本', '## 9. Publication Gate', '### Reader entry', '### Opening fulfillment', '### Narrative progression', '### Accurate retellability', '### Natural transmission reason', '### Durable retrieval anchor', '### Integrity')) {
        if ($protocolText -notmatch [regex]::Escape($requiredProtocol)) { Fail "编辑协议缺少必要章节：$requiredProtocol" }
    }
}

$evalPath = Join-Path $repoRoot 'evals/evals.json'
if (Test-Path -LiteralPath $evalPath) {
    try {
        $evals = Get-Content -Raw -LiteralPath $evalPath | ConvertFrom-Json
        if ($evals.skill_name -eq 'weave-editorial' -and @($evals.evals).Count -eq 6) { Pass 'evals.json 包含 6 个评测' } else { Fail 'evals.json 的 skill_name 或评测数量不正确' }
        foreach ($eval in @($evals.evals)) {
            if (-not $eval.prompt -or -not $eval.expected_output -or @($eval.files).Count -ne 1 -or $eval.mode -notin @('faithful', 'publication')) { Fail "评测 $($eval.id) 字段不完整或 mode 无效" }
        }
        if (@($evals.evals | Where-Object { $_.mode -eq 'faithful' }).Count -ne 3 -or @($evals.evals | Where-Object { $_.mode -eq 'publication' }).Count -ne 3) {
            Fail 'evals.json 必须各包含 3 个 faithful 与 publication 评测'
        }
    } catch { Fail "evals.json 无法解析：$($_.Exception.Message)" }
}

if (-not $SkipInstall) {
    try {
        $discovery = (& npx -y skills@1.5.17 add $repoRoot --list 2>&1 | Out-String)
        if ($LASTEXITCODE -eq 0 -and $discovery -match 'weave-editorial') { Pass 'skills CLI 能发现 weave-editorial' } else { Fail "skills CLI 未发现 weave-editorial`n$discovery" }
    } catch { Fail "skills CLI 发现性检查失败：$($_.Exception.Message)" }
}

if ([string]::IsNullOrWhiteSpace($SourceArticle) -xor [string]::IsNullOrWhiteSpace($OutputArticle)) {
    Fail 'SourceArticle 与 OutputArticle 必须同时提供'
}

if ($SourceArticle -and $OutputArticle) {
    $sourcePath = [System.IO.Path]::GetFullPath($SourceArticle)
    $outputPath = [System.IO.Path]::GetFullPath($OutputArticle)

    if ($sourcePath -eq $outputPath) { Fail '输出不得覆盖源文件' } else { Pass '源稿与成稿路径不同' }
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { Fail "源稿不存在：$sourcePath" }
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) { Fail "成稿不存在：$outputPath" }

    if ((Test-Path -LiteralPath $sourcePath) -and (Test-Path -LiteralPath $outputPath)) {
        if ([System.IO.Path]::GetExtension($outputPath) -eq '.md') { Pass '成稿是 Markdown 文件' } else { Fail '成稿必须是 .md 文件' }

        $sourceText = Get-Content -Raw -LiteralPath $sourcePath
        $outputText = Get-Content -Raw -LiteralPath $outputPath
        $sourceBody = Get-Body $sourceText
        $outputBody = Get-Body $outputText
        $outputFrontmatter = Get-Frontmatter $outputText
        $title = Get-FrontmatterValue $outputFrontmatter 'title'
        $status = Get-FrontmatterValue $outputFrontmatter 'status'
        $h1 = @([regex]::Matches($outputBody, '(?m)^#\s+(.+?)\s*$'))

        if ($title) { Pass '成稿 frontmatter 包含 title' } else { Fail '成稿 frontmatter 缺少 title' }
        if ($status -eq 'draft') { Pass '成稿 status 为 draft' } else { Fail '成稿 frontmatter 的 status 必须为 draft' }
        if ($h1.Count -eq 1) { Pass '成稿只有一个 H1' } else { Fail "成稿应只有一个 H1，实际 $($h1.Count) 个" }
        if ($h1.Count -eq 1 -and $title -eq $h1[0].Groups[1].Value.Trim()) { Pass 'frontmatter title 与 H1 一致' } else { Fail 'frontmatter title 与 H1 不一致' }

        $urlPattern = 'https?://[^\s<>)\]"'']+'
        $imagePattern = '!\[[^\]]*\]\([^\r\n)]+\)'
        $codePattern = '(?ms)^```[^\r\n]*\r?\n.*?^```\s*$'
        $sourceUrls = Get-Set ([regex]::Matches($sourceText, $urlPattern).Value)
        $outputUrls = Get-Set ([regex]::Matches($outputText, $urlPattern).Value)
        $sourceImages = Get-Set ([regex]::Matches($sourceText, $imagePattern).Value)
        $outputImages = Get-Set ([regex]::Matches($outputText, $imagePattern).Value)
        $sourceCode = Get-Set ([regex]::Matches($sourceText, $codePattern).Value)
        $outputCode = Get-Set ([regex]::Matches($outputText, $codePattern).Value)

        if ($Mode -eq 'faithful') {
            Compare-ExactSet $sourceUrls $outputUrls 'URL'
            Compare-ExactSet $sourceImages $outputImages '图片引用'
            Compare-ExactSet $sourceCode $outputCode '代码块'
        } else {
            Compare-Subset $sourceUrls $outputUrls 'URL'
            Compare-Subset $sourceImages $outputImages '图片引用'
            Compare-Subset $sourceCode $outputCode '代码块'
        }

        if ($outputBody -match '(?im)^\s*(?:\d+\s*/\s*\d+|thread\b|x\s+thread\b)' -or $outputBody -match '(?im)^#{1,6}\s*(?:微信公众号版|微信版|X\s*版|X\s*Thread)\s*$') {
            Fail '检测到 thread 或平台分版标记'
        } else { Pass '成稿保持单篇文章形态' }

        $sourceLength = ($sourceBody -replace '\s', '').Length
        $outputLength = ($outputBody -replace '\s', '').Length
        $ratio = if ($sourceLength -gt 0) { $outputLength / $sourceLength } else { 0 }
        if ($Mode -eq 'faithful') {
            if ($ratio -lt 0.85) { Fail ('faithful 正文非空白字符比例过低：{0:P1}' -f $ratio) }
            elseif ($ratio -lt 0.95) { Warn ('faithful 正文非空白字符比例为 {0:P1}，需要人工确认没有丢失独立材料' -f $ratio) }
            else { Pass ('faithful 正文非空白字符比例为 {0:P1}' -f $ratio) }
        } else {
            if ($ratio -lt 0.60) { Warn ('publication 正文非空白字符比例为 {0:P1}，需要人工确认承重判断、证据、反例和边界完整' -f $ratio) }
            else { Pass ('publication 正文非空白字符比例为 {0:P1}' -f $ratio) }
        }

        if ($outputBody -match '(?im)^#{1,6}\s*(?:Publication Gate|Reader entry|Opening fulfillment|Narrative progression|Accurate retellability|Natural transmission reason|Durable retrieval anchor|内容账本|承重账本)\s*$' -or
            $outputBody -match '(?im)^\s*(?:Public reader|Recurring situation|Missing capability|Durable payoff|Research consequence)\s*:') {
            Fail '成稿泄漏内部编辑账本、Publication Gate 探针或上游 reader 字段'
        } else { Pass '成稿未泄漏内部编辑探针' }
    }
}

Write-Host ''
if ($script:Warnings.Count -gt 0) { Write-Host "Warnings: $($script:Warnings.Count)" -ForegroundColor Yellow }
if ($script:Failures.Count -gt 0) {
    Write-Host "Checks failed: $($script:Failures.Count)" -ForegroundColor Red
    exit 1
}
Write-Host 'All checks passed.' -ForegroundColor Green
exit 0

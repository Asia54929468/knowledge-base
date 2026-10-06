$ErrorActionPreference = "Stop"

$siteRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$contentDir = Join-Path $siteRoot "docs\software-testing"
$overviewPath = Join-Path $contentDir "index.md"
$searchIndexPath = Join-Path $siteRoot "site\search\search_index.json"
$errors = New-Object System.Collections.Generic.List[string]

$expectedPages = @(
    "01-foundations.md",
    "02-analysis-and-design.md",
    "03-execution-and-quality.md",
    "04-application-testing.md",
    "05-quality-attributes.md",
    "06-automation-and-engineering.md",
    "07-practice-handbook.md"
)

if (-not (Test-Path -LiteralPath $contentDir -PathType Container)) {
    throw "找不到软件测试内容目录：$contentDir"
}

$actualPages = @(
    Get-ChildItem -LiteralPath $contentDir -File -Filter "0*.md" |
        ForEach-Object { $_.Name } |
        Sort-Object
)

if ($actualPages.Count -ne $expectedPages.Count) {
    $errors.Add("软件测试分类页面应为 $($expectedPages.Count) 个，实际为 $($actualPages.Count) 个。")
}

foreach ($page in $expectedPages) {
    if ($page -notin $actualPages) {
        $errors.Add("缺少分类页面：$page")
    }
}

foreach ($page in $actualPages) {
    if ($page -notin $expectedPages) {
        $errors.Add("发现未登记的分类页面：$page")
    }
}

$anchorOwners = @{}

foreach ($page in $expectedPages) {
    $pagePath = Join-Path $contentDir $page
    if (-not (Test-Path -LiteralPath $pagePath -PathType Leaf)) {
        continue
    }

    $content = (Get-Content -Raw -LiteralPath $pagePath -Encoding UTF8) -replace "`r`n", "`n"
    $h1Matches = [regex]::Matches($content, '(?m)^#\s+[^#]')
    if ($h1Matches.Count -ne 1) {
        $errors.Add("$page 必须且只能包含一个 H1，实际为 $($h1Matches.Count) 个。")
    }

    if ([regex]::IsMatch($content, '(?m)^####\s+')) {
        $errors.Add("$page 包含 H4；分类长页最多使用 H3。")
    }

    $h2Lines = [regex]::Matches($content, '(?m)^##\s+.+$')
    if ($h2Lines.Count -eq 0) {
        $errors.Add("$page 至少需要一个 H2 核心主题。")
    }

    foreach ($h2Line in $h2Lines) {
        $anchorMatch = [regex]::Match(
            $h2Line.Value,
            '^##\s+.+\s+\{\s*#(?<anchor>[a-z0-9]+(?:-[a-z0-9]+)*)\s*\}\s*$'
        )

        if (-not $anchorMatch.Success) {
            $errors.Add("$page 的 H2 缺少稳定英文锚点或格式无效：$($h2Line.Value)")
            continue
        }

        $anchor = $anchorMatch.Groups['anchor'].Value
        if ($anchorOwners.ContainsKey($anchor)) {
            $errors.Add("H2 锚点重复：#$anchor 同时出现在 $($anchorOwners[$anchor]) 和 $page。")
        }
        else {
            $anchorOwners[$anchor] = $page
        }
    }
}

if (-not (Test-Path -LiteralPath $overviewPath -PathType Leaf)) {
    $errors.Add("缺少软件测试总览页：docs/software-testing/index.md")
}
else {
    $overview = Get-Content -Raw -LiteralPath $overviewPath -Encoding UTF8
    foreach ($page in $expectedPages) {
        if ($overview -notmatch [regex]::Escape("($page)")) {
            $errors.Add("软件测试总览缺少分类入口：$page")
        }
    }
}

$automationPath = Join-Path $contentDir "06-automation-and-engineering.md"
if (Test-Path -LiteralPath $automationPath -PathType Leaf) {
    $automationContent = Get-Content -Raw -LiteralPath $automationPath -Encoding UTF8
    if ($automationContent -notmatch '(?m)^## 测试隔离与测试替身 \{ #test-isolation-and-doubles \}\s*$') {
        $errors.Add("必须保留核心主题：测试隔离与测试替身，并保留其稳定锚点。")
    }
    if ($automationContent -match '(?m)^##\s+.*服务虚拟化') {
        $errors.Add("不得新增独立的服务虚拟化核心主题。")
    }
}

if (-not (Test-Path -LiteralPath $searchIndexPath -PathType Leaf)) {
    $errors.Add("找不到搜索索引；请先执行 mkdocs build --strict。")
}
else {
    try {
        $searchData = Get-Content -Raw -LiteralPath $searchIndexPath -Encoding UTF8 | ConvertFrom-Json
        $searchText = @(
            $searchData.docs | ForEach-Object { "$($_.title) $($_.text)" }
        ) -join "`n"
    }
    catch {
        $errors.Add("搜索索引不是有效的 JSON：$($_.Exception.Message)")
        $searchText = ""
    }
    $keywords = @(
        "软件质量",
        "V 模型",
        "边界值",
        "缺陷生命周期",
        "API",
        "数据一致性",
        "P95",
        "SQL 注入",
        "Mock",
        "CI/CD",
        "RTO",
        "RPO"
    )

    foreach ($keyword in $keywords) {
        if (-not $searchText.Contains($keyword)) {
            $errors.Add("搜索索引缺少代表关键词：$keyword")
        }
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "内容结构核验通过：7 个分类页面，H2 标题均使用唯一稳定锚点。"
Write-Output "约定主题核验通过：测试隔离与测试替身保持既定边界。"
Write-Output "搜索索引核验通过：12 个代表关键词均可检索。"

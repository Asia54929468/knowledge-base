param(
    [string]$SiteDir
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$docsDir = Join-Path $projectRoot "docs"
$navTemplatePath = Join-Path $projectRoot "overrides\partials\nav-item.html"
$themeStylesheetPath = Join-Path $docsDir "assets\stylesheets\extra.css"

if ([string]::IsNullOrWhiteSpace($SiteDir)) {
    $resolvedSiteDir = Join-Path $projectRoot "site"
}
elseif ([System.IO.Path]::IsPathRooted($SiteDir)) {
    $resolvedSiteDir = [System.IO.Path]::GetFullPath($SiteDir)
}
else {
    $resolvedSiteDir = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $SiteDir))
}

$searchIndexPath = Join-Path $resolvedSiteDir "search\search_index.json"
$errors = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $docsDir -PathType Container)) {
    throw "找不到内容目录：$docsDir"
}

$pages = @(
    Get-ChildItem -LiteralPath $docsDir -File -Filter "*.md" -Recurse |
        Sort-Object FullName
)

if ($pages.Count -eq 0) {
    throw "内容目录中没有 Markdown 页面：$docsDir"
}

$docsRoot = [System.IO.Path]::GetFullPath($docsDir).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$pageLocations = @{}
$pageMetadata = @{}
$pageLinks = @{}
$anchorCount = 0

foreach ($page in $pages) {
    $relativePath = $page.FullName.Substring($docsRoot.Length).Replace('\', '/')
    $lines = @(Get-Content -LiteralPath $page.FullName -Encoding UTF8)
    $metadata = @{}
    $frontMatterEnd = -1

    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") {
        $errors.Add("$relativePath 缺少位于文件开头的 YAML Front Matter。")
    }
    else {
        for ($lineIndex = 1; $lineIndex -lt $lines.Count; $lineIndex++) {
            if ($lines[$lineIndex].Trim() -eq "---") {
                $frontMatterEnd = $lineIndex
                break
            }
        }

        if ($frontMatterEnd -lt 0) {
            $errors.Add("$relativePath 的 YAML Front Matter 未闭合。")
        }
        else {
            for ($lineIndex = 1; $lineIndex -lt $frontMatterEnd; $lineIndex++) {
                $metadataMatch = [regex]::Match(
                    $lines[$lineIndex],
                    '^(?<key>[A-Za-z0-9_-]+):[ \t]*(?<value>.*)$'
                )

                if ($metadataMatch.Success) {
                    $metadata[$metadataMatch.Groups['key'].Value] = $metadataMatch.Groups['value'].Value.Trim().Trim('"', "'")
                }
            }
        }
    }

    foreach ($requiredKey in @("title", "description")) {
        if (-not $metadata.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace($metadata[$requiredKey])) {
            $errors.Add("$relativePath 的 YAML Front Matter 缺少非空字段：$requiredKey")
        }
    }

    $pageMetadata[$relativePath] = $metadata
    $pageLinks[$relativePath] = @{}
    $h1Count = 0
    $pageAnchors = @{}
    $inFence = $false
    $fenceCharacter = ""
    $fenceLength = 0

    foreach ($line in $lines) {
        $fenceMatch = [regex]::Match($line, '^ {0,3}(?<marker>`{3,}|~{3,})(?<rest>.*)$')
        if ($fenceMatch.Success) {
            $marker = $fenceMatch.Groups['marker'].Value
            $markerCharacter = $marker.Substring(0, 1)

            if (-not $inFence) {
                $inFence = $true
                $fenceCharacter = $markerCharacter
                $fenceLength = $marker.Length
            }
            elseif (
                $markerCharacter -eq $fenceCharacter -and
                $marker.Length -ge $fenceLength -and
                [string]::IsNullOrWhiteSpace($fenceMatch.Groups['rest'].Value)
            ) {
                $inFence = $false
                $fenceCharacter = ""
                $fenceLength = 0
            }

            continue
        }

        if ($inFence) {
            continue
        }

        $linkMatches = [regex]::Matches(
            $line,
            '(?<!!)\[[^\]]*\]\((?<target><[^>]+>|[^)\s]+)(?:\s+["''][^"'']*["''])?\)'
        )

        foreach ($linkMatch in $linkMatches) {
            $target = $linkMatch.Groups['target'].Value.Trim()
            if ($target.StartsWith('<') -and $target.EndsWith('>')) {
                $target = $target.Substring(1, $target.Length - 2)
            }

            if ($target -match '^(?:[a-z][a-z0-9+.-]*:|/|#)') {
                continue
            }

            $targetWithoutSuffix = ($target -split '[?#]', 2)[0]
            if ([System.IO.Path]::GetExtension($targetWithoutSuffix) -ine ".md") {
                continue
            }

            $relativeDirectory = [System.IO.Path]::GetDirectoryName($relativePath.Replace('/', '\'))
            if ([string]::IsNullOrWhiteSpace($relativeDirectory)) {
                $combinedTarget = $targetWithoutSuffix
            }
            else {
                $combinedTarget = Join-Path $relativeDirectory $targetWithoutSuffix
            }

            try {
                $resolvedTargetPath = [System.IO.Path]::GetFullPath((Join-Path $docsDir $combinedTarget))
            }
            catch {
                continue
            }

            if ($resolvedTargetPath.StartsWith($docsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                $resolvedTarget = $resolvedTargetPath.Substring($docsRoot.Length).Replace('\', '/')
                $pageLinks[$relativePath][$resolvedTarget] = $true
            }
        }

        if ($line -match '^ {0,3}#[ \t]+\S') {
            $h1Count++
        }

        if ($line -match '^ {0,3}#{1,6}[ \t]+' -and $line -match '\{[^}]*#') {
            $attributeMatch = [regex]::Match(
                $line,
                '\{(?<attributes>[^{}]*)\}\s*$'
            )

            if (-not $attributeMatch.Success) {
                $errors.Add("$relativePath 的显式锚点格式无效：$line")
                continue
            }

            $anchorMatches = [regex]::Matches(
                $attributeMatch.Groups['attributes'].Value,
                '(?:^|\s)#(?<anchor>[^\s]+)'
            )

            if ($anchorMatches.Count -ne 1) {
                $errors.Add("$relativePath 的显式锚点格式无效：$line")
                continue
            }

            $anchor = $anchorMatches[0].Groups['anchor'].Value
            if ($anchor -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
                $errors.Add("$relativePath 的显式锚点只能使用小写字母、数字和连字符：#$anchor")
                continue
            }

            if ($pageAnchors.ContainsKey($anchor)) {
                $errors.Add("$relativePath 的显式锚点重复：#$anchor")
            }
            else {
                $pageAnchors[$anchor] = $true
                $anchorCount++
            }
        }
    }

    if ($inFence) {
        $errors.Add("$relativePath 包含未闭合的代码围栏。")
    }

    if ($h1Count -ne 1) {
        $errors.Add("$relativePath 必须且只能包含一个代码围栏外的 H1，实际为 $h1Count 个。")
    }

    if ($relativePath -ieq "index.md") {
        $pageLocations[$relativePath] = ""
    }
    elseif ($relativePath -match '(^|/)index\.md$') {
        $pageLocations[$relativePath] = $relativePath.Substring(0, $relativePath.Length - "index.md".Length)
    }
    else {
        $pageLocations[$relativePath] = $relativePath.Substring(0, $relativePath.Length - ".md".Length) + "/"
    }
}

$domainIndexPaths = @(
    $pageLocations.Keys |
        Where-Object { $_ -match '^[^/]+/index\.md$' } |
        Sort-Object
)
$domainSummaries = New-Object System.Collections.Generic.List[object]

if ($domainIndexPaths.Count -eq 0) {
    $errors.Add("docs/ 下没有发现包含 index.md 的一级知识领域目录。")
}

$homeLinks = @{}
if ($pageLinks.ContainsKey("index.md")) {
    $homeLinks = $pageLinks["index.md"]
}
else {
    $errors.Add("docs/index.md 不存在，无法提供知识领域入口。")
}

foreach ($domainIndexPath in $domainIndexPaths) {
    $domainDirectory = $domainIndexPath.Substring(0, $domainIndexPath.IndexOf('/'))
    $domainTitle = $domainDirectory
    if ($pageMetadata[$domainIndexPath].ContainsKey("title")) {
        $domainTitle = $pageMetadata[$domainIndexPath]["title"]
    }

    if (
        -not $pageMetadata[$domainIndexPath].ContainsKey("icon") -or
        [string]::IsNullOrWhiteSpace($pageMetadata[$domainIndexPath]["icon"])
    ) {
        $errors.Add("领域 [$domainTitle] 的总览 $domainIndexPath 缺少非空 Front Matter 字段：icon")
    }

    $topicPaths = @(
        $pageLocations.Keys |
            Where-Object {
                $_.StartsWith("$domainDirectory/", [System.StringComparison]::OrdinalIgnoreCase) -and
                $_ -ine $domainIndexPath
            } |
            Sort-Object
    )

    if ($topicPaths.Count -eq 0) {
        $errors.Add("领域 [$domainTitle] 只有总览页，至少需要一个实际主题页。")
    }

    foreach ($topicPath in $topicPaths) {
        if (-not $pageLinks[$domainIndexPath].ContainsKey($topicPath)) {
            $errors.Add("领域 [$domainTitle] 的总览 $domainIndexPath 缺少主题页链接：$topicPath")
        }
    }

    if (-not $homeLinks.ContainsKey($domainIndexPath)) {
        $errors.Add("站点首页 index.md 缺少领域 [$domainTitle] 的总览链接：$domainIndexPath")
    }

    $domainSummaries.Add([pscustomobject]@{
        Title = $domainTitle
        Directory = $domainDirectory
        TopicCount = $topicPaths.Count
    })
}

$navTemplate = ""
if (-not (Test-Path -LiteralPath $navTemplatePath -PathType Leaf)) {
    $errors.Add("找不到领域导航模板：$navTemplatePath")
}
else {
    $navTemplate = Get-Content -Raw -LiteralPath $navTemplatePath -Encoding UTF8
    if (-not $navTemplate.Contains('data-nav-title="{{ ref.title }}"')) {
        $errors.Add("导航模板 overrides/partials/nav-item.html 必须通过 data-nav-title 动态传递 ref.title。")
    }
}

$themeStylesheet = ""
if (-not (Test-Path -LiteralPath $themeStylesheetPath -PathType Leaf)) {
    $errors.Add("找不到主题样式表：$themeStylesheetPath")
}
else {
    $themeStylesheet = Get-Content -Raw -LiteralPath $themeStylesheetPath -Encoding UTF8
    if ($themeStylesheet -notmatch 'attr\s*\(\s*data-nav-title\s*\)') {
        $errors.Add("主题样式 docs/assets/stylesheets/extra.css 必须通过 attr(data-nav-title) 显示当前领域名称。")
    }

}

if (("$navTemplate`n$themeStylesheet") -match '当前领域\s*·\s*[\p{L}\p{N}]') {
    $errors.Add("导航模板和主题样式不得在 [当前领域 ·] 后写死具体领域名称。")
}

if (-not (Test-Path -LiteralPath $searchIndexPath -PathType Leaf)) {
    $errors.Add("找不到搜索索引；请先执行 mkdocs build --strict：$searchIndexPath")
}
else {
    try {
        $searchData = Get-Content -Raw -LiteralPath $searchIndexPath -Encoding UTF8 | ConvertFrom-Json
        $indexedLocations = @($searchData.docs | ForEach-Object { [string]$_.location })

        foreach ($relativePath in $pageLocations.Keys) {
            $expectedLocation = $pageLocations[$relativePath]
            if ($expectedLocation -notin $indexedLocations) {
                $errors.Add("搜索索引缺少页面：$relativePath（预期位置：$expectedLocation）")
            }
        }
    }
    catch {
        $errors.Add("搜索索引不是有效的 JSON：$($_.Exception.Message)")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    exit 1
}

Write-Output "知识领域检查通过：发现 $($domainSummaries.Count) 个领域，首页和领域总览已覆盖全部内容入口。"
foreach ($domainSummary in $domainSummaries) {
    Write-Output "  - $($domainSummary.Title)（$($domainSummary.Directory)）：$($domainSummary.TopicCount) 个主题页"
}
Write-Output "动态领域标题检查通过：导航模板与主题样式未写死具体领域名称。"
Write-Output "内容结构检查通过：$($pages.Count) 个 Markdown 页面均包含一个代码围栏外的 H1。"
Write-Output "锚点检查通过：$anchorCount 个显式锚点格式有效且在各自页面内唯一。"
Write-Output "搜索索引检查通过：所有 Markdown 页面均已进入索引。"

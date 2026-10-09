param(
    [string]$SiteDir
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$docsDir = Join-Path $projectRoot "docs"

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
$anchorCount = 0

foreach ($page in $pages) {
    $relativePath = $page.FullName.Substring($docsRoot.Length).Replace('\', '/')
    $lines = @(Get-Content -LiteralPath $page.FullName -Encoding UTF8)
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

Write-Output "内容结构检查通过：$($pages.Count) 个 Markdown 页面均包含一个代码围栏外的 H1。"
Write-Output "锚点检查通过：$anchorCount 个显式锚点格式有效且在各自页面内唯一。"
Write-Output "搜索索引检查通过：所有 Markdown 页面均已进入索引。"

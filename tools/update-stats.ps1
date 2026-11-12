<#
  Refreshes assets/activity/stats-{dark,light}.svg with real numbers from GitHub.

  CI:     runs daily in the "Profile assets" workflow (uses GITHUB_TOKEN).
  Local:  powershell -ExecutionPolicy Bypass -File tools/update-stats.ps1
          No token needed: it reads the public contribution calendar instead.
  -FromCache  re-renders from assets/activity/stats.json without calling GitHub.

  If GitHub cannot be reached, the existing files are left untouched, so the
  README never shows a broken image because of a failed refresh.
#>
param([switch]$FromCache)
. (Join-Path $PSScriptRoot 'lib.ps1')
$Prof = Read-ProfileData
$User = $Prof.GitHub
$cachePath = Join-Path $script:RepoRoot 'assets/activity/stats.json'

$script:Hdr = @{ 'User-Agent' = 'mhanikbd-profile-stats'; 'Accept' = 'application/vnd.github+json' }
if ($env:GITHUB_TOKEN) { $script:Hdr['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }

function Get-Api([string]$path) {
    Invoke-RestMethod -UseBasicParsing -Headers $script:Hdr -Uri ('https://api.github.com/' + $path)
}

function Get-CalendarGraphQL {
    $q = 'query($login:String!){user(login:$login){contributionsCollection{contributionCalendar{weeks{contributionDays{date contributionCount}}}}}}'
    $body = @{ query = $q; variables = @{ login = $User } } | ConvertTo-Json -Depth 5 -Compress
    $res = Invoke-RestMethod -UseBasicParsing -Method Post -Uri 'https://api.github.com/graphql' -Headers $script:Hdr -Body $body -ContentType 'application/json'
    if ($res.PSObject.Properties.Name -contains 'errors' -and $res.errors) { throw ($res.errors | ConvertTo-Json -Compress) }
    $list = New-Object System.Collections.ArrayList
    foreach ($wk in $res.data.user.contributionsCollection.contributionCalendar.weeks) {
        foreach ($dy in $wk.contributionDays) { [void]$list.Add([pscustomobject]@{ date = [string]$dy.date; count = [int]$dy.contributionCount }) }
    }
    , $list.ToArray()
}

function Get-CalendarHtml {
    $html = (Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'mhanikbd-profile-stats' } -Uri "https://github.com/users/$User/contributions").Content
    $dateById = @{}
    foreach ($m in [regex]::Matches($html, '<td[^>]*ContributionCalendar-day[^>]*>')) {
        $dm = [regex]::Match($m.Value, 'data-date="([0-9-]+)"'); $im = [regex]::Match($m.Value, '\sid="([^"]+)"')
        if ($dm.Success -and $im.Success) { $dateById[$im.Groups[1].Value] = $dm.Groups[1].Value }
    }
    $countById = @{}
    foreach ($m in [regex]::Matches($html, '<tool-tip[^>]*\sfor="([^"]+)"[^>]*>([^<]*)</tool-tip>')) {
        $num = 0; $cm = [regex]::Match($m.Groups[2].Value.Trim(), '^(\d[\d,]*) contribution')
        if ($cm.Success) { $num = [int]($cm.Groups[1].Value -replace ',', '') }
        $countById[$m.Groups[1].Value] = $num
    }
    if ($dateById.Count -lt 300) { throw "Contribution calendar not found ($($dateById.Count) days parsed)" }
    $list = New-Object System.Collections.ArrayList
    foreach ($k in $dateById.Keys) {
        $cnt = 0; if ($countById.ContainsKey($k)) { $cnt = $countById[$k] }
        [void]$list.Add([pscustomobject]@{ date = $dateById[$k]; count = $cnt })
    }
    , $list.ToArray()
}

function Get-Stats {
    $days = $null
    if ($env:GITHUB_TOKEN) {
        try { $days = Get-CalendarGraphQL } catch { Write-Warning "GraphQL calendar failed, falling back to the public page: $_" }
    }
    if (-not $days) { $days = Get-CalendarHtml }
    $days = @($days | Sort-Object date)

    $repos = @(); $page = 1
    do {
        $batch = Get-Api "users/$User/repos?per_page=100&type=owner&page=$page"
        $batch = @($batch)
        $repos += $batch; $page++
    } while ($batch.Count -eq 100)
    $own = @($repos | Where-Object { -not $_.fork -and $_.name -ne $User })

    $langs = @{}
    foreach ($repo in $own) {
        if ($repo.size -eq 0) { continue }
        $lg = Get-Api "repos/$User/$($repo.name)/languages"
        foreach ($prop in $lg.PSObject.Properties) { $langs[$prop.Name] = [int64]$langs[$prop.Name] + [int64]$prop.Value }
    }

    $total = 0; $active = 0; $longest = 0; $run = 0
    foreach ($dy in $days) {
        $total += $dy.count
        if ($dy.count -gt 0) { $active++; $run++; if ($run -gt $longest) { $longest = $run } } else { $run = 0 }
    }
    $current = 0; $idx = $days.Count - 1
    if ($idx -ge 0 -and $days[$idx].count -eq 0) { $idx-- }   # today may simply not have started
    while ($idx -ge 0 -and $days[$idx].count -gt 0) { $current++; $idx-- }

    $top = @($langs.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object { [pscustomobject]@{ name = $_.Key; bytes = [int64]$_.Value } })
    $stars = 0; foreach ($repo in $own) { $stars += [int]$repo.stargazers_count }
    [pscustomobject]@{
        generated  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
        user       = $User
        from       = $days[0].date
        to         = $days[$days.Count - 1].date
        total      = $total
        activeDays = $active
        longest    = $longest
        current    = $current
        repos      = $own.Count
        stars      = $stars
        languages  = $top
    }
}

function Build-Stats($t, $S) {
    $W = 900; $H = 262
    $tiles = @(
        @('CONTRIBUTIONS', [string]$S.total, '', 'in the last 12 months'),
        @('ACTIVE DAYS', [string]$S.activeDays, '', 'days with contributions'),
        @('LONGEST STREAK', [string]$S.longest, ' days', 'consecutive, past 12 months'),
        @('REPOSITORIES', [string]$S.repos, '', 'original public repositories')
    )
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((New-Panel 0.5 0.5 899 261 $t 24))
    for ($i = 0; $i -lt 4; $i++) {
        $x = 28 + $i * 214; $y = 28; $tl = $tiles[$i]
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.08 * $i))s'>")
        [void]$sb.Append("<rect x='$x' y='$y' width='200' height='104' rx='16' fill='$($t.panel2)' stroke='$($t.line)'/>")
        [void]$sb.Append("<text x='$($x + 20)' y='$($y + 30)' class='m t3' font-size='10.5' font-weight='500' letter-spacing='1.6'>$($tl[0])</text>")
        [void]$sb.Append("<text x='$($x + 20)' y='$($y + 72)' class='d t1' font-size='34' font-weight='700' letter-spacing='-.5'>$(X $tl[1])<tspan class='s t3' font-size='14' font-weight='500'>$(X $tl[2])</tspan></text>")
        [void]$sb.Append("<text x='$($x + 20)' y='$($y + 93)' class='s t3' font-size='12'>$(X $tl[3])</text></g>")
    }
    # language bar
    $langs = @($S.languages); $sum = 0.0; foreach ($lg in $langs) { $sum += [double]$lg.bytes }
    $colors = @($t.g2, $t.g3, $t.g1, $t.gold, $t.text3, $t.line2)
    $shown = @(); $other = 0.0
    for ($i = 0; $i -lt $langs.Count; $i++) { if ($i -lt 5) { $shown += $langs[$i] } else { $other += [double]$langs[$i].bytes } }
    if ($other -gt 0) { $shown += [pscustomobject]@{ name = 'Other'; bytes = $other } }
    [void]$sb.Append("<text x='28' y='170' class='m t3' font-size='10.5' font-weight='500' letter-spacing='1.6'>LANGUAGES BY CODE VOLUME</text>")
    [void]$sb.Append("<text x='872' y='170' text-anchor='end' class='m t3' font-size='10.5' letter-spacing='1.2'>ACROSS $($S.repos) ORIGINAL REPOS</text>")
    [void]$sb.Append("<rect x='28' y='182' width='844' height='10' rx='5' fill='$($t.chipBg)'/>")
    [void]$sb.Append("<g clip-path='url(#lb)'><g class='gx'>")
    $bx = 28.0; $lx = 28.0; $ly = 222; $legend = ''
    for ($i = 0; $i -lt $shown.Count; $i++) {
        $frac = 0.0; if ($sum -gt 0) { $frac = [double]$shown[$i].bytes / $sum }
        $segW = 844 * $frac   # not $w: PowerShell names ignore case and $W is the canvas width
        [void]$sb.Append("<rect x='$(Rnd $bx)' y='182' width='$(Rnd ([math]::Max($segW, 0)))' height='10' fill='$($colors[$i])'/>")
        $bx += $segW
        $label = $shown[$i].name + ' ' + [math]::Round($frac * 100, 1) + '%'
        $iw = 14 + (MonoW $label 11 0) + 24
        if ($lx + $iw -gt 872 -and $lx -gt 28) { $lx = 28; $ly += 20 }
        $legend += "<circle cx='$(Rnd ($lx + 4.5))' cy='$($ly - 4)' r='4.5' fill='$($colors[$i])'/><text x='$(Rnd ($lx + 14))' y='$ly' class='m t2' font-size='11'>$(X $label)</text>"
        $lx += $iw
    }
    [void]$sb.Append('</g></g>')
    [void]$sb.Append("<g class='up' style='animation-delay:.4s'>$legend</g>")
    [void]$sb.Append("<text x='872' y='$($H - 16)' text-anchor='end' class='m t3' font-size='10' letter-spacing='1.2' opacity='.8'>UPDATED $($S.generated) $script:MID LIVE DATA FROM GITHUB</text>")
    $css = ".gx{transform-box:fill-box;transform-origin:left;animation:gx 1.4s .3s cubic-bezier(.3,.6,.2,1) both}@keyframes gx{from{transform:scaleX(0)}to{transform:none}}"
    $defs = "<clipPath id='lb'><rect x='28' y='182' width='844' height='10' rx='5'/></clipPath>"
    $desc = "GitHub activity for $($S.user) from $($S.from) to $($S.to): $($S.total) contributions, $($S.activeDays) active days, longest streak $($S.longest) days, $($S.repos) original public repositories. Languages: " +
            (($shown | ForEach-Object { $_.name + ' ' + [math]::Round(([double]$_.bytes / [math]::Max($sum, 1)) * 100, 1) + '%' }) -join ', ') + '.'
    New-SvgDoc -W $W -H $H -Title 'GitHub activity' -Desc $desc -Theme $t -Css $css -Defs $defs -Body $sb.ToString() -Fonts @('Sora')
}

# ---------------------------------------------------------------- run --
if ($FromCache) {
    $S = [IO.File]::ReadAllText($cachePath, [Text.Encoding]::UTF8) | ConvertFrom-Json
} else {
    try { $S = Get-Stats }
    catch {
        Write-Warning "Could not refresh stats, keeping the current files: $_"
        exit 0
    }
    [IO.File]::WriteAllText($cachePath, ($S | ConvertTo-Json -Depth 5), $script:Utf8NoBom)
}
Write-Host "Stats for $($S.user): $($S.total) contributions, $($S.activeDays) active days, longest streak $($S.longest), $($S.repos) repos"
foreach ($th in $script:Themes.Values) { Save-Svg "assets/activity/stats-$($th.name).svg" (Build-Stats $th $S) }

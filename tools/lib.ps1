# Shared helpers for the profile asset generators (build-assets.ps1, update-stats.ps1).
# Runs on Windows PowerShell 5.1 and on PowerShell 7 (the GitHub Actions ubuntu runner).
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as ANSI.

$ErrorActionPreference = 'Stop'

$script:RepoRoot  = Split-Path -Parent $PSScriptRoot
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$script:EM  = [string][char]0x2014   # em dash
$script:MID = [string][char]0x00B7   # middle dot
$script:ARR = [string][char]0x2192   # right arrow

# ---------------------------------------------------------------- palette --
# One design system, two themes. GitHub shows the matching file through <picture>.
$script:Themes = [ordered]@{
    dark  = @{
        name = 'dark'
        bg = '#060A14'; panel = '#0B1222'; panel2 = '#0F1830'; line = '#1B2640'; line2 = '#2A3A60'
        text = '#F1F5F9'; text2 = '#A9B5C8'; text3 = '#71809A'
        g1 = '#2DD4BF'; g2 = '#38BDF8'; g3 = '#818CF8'; gold = '#F5B841'
        aur1 = '#0EA5A4'; aur2 = '#6366F1'; aur3 = '#0284C7'; aurOp = '0.42'
        grid = '#1A2542'; chipBg = '#0E182D'; chipLine = '#24345A'
    }
    light = @{
        name = 'light'
        bg = '#F5F8FC'; panel = '#FFFFFF'; panel2 = '#F3F6FB'; line = '#E1E7F0'; line2 = '#C9D3E1'
        text = '#0B1324'; text2 = '#44536A'; text3 = '#6B7890'
        g1 = '#0D9488'; g2 = '#0284C7'; g3 = '#4F46E5'; gold = '#B7791F'
        aur1 = '#5EEAD4'; aur2 = '#A5B4FC'; aur3 = '#7DD3FC'; aurOp = '0.50'
        grid = '#D9E1EC'; chipBg = '#F1F5FA'; chipLine = '#D3DCE8'
    }
}

# ------------------------------------------------------------------ input --
function Read-ProfileData {
    $path = Join-Path $script:RepoRoot 'profile.psd1'
    $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    $sb = [scriptblock]::Create($text)
    # Same safety rules as a PowerShell data file: literals only, no commands.
    $sb.CheckRestrictedLanguage([string[]]@(), [string[]]@('true', 'false', 'null'), $false)
    & $sb
}

# ---------------------------------------------------------------- strings --
function X([string]$s) {
    if ($null -eq $s) { return '' }
    [System.Security.SecurityElement]::Escape($s)
}

function Rnd([double]$n) { [math]::Round($n, 2) }

# Width of monospaced text: every glyph is 0.6em wide.
function MonoW([string]$s, [double]$size, [double]$ls = 0) {
    $s.Length * ($size * 0.6 + $ls)
}

# ------------------------------------------------------------------ fonts --
$script:FontCache = @{}
function Get-FontCss([string[]]$Families) {
    $css = ''
    foreach ($f in $Families) {
        if ($f -eq 'Sora') { $file = 'Sora-latin.woff2'; $fam = 'Sora' }
        elseif ($f -eq 'Mono') { $file = 'JetBrainsMono-latin.woff2'; $fam = 'JetBrains Mono' }
        else { throw "Unknown font $f" }
        if (-not $script:FontCache.ContainsKey($file)) {
            $p = Join-Path (Join-Path $PSScriptRoot 'fonts') $file
            $script:FontCache[$file] = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
        }
        $css += "@font-face{font-family:'$fam';font-style:normal;font-weight:100 800;src:url(data:font/woff2;base64,$($script:FontCache[$file])) format('woff2')}"
    }
    $css
}

# ------------------------------------------------------------- css + defs --
# Rule for every animation: the un-animated state is the finished state, so
# static renderers and reduced-motion users still see the complete design.
function Get-BaseCss($t) {
@"
.d{font-family:'Sora','Segoe UI',system-ui,-apple-system,'Helvetica Neue',Arial,sans-serif}
.s{font-family:'Segoe UI',system-ui,-apple-system,'Helvetica Neue',Roboto,Arial,sans-serif}
.m{font-family:'JetBrains Mono','SF Mono','Cascadia Code',Menlo,Consolas,'Liberation Mono',monospace}
.t1{fill:$($t.text)}.t2{fill:$($t.text2)}.t3{fill:$($t.text3)}.gd{fill:$($t.gold)}.ac{fill:$($t.g2)}
.fx{transform-box:fill-box;transform-origin:center}
.up{animation:fadeUp .9s cubic-bezier(.2,.7,.2,1) both}
.ping{transform-box:fill-box;transform-origin:center;animation:ping 2.6s ease-out infinite}
.blink{animation:blink 1.05s step-end infinite}
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:none}}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
@keyframes ping{0%{opacity:.85;transform:scale(1)}70%,100%{opacity:0;transform:scale(2.8)}}
@keyframes blink{0%,49%{opacity:1}50%,100%{opacity:0}}
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes spinr{to{transform:rotate(-360deg)}}
@keyframes glow{0%,100%{opacity:0}8%{opacity:.9}24%{opacity:0}}
@media (prefers-reduced-motion:reduce){*{animation:none!important}}
"@
}

function Get-CommonDefs($t) {
@"
<linearGradient id="gA" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="$($t.g1)"/><stop offset=".55" stop-color="$($t.g2)"/><stop offset="1" stop-color="$($t.g3)"/></linearGradient>
<linearGradient id="gV" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="$($t.g1)"/><stop offset=".55" stop-color="$($t.g2)"/><stop offset="1" stop-color="$($t.g3)"/></linearGradient>
<linearGradient id="gD" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="$($t.g1)"/><stop offset=".5" stop-color="$($t.g2)"/><stop offset="1" stop-color="$($t.g3)"/></linearGradient>
<linearGradient id="streak" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="$($t.g2)" stop-opacity="0"/><stop offset=".5" stop-color="$($t.g2)" stop-opacity=".95"/><stop offset="1" stop-color="$($t.g2)" stop-opacity="0"/></linearGradient>
<radialGradient id="au1"><stop offset="0" stop-color="$($t.aur1)" stop-opacity="$($t.aurOp)"/><stop offset="1" stop-color="$($t.aur1)" stop-opacity="0"/></radialGradient>
<radialGradient id="au2"><stop offset="0" stop-color="$($t.aur2)" stop-opacity="$($t.aurOp)"/><stop offset="1" stop-color="$($t.aur2)" stop-opacity="0"/></radialGradient>
<radialGradient id="au3"><stop offset="0" stop-color="$($t.aur3)" stop-opacity="$($t.aurOp)"/><stop offset="1" stop-color="$($t.aur3)" stop-opacity="0"/></radialGradient>
<pattern id="dots" width="22" height="22" patternUnits="userSpaceOnUse"><circle cx="2" cy="2" r="1.1" fill="$($t.grid)"/></pattern>
"@
}

function New-SvgDoc {
    param([double]$W, [double]$H, [string]$Title, [string]$Desc, $Theme,
          [string]$Css = '', [string]$Defs = '', [string]$Body = '', [string[]]$Fonts = @())
    $fontCss = ''
    if ($Fonts -and $Fonts.Count -gt 0) { $fontCss = Get-FontCss $Fonts }
@"
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H" viewBox="0 0 $W $H" role="img" aria-labelledby="title desc">
<title id="title">$(X $Title)</title>
<desc id="desc">$(X $Desc)</desc>
<defs>
<style>
$fontCss
$(Get-BaseCss $Theme)
$Css
</style>
$(Get-CommonDefs $Theme)
$Defs
</defs>
$Body
</svg>
"@
}

function Save-Svg([string]$RelPath, [string]$Content) {
    $p = Join-Path $script:RepoRoot $RelPath
    $dir = Split-Path -Parent $p
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [IO.File]::WriteAllText($p, $Content, $script:Utf8NoBom)
    Write-Host ('  {0,-52} {1,7:N0} bytes' -f $RelPath, (Get-Item $p).Length)
}

# ------------------------------------------------------------- primitives --
function New-Panel([double]$x, [double]$y, [double]$w, [double]$h, $t, [double]$r = 22, [switch]$NoHairline) {
    $s = "<rect x='$x' y='$y' width='$w' height='$h' rx='$r' fill='$($t.panel)' stroke='$($t.line)'/>"
    if (-not $NoHairline) {
        $s += "<rect x='$(Rnd ($x + $r))' y='$y' width='$(Rnd ($w - 2 * $r))' height='1.2' fill='url(#gA)' opacity='.55'/>"
    }
    $s
}

function New-Chip {
    param([double]$X, [double]$Y, [string]$Text, $Theme, [double]$Size = 12, [double]$H = 28,
          [double]$Pad = 13, [string]$Tone = 'default', [double]$Ls = 0.4)
    $t = $Theme
    $w = Rnd ((MonoW $Text $Size $Ls) + 2 * $Pad)
    switch ($Tone) {
        'accent' { $stroke = $t.g2;   $tc = $t.g2;    $so = '.55' }
        'gold'   { $stroke = $t.gold; $tc = $t.gold;  $so = '.6' }
        default  { $stroke = $t.chipLine; $tc = $t.text2; $so = '1' }
    }
    $ty = Rnd ($Y + $H / 2 + $Size * 0.36)
    $svg = "<rect x='$(Rnd $X)' y='$(Rnd $Y)' width='$w' height='$H' rx='$(Rnd ($H / 2))' fill='$($t.chipBg)' stroke='$stroke' stroke-opacity='$so'/>" +
           "<text x='$(Rnd ($X + $Pad))' y='$ty' class='m' font-size='$Size' font-weight='500' letter-spacing='$Ls' fill='$tc'>$(X $Text)</text>"
    [pscustomobject]@{ Svg = $svg; Width = $w }
}

# Lays chips out left to right, wrapping to new rows inside MaxW.
function New-ChipFlow {
    param([double]$X, [double]$Y, [double]$MaxW, [string[]]$Items, $Theme, [double]$Size = 12.5,
          [double]$H = 30, [double]$Gap = 9, [double]$RowGap = 10, [string]$Tone = 'default',
          [double]$Pad = 13, [double]$Ls = 0.2, [double]$Delay = -1, [double]$Step = 0.06)
    $cx = $X; $cy = $Y; $sb = New-Object System.Text.StringBuilder; $i = 0
    foreach ($it in $Items) {
        $w = (MonoW $it $Size $Ls) + 2 * $Pad
        if (($cx - $X + $w) -gt $MaxW -and $cx -gt $X) { $cx = $X; $cy += $H + $RowGap }
        $c = New-Chip -X $cx -Y $cy -Text $it -Theme $Theme -Size $Size -H $H -Pad $Pad -Tone $Tone -Ls $Ls
        if ($Delay -ge 0) {
            [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd ($Delay + $i * $Step))s'>$($c.Svg)</g>")
        } else { [void]$sb.Append($c.Svg) }
        $cx += $c.Width + $Gap; $i++
    }
    [pscustomobject]@{ Svg = $sb.ToString(); Bottom = ($cy + $H) }
}

# 28x28 line icons, drawn for this profile.
$script:Icons = @{
    bank   = "<path d='M3 11 L14 4 L25 11 Z'/><path d='M6.5 13.5 V21.5 M11.5 13.5 V21.5 M16.5 13.5 V21.5 M21.5 13.5 V21.5'/><path d='M3 24.5 H25'/>"
    chart  = "<path d='M4 4 V24 H25'/><path d='M8 19 L13 13.5 L17 16.5 L24 8'/><path d='M19 8 H24 V13'/>"
    web    = "<rect x='3' y='5' width='22' height='18' rx='3'/><path d='M3 10 H25'/><path d='M11 14.5 L8.5 17 L11 19.5 M17 14.5 L19.5 17 L17 19.5'/>"
    rocket = "<path d='M14 3 C19.5 7 21 13 18 20 H10 C7 13 8.5 7 14 3 Z'/><circle cx='14' cy='11' r='2.3'/><path d='M10 20 L7 24.5 M18 20 L21 24.5 M14 20 V25'/>"
    pen    = "<path d='M5 23 L6 18 L19 5 L23 9 L10 22 Z'/><path d='M16.5 7.5 L20.5 11.5'/>"
    spark  = "<path d='M13 4 L15.2 11.8 L23 14 L15.2 16.2 L13 24 L10.8 16.2 L3 14 L10.8 11.8 Z'/><path d='M22.5 3 V8 M20 5.5 H25'/>"
    target = "<circle cx='14' cy='14' r='10.5'/><circle cx='14' cy='14' r='5.5'/><circle cx='14' cy='14' r='1.3'/>"
    code   = "<path d='M10 8 L4 14 L10 20 M18 8 L24 14 L18 20 M16 5 L12 23'/>"
    arrow  = "<path d='M8 20 L20 8 M10.5 8 H20 V17.5'/>"
    pin    = "<path d='M14 25 C14 25 6 17 6 11.5 A8 8 0 0 1 22 11.5 C22 17 14 25 14 25 Z'/><circle cx='14' cy='11.5' r='2.8'/>"
}
function New-Icon([string]$Name, [double]$X, [double]$Y, [string]$Color, [double]$Scale = 1, [double]$Sw = 1.8) {
    "<g transform='translate($(Rnd $X) $(Rnd $Y)) scale($Scale)' fill='none' stroke='$Color' stroke-width='$Sw' stroke-linecap='round' stroke-linejoin='round'>$($script:Icons[$Name])</g>"
}

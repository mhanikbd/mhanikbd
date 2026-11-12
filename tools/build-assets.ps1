<#
  Builds every design graphic under assets/ from profile.psd1, in a dark and a
  light version. GitHub picks the right one with <picture> in README.md.

  Local:   powershell -ExecutionPolicy Bypass -File tools/build-assets.ps1
  CI:      pwsh ./tools/build-assets.ps1   (the "Profile assets" workflow)

  If assets/source/profile-photo.jpg exists it is embedded in the hero banner;
  otherwise the hero shows the monogram from profile.psd1.
#>
. (Join-Path $PSScriptRoot 'lib.ps1')
$P = Read-ProfileData

# =================================================================== HERO ==
function Build-Hero($t) {
    $W = 1000; $H = 420; $cx = 180; $cy = 200

    # --- portrait: photo if present, monogram otherwise
    $photo = Join-Path $script:RepoRoot 'assets/source/profile-photo.jpg'
    if (Test-Path $photo) {
        $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($photo))
        $portrait = "<image href='data:image/jpeg;base64,$b64' x='$($cx - 99)' y='$($cy - 99)' width='198' height='198' preserveAspectRatio='xMidYMid slice' clip-path='url(#pc)'/>"
    } else {
        $portrait = "<text x='$cx' y='$($cy + 14)' text-anchor='middle' class='d' font-size='48' font-weight='700' letter-spacing='1' fill='url(#gA)'>$(X $P.Monogram)</text>" +
                    "<text x='$cx' y='$($cy + 44)' text-anchor='middle' class='m t3' font-size='10.5' font-weight='500' letter-spacing='3'>SINCE $($P.Since)</text>"
    }

    # --- typing line: each phrase types in, holds, and erases (SMIL, discrete steps)
    # (PowerShell variable names ignore case: never reuse $p/$t/$c for locals here.)
    $phr = @($P.Rotating); $slot = 4.0; $period = $slot * $phr.Count; $cw = 17 * 0.6; $x0 = 362
    $clipDefs = ''; $phrases = ''; $caret = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $phr.Count; $i++) {
        $txt = $phr[$i]; $n = $txt.Length; $s = $slot * $i
        $pts = New-Object System.Collections.ArrayList
        if ($i -gt 0) { [void]$pts.Add(@(0.0, 0.0)) }
        for ($k = 0; $k -le $n; $k++) { [void]$pts.Add(@(($s + $k * 1.5 / $n), ($k * $cw))) }
        [void]$pts.Add(@(($s + 3.3), ($n * $cw)))
        for ($k = $n - 1; $k -ge 0; $k--) { [void]$pts.Add(@(($s + 3.3 + ($n - $k) * 0.45 / $n), ($k * $cw))) }
        foreach ($pt in $pts) { if (-not ($i -gt 0 -and $pt[0] -eq 0.0)) { [void]$caret.Add($pt) } }
        [void]$pts.Add(@($period, 0.0))
        $kt = ($pts | ForEach-Object { [math]::Round($_[0] / $period, 4) }) -join ';'
        $vs = ($pts | ForEach-Object { [math]::Round($_[1], 1) }) -join ';'
        $base = 0; if ($i -eq 0) { $base = Rnd ($n * $cw + 2) }
        $clipDefs += "<clipPath id='tc$i'><rect x='$x0' y='258' height='32' width='$base'><animate attributeName='width' dur='$($period)s' repeatCount='indefinite' calcMode='discrete' keyTimes='$kt' values='$vs'/></rect></clipPath>"
        $phrases += "<text x='$x0' y='280' class='m t1' font-size='17' font-weight='500' clip-path='url(#tc$i)'>$(X $txt)</text>"
    }
    [void]$caret.Add(@($period, 0.0))
    $ckt = ($caret | ForEach-Object { [math]::Round($_[0] / $period, 4) }) -join ';'
    $cvs = ($caret | ForEach-Object { [math]::Round($x0 + $_[1] + 2, 1) }) -join ';'
    $caretBase = Rnd ($x0 + $phr[0].Length * $cw + 2)

    # --- focus pills
    $pills = ''; $px = 340
    foreach ($f in $P.Focus) {
        $c = New-Chip -X $px -Y 210 -Text $f -Theme $t -Size 12.5 -H 30 -Pad 14 -Ls 0.3
        $pills += $c.Svg; $px += $c.Width + 10
    }

    # --- location chip under the portrait
    $loc = $P.Location.ToUpper(); $lw = (MonoW $loc 11 1.8) + 46; $lx = $cx - $lw / 2; $ly = 348
    $locSvg = "<rect x='$(Rnd $lx)' y='$ly' width='$(Rnd $lw)' height='30' rx='15' fill='$($t.chipBg)' stroke='$($t.chipLine)'/>" +
              (New-Icon 'pin' ($lx + 12) ($ly + 7) $t.gold 0.58 2.4) +
              "<text x='$(Rnd ($lx + 32))' y='$($ly + 19.5)' class='m t2' font-size='11' font-weight='500' letter-spacing='1.8'>$(X $loc)</text>"

    $css = @"
.a1,.a2,.a3{transform-box:fill-box;transform-origin:center}
.a1{animation:dr1 22s ease-in-out infinite alternate}
.a2{animation:dr2 27s ease-in-out infinite alternate}
.a3{animation:dr3 31s ease-in-out infinite alternate}
@keyframes dr1{to{transform:translate(-90px,50px) scale(1.15)}}
@keyframes dr2{to{transform:translate(90px,-40px) scale(1.1)}}
@keyframes dr3{to{transform:translate(-70px,-50px) scale(1.2)}}
.ring{transform-origin:$($cx)px $($cy)px;animation:spin 18s linear infinite}
.ring2{transform-origin:$($cx)px $($cy)px;animation:spinr 60s linear infinite}
.orb{transform-origin:$($cx)px $($cy)px;animation:spin 10s linear infinite}
.halo{transform-origin:$($cx)px $($cy)px;animation:breathe 7s ease-in-out infinite alternate}
@keyframes breathe{from{opacity:.6;transform:scale(.95)}to{opacity:1;transform:scale(1.05)}}
.cf{stroke-dasharray:22 420;animation:cflow 6s linear infinite}
@keyframes cflow{from{stroke-dashoffset:442}to{stroke-dashoffset:0}}
.st{animation:travel 5s cubic-bezier(.5,0,.3,1) infinite}
@keyframes travel{0%{transform:translateX(0);opacity:0}12%{opacity:1}88%{opacity:1}100%{transform:translateX(560px);opacity:0}}
.np{transform-box:fill-box;transform-origin:center;animation:np 5s ease-out infinite}
@keyframes np{0%{opacity:.9;transform:scale(1)}30%,100%{opacity:0;transform:scale(3)}}
"@

    $defs = @"
<radialGradient id="fade" cx=".62" cy=".42" r=".75"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
<mask id="dm"><rect width="$W" height="$H" fill="url(#fade)"/></mask>
<clipPath id="frame"><rect width="$W" height="$H" rx="28"/></clipPath>
<clipPath id="pc"><circle cx="$cx" cy="$cy" r="99"/></clipPath>
<radialGradient id="disc" cx=".35" cy=".3" r=".9"><stop offset="0" stop-color="$($t.panel2)"/><stop offset="1" stop-color="$($t.panel)"/></radialGradient>
$clipDefs
"@

    $circuit = "M1000 34 H936 L912 58 H866|M1000 80 H960 L946 94 H904|M972 0 V14 L956 30 H930|M1000 296 H964 L942 318 V350"
    $paths = $circuit.Split('|')
    $c1 = ($paths | ForEach-Object { "<path d='$_'/>" }) -join ''
    $c2 = "<path class='cf' d='$($paths[0])'/><path class='cf' style='animation-delay:-2s' d='$($paths[1])'/><path class='cf' style='animation-delay:-4s' d='$($paths[3])'/>"

    $flowNodes = ''
    $nodes = @(@(340, $t.g2, 0.15, 'IDEAS', 'start'), @(620, $t.g2, 2.5, 'TECHNOLOGY', 'middle'), @(900, $t.gold, 4.85, 'IMPACT', 'end'))
    foreach ($nd in $nodes) {
        $flowNodes += "<circle cx='$($nd[0])' cy='350' r='6' fill='$($t.bg)' stroke='$($nd[1])' stroke-width='2'/>" +
                      "<circle cx='$($nd[0])' cy='350' r='6' fill='none' stroke='$($nd[1])' stroke-width='1.5' class='np' style='animation-delay:$($nd[2])s' opacity='0'/>" +
                      "<text x='$($nd[0])' y='380' text-anchor='$($nd[4])' class='m t3' font-size='11' font-weight='500' letter-spacing='3'>$($nd[3])</text>"
    }

    $body = @"
<g clip-path="url(#frame)">
<rect width="$W" height="$H" fill="$($t.bg)"/>
<rect width="$W" height="$H" fill="url(#dots)" mask="url(#dm)"/>
<g class="a1"><circle cx="800" cy="40" r="330" fill="url(#au2)"/></g>
<g class="a2"><circle cx="150" cy="400" r="300" fill="url(#au1)"/></g>
<g class="a3"><circle cx="990" cy="430" r="260" fill="url(#au3)"/></g>
<g fill="none" stroke="$($t.line2)" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">$c1</g>
<g fill="none" stroke="$($t.g2)" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">$c2</g>
<g fill="$($t.g2)"><circle cx="866" cy="58" r="3"/><circle cx="904" cy="94" r="3"/><circle cx="930" cy="30" r="2.5"/><circle cx="942" cy="350" r="3"/></g>

<g class="halo"><circle cx="$cx" cy="$cy" r="155" fill="url(#au1)"/></g>
<circle class="ring2" cx="$cx" cy="$cy" r="128" fill="none" stroke="$($t.line2)" stroke-width="1.2" stroke-dasharray="2 7"/>
<g class="ring"><circle cx="$cx" cy="$cy" r="111" fill="none" stroke="url(#gD)" stroke-width="3" stroke-linecap="round" stroke-dasharray="150 40 70 40 120 277.4"/></g>
<g class="orb"><circle cx="$cx" cy="$($cy - 111)" r="10" fill="$($t.gold)" opacity=".18"/><circle cx="$cx" cy="$($cy - 111)" r="4.5" fill="$($t.gold)"/></g>
<circle cx="$cx" cy="$cy" r="99" fill="url(#disc)" stroke="$($t.line2)"/>
$portrait
<g class="up" style="animation-delay:.5s">$locSvg</g>

<g class="up" style="animation-delay:.05s">
<circle cx="346" cy="81" r="4" fill="$($t.gold)"/>
<circle class="ping" cx="346" cy="81" r="4" fill="none" stroke="$($t.gold)" stroke-width="1.5" opacity="0"/>
<text x="362" y="86" class="m t2" font-size="13" font-weight="500" letter-spacing="2.6">CURRENTLY AT $(X $P.Company.ToUpper())</text>
</g>
<g class="up" style="animation-delay:.18s"><text x="337" y="150" class="d t1" font-size="54" font-weight="700" letter-spacing="-1.2">$(X $P.Name)</text></g>
<g class="up" style="animation-delay:.32s"><text x="340" y="192" class="d" font-size="22" font-weight="600" fill="url(#gA)">$(X $P.Headline)</text></g>
<g class="up" style="animation-delay:.46s">$pills</g>
<g class="up" style="animation-delay:.6s">
<text x="340" y="281" class="m gd" font-size="19" font-weight="600">&gt;</text>
$phrases
<g class="blink"><rect x="$caretBase" y="263" width="2.4" height="21" rx="1" fill="$($t.g1)"><animate attributeName="x" dur="$($period)s" repeatCount="indefinite" calcMode="discrete" keyTimes="$ckt" values="$cvs"/></rect></g>
</g>
<g class="up" style="animation-delay:.74s">
<rect x="340" y="349" width="560" height="2" rx="1" fill="$($t.line2)"/>
<rect x="340" y="349" width="560" height="2" rx="1" fill="url(#gA)" opacity=".45"/>
<g class="st"><rect x="300" y="348" width="80" height="4" rx="2" fill="url(#streak)"/></g>
$flowNodes
</g>
</g>
<rect x=".5" y=".5" width="$($W - 1)" height="$($H - 1)" rx="27.5" fill="none" stroke="$($t.line)"/>
"@

    $desc = "Animated banner. A portrait framed by a rotating gradient ring, the name $($P.Name), the headline $($P.Headline), tags $($P.Focus -join ', '), a typed line cycling through: $($phr -join '; '). An animated line connects Ideas, Technology and Impact."
    New-SvgDoc -W $W -H $H -Title "$($P.Name) $script:EM $($P.Headline)" -Desc $desc -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora', 'Mono')
}

# ======================================================== SECTION HEADER ==
function Build-Header($t, [string]$key) {
    $s = $P.Sections[$key]; $W = 900; $H = 112
    $css = ".sw{animation:sweep 7s cubic-bezier(.45,0,.25,1) infinite}@keyframes sweep{0%{transform:translateX(0);opacity:0}10%{opacity:1}90%{opacity:1}100%{transform:translateX(780px);opacity:0}}"
    $defs = "<clipPath id='hc'><rect x='76' y='94' width='824' height='6'/></clipPath>"
    $body = @"
<g class="up"><text x="1" y="30" class="m" font-size="12.5" font-weight="600" letter-spacing="3"><tspan fill="$($t.g2)">$($s.Num)</tspan><tspan class="t3" font-weight="500" dx="10">/</tspan><tspan class="t3" font-weight="500" dx="10">$(X $s.Label)</tspan></text></g>
<g class="up" style="animation-delay:.12s"><text x="0" y="76" class="d t1" font-size="30" font-weight="700" letter-spacing="-.4">$(X $s.Title)</text></g>
<rect x="0" y="96" width="64" height="3" rx="1.5" fill="url(#gA)"/>
<rect x="76" y="97" width="824" height="1" fill="$($t.line2)"/>
<g clip-path="url(#hc)"><g class="sw"><rect x="-44" y="96.5" width="120" height="2" rx="1" fill="url(#streak)"/></g></g>
"@
    New-SvgDoc -W $W -H $H -Title "$($s.Label): $($s.Title)" -Desc "Section heading $($s.Num), $($s.Label): $($s.Title)" -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora')
}

# ============================================================= CODE CARD ==
function Build-CodeCard($t) {
    $W = 460; $H = 322; $c = $P.CodeCard
    $kw = $t.g3; $str = $t.g1; $num = $t.gold; $key = $t.text2; $pun = $t.text3; $id = $t.text
    function Tk([string]$s, [string]$col, [string]$extra = '') { "<tspan fill='$col'$extra>$(X $s)</tspan>" }
    $q = '"'
    $doms = (($c.Domains | ForEach-Object { $q + $_ + $q }) -join ', ')
    $lines = @(
        (Tk '// who I am, in one object' $pun " font-style='italic'"),
        ((Tk 'const ' $kw) + (Tk 'mehedi' $id) + (Tk ' = {' $pun)),
        ((Tk '  role:     ' $key) + (Tk ($q + $c.Role + $q) $str) + (Tk ',' $pun)),
        ((Tk '  base:     ' $key) + (Tk ($q + $P.Location + $q) $str) + (Tk ',' $pun)),
        ((Tk '  company:  ' $key) + (Tk ($q + $P.Company + $q) $str) + (Tk ',' $pun)),
        ((Tk '  since:    ' $key) + (Tk ([string]$P.Since) $num) + (Tk ',' $pun)),
        ((Tk '  domains:  ' $key) + (Tk '[' $pun) + (Tk $doms $str) + (Tk '],' $pun)),
        ((Tk '  approach: ' $key) + (Tk ($q + $c.Approach + $q) $str) + (Tk ',' $pun)),
        (Tk '};' $pun)
    )
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $y = 84 + $i * 26
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.15 + $i * 0.09))s'><text x='34' y='$y' text-anchor='end' class='m t3' font-size='11.5' opacity='.6'>$($i + 1)</text><text x='50' y='$y' class='m' font-size='13.5' xml:space='preserve'>$($lines[$i])</text></g>")
    }
    $lastY = 84 + ($lines.Count - 1) * 26
    $body = @"
$(New-Panel 0.5 0.5 459 321 $t 18)
<circle cx="24" cy="24" r="5" fill="#FF5F57"/><circle cx="42" cy="24" r="5" fill="#FEBC2E"/><circle cx="60" cy="24" r="5" fill="#28C840"/>
<text x="230" y="28" text-anchor="middle" class="m t3" font-size="11.5" letter-spacing=".5">mehedi.ts</text>
<rect x="0.5" y="46" width="459" height="1" fill="$($t.line)"/>
$($sb.ToString())
<g class="blink"><rect x="$(Rnd (50 + 2 * 8.1 + 6))" y="$($lastY - 13)" width="8" height="17" rx="1.5" fill="$($t.g1)" opacity=".85"/></g>
"@
    New-SvgDoc -W $W -H $H -Title 'About me as a code object' -Desc "A code editor card describing $($P.Name): role $($c.Role), based in $($P.Location), company $($P.Company), working since $($P.Since), domains $($c.Domains -join ', '), approach $($c.Approach)." -Theme $t -Body $body
}

# ============================================================== CLIENTS ==
function Build-Spectrum($t) {
    $W = 900; $H = 186; $C = @($P.Clients); $n = $C.Count
    $x0 = 90; $x1 = 810; $ly = 92; $step = ($x1 - $x0) / ($n - 1)
    $css = ".sp{animation:spr 6s cubic-bezier(.45,0,.3,1) infinite}@keyframes spr{0%{transform:translateX(0);opacity:0}10%{opacity:1}90%{opacity:1}100%{transform:translateX($($x1 - $x0)px);opacity:0}}"
    $defs = "<linearGradient id='gS' gradientUnits='userSpaceOnUse' x1='$x0' y1='0' x2='$x1' y2='0'><stop offset='0' stop-color='$($t.g1)'/><stop offset='.55' stop-color='$($t.g2)'/><stop offset='1' stop-color='$($t.g3)'/></linearGradient>"
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $n - 1; $i++) {
        $sx = $x0 + $i * $step + 15
        [void]$sb.Append("<rect x='$(Rnd $sx)' y='$($ly - 1)' width='$(Rnd ($step - 30))' height='2' rx='1' fill='url(#gS)' opacity='.6'/>")
    }
    [void]$sb.Append("<g class='sp'><rect x='$($x0 - 40)' y='$($ly - 2)' width='80' height='4' rx='2' fill='url(#streak)'/></g>")
    for ($i = 0; $i -lt $n; $i++) {
        $x = Rnd ($x0 + $i * $step)
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.1 + $i * 0.1))s'>")
        [void]$sb.Append("<circle cx='$x' cy='$ly' r='10' fill='none' stroke='url(#gS)' stroke-width='2'/><circle cx='$x' cy='$ly' r='3.6' fill='url(#gS)'/>")
        [void]$sb.Append("<circle class='ping' cx='$x' cy='$ly' r='10' fill='none' stroke='url(#gS)' stroke-width='1.2' opacity='0' style='animation-delay:$(Rnd ($i * 0.45))s'/>")
        [void]$sb.Append("<text x='$x' y='134' text-anchor='middle' class='d t1' font-size='15' font-weight='600'>$(X $C[$i].Label)</text>")
        [void]$sb.Append("<text x='$x' y='155' text-anchor='middle' class='s t3' font-size='12.5'>$(X $C[$i].Sub)</text></g>")
    }
    $body = @"
<text x="0" y="26" class="m t3" font-size="12" font-weight="500" letter-spacing="3">WHO I&apos;VE WORKED WITH</text>
<text x="900" y="26" text-anchor="end" class="m t3" font-size="11" letter-spacing="2">FROM SOLO FOUNDERS TO BANKS</text>
$($sb.ToString())
"@
    $list = ($C | ForEach-Object { $_.Label + ' (' + $_.Sub + ')' }) -join ', '
    New-SvgDoc -W $W -H $H -Title "Who I've worked with" -Desc "A scale from individual founders to financial institutions: $list." -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora')
}

# ============================================================= TIMELINE ==
function Build-Timeline($t) {
    $J = @($P.Journey); $W = 900; $top = 44; $rowH = 108; $H = $top + $J.Count * $rowH + 12
    $lineX = 232; $cX = 268
    $y1 = $top + 26; $y2 = $top + ($J.Count - 1) * $rowH + 26
    $css = ".grow{transform-box:fill-box;transform-origin:top;animation:grow 2.4s .2s cubic-bezier(.3,.6,.2,1) both}@keyframes grow{from{transform:scaleY(0)}to{transform:none}}"
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((New-Panel 0.5 0.5 899 ($H - 1) $t 24))
    [void]$sb.Append("<rect x='$($lineX - 1)' y='$y1' width='2' height='$($y2 - $y1)' rx='1' fill='$($t.line2)'/>")
    [void]$sb.Append("<g class='grow'><rect x='$($lineX - 1)' y='$y1' width='2' height='$($y2 - $y1)' rx='1' fill='url(#gV)'/></g>")
    for ($i = 0; $i -lt $J.Count; $i++) {
        $e = $J[$i]; $y = $top + $i * $rowH; $cur = [bool]$e.Current
        $nc = $t.g2; $yc = $t.text2; if ($cur) { $nc = $t.gold; $yc = $t.gold }
        $d = Rnd (0.3 + $i * 0.38)
        [void]$sb.Append("<g class='up' style='animation-delay:$($d)s'>")
        [void]$sb.Append("<text x='196' y='$($y + 31)' text-anchor='end' class='m' font-size='14' font-weight='600' letter-spacing='.5' fill='$yc'>$(X $e.Years)</text>")
        [void]$sb.Append("<text x='196' y='$($y + 52)' text-anchor='end' class='m t3' font-size='10.5' font-weight='500' letter-spacing='2'>STAGE 0$($i + 1)</text>")
        [void]$sb.Append("<circle cx='$lineX' cy='$($y + 26)' r='11' fill='$($t.panel)' stroke='$nc' stroke-opacity='.4'/><circle cx='$lineX' cy='$($y + 26)' r='5.5' fill='$nc'/>")
        if ($cur) { [void]$sb.Append("<circle class='ping' cx='$lineX' cy='$($y + 26)' r='5.5' fill='none' stroke='$nc' stroke-width='1.5' opacity='0'/>") }
        [void]$sb.Append("<text x='$cX' y='$($y + 32)' class='d t1' font-size='20' font-weight='600'>$(X $e.Title)</text>")
        [void]$sb.Append("<text x='$cX' y='$($y + 56)' class='s t2' font-size='14.5'>$(X $e.Text)</text>")
        $tx = $cX
        foreach ($tag in $e.Tags) {
            $tone = 'default'; if ($cur -and $tag -eq 'NOW') { $tone = 'gold' } elseif ($cur) { $tone = 'accent' }
            $chip = New-Chip -X $tx -Y ($y + 68) -Text $tag -Theme $t -Size 10.5 -H 24 -Pad 11 -Tone $tone -Ls 1.2
            [void]$sb.Append($chip.Svg); $tx += $chip.Width + 8
        }
        [void]$sb.Append('</g>')
    }
    $desc = ($J | ForEach-Object { $_.Years + ': ' + $_.Title + '. ' + $_.Text + '.' }) -join ' '
    New-SvgDoc -W $W -H $H -Title 'Career journey, 2018 to now' -Desc $desc -Theme $t -Css $css -Body $sb.ToString() -Fonts @('Sora')
}

# ======================================================= PRACTICE AREAS ==
function Build-Practice($t) {
    $areas = @($P.Practice); $W = 900; $tw = 288; $th = 184; $gap = 18
    $rows = [math]::Ceiling($areas.Count / 3); $H = $rows * $th + ($rows - 1) * $gap
    $css = ".tg{animation:glow 12s ease-in-out infinite}"
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $areas.Count; $i++) {
        $ar = $areas[$i]; $x = ($i % 3) * ($tw + $gap) + 0.5; $y = [math]::Floor($i / 3) * ($th + $gap) + 0.5
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.1 + $i * 0.08))s'>")
        [void]$sb.Append((New-Panel $x $y ($tw - 1) ($th - 1) $t 20 -NoHairline))
        [void]$sb.Append("<rect class='tg' x='$x' y='$y' width='$($tw - 1)' height='$($th - 1)' rx='20' fill='none' stroke='url(#gD)' stroke-width='1.5' opacity='0' style='animation-delay:$($i * 2)s'/>")
        [void]$sb.Append("<rect x='$($x + 22)' y='$($y + 22)' width='30' height='30' rx='9' fill='$($t.chipBg)' stroke='$($t.chipLine)'/>")
        [void]$sb.Append("<text x='$($x + 37)' y='$($y + 41.5)' text-anchor='middle' class='m ac' font-size='13' font-weight='600'>$(X $ar.Key)</text>")
        [void]$sb.Append((New-Icon $ar.Icon ($x + $tw - 52) ($y + 23) $t.g2))
        [void]$sb.Append("<text x='$($x + 22)' y='$($y + 90)' class='d t1' font-size='18' font-weight='600'>$(X $ar.Title)</text>")
        $ly = $y + 115
        foreach ($l in $ar.Lines) { [void]$sb.Append("<text x='$($x + 22)' y='$ly' class='s t2' font-size='13.5'>$(X $l)</text>"); $ly += 19 }
        [void]$sb.Append("<text x='$($x + 22)' y='$($y + 164)' class='m' font-size='10.5' font-weight='500' letter-spacing='1.2' fill='$($t.g2)'>$(X $ar.Note)</text>")
        [void]$sb.Append('</g>')
    }
    $desc = ($areas | ForEach-Object { $_.Key + '. ' + $_.Title + ': ' + ($_.Lines -join ' ') + '.' }) -join ' '
    New-SvgDoc -W $W -H $H -Title 'Six practice areas' -Desc $desc -Theme $t -Css $css -Body $sb.ToString() -Fonts @('Sora')
}

# ============================================================ PROJECTS ==
function Add-CardTags($sb, $pr, $t, [double]$x, [double]$y) {
    foreach ($tag in $pr.Tags) {
        $c = New-Chip -X $x -Y $y -Text $tag -Theme $t -Size 10.5 -H 24 -Pad 11 -Tone 'accent' -Ls 1.2
        [void]$sb.Append($c.Svg); $x += $c.Width + 8
    }
    $c = New-Chip -X $x -Y $y -Text $pr.Role -Theme $t -Size 10.5 -H 24 -Pad 11 -Tone 'gold' -Ls 1.2
    [void]$sb.Append($c.Svg)
}

function Build-Featured($t, $pr) {
    $W = 900; $H = 330
    $flow = @($pr.Flow)
    $css = ".bx{animation:glow 6s linear infinite}.fl{stroke-dasharray:18 394;animation:fl 6s linear infinite}@keyframes fl{from{stroke-dashoffset:412}to{stroke-dashoffset:0}}"
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((New-Panel 0.5 0.5 899 329 $t 24))
    [void]$sb.Append("<g class='up'>"); Add-CardTags $sb $pr $t 36 32; [void]$sb.Append('</g>')
    [void]$sb.Append("<g class='up' style='animation-delay:.1s'><text x='36' y='104' class='d t1' font-size='30' font-weight='700' letter-spacing='-.3'>$(X $pr.Title)</text>")
    $ly = 136; foreach ($l in $pr.Lines) { [void]$sb.Append("<text x='36' y='$ly' class='s t2' font-size='15'>$(X $l)</text>"); $ly += 22 }
    [void]$sb.Append('</g>')
    $fx = @(36, 216, 410); $i = 0
    foreach ($f in $pr.Facts) {
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.2 + $i * 0.08))s'><rect x='$($fx[$i])' y='190' width='3' height='38' rx='1.5' fill='url(#gV)'/>")
        [void]$sb.Append("<text x='$($fx[$i] + 14)' y='205' class='d t1' font-size='15' font-weight='600'>$(X $f.Big)</text>")
        [void]$sb.Append("<text x='$($fx[$i] + 14)' y='225' class='s t3' font-size='12.5'>$(X $f.Small)</text></g>")
        $i++
    }
    $st = New-ChipFlow -X 36 -Y 258 -MaxW 560 -Items $pr.Stack -Theme $t -Size 11.5 -H 28 -Gap 8 -Pad 12 -Ls 0.2 -Delay 0.35
    [void]$sb.Append($st.Svg)

    # lifecycle diagram: two columns, U-shaped path, a dot travelling along it
    [void]$sb.Append("<rect x='604' y='28' width='268' height='274' rx='18' fill='$($t.panel2)' stroke='$($t.line)'/>")
    [void]$sb.Append("<text x='622' y='56' class='m t3' font-size='10.5' font-weight='500' letter-spacing='2'>LENDING LIFECYCLE</text>")
    [void]$sb.Append("<path d='M677 91 V235 H801 V91' fill='none' stroke='$($t.line2)' stroke-width='1.5'/>")
    [void]$sb.Append("<path class='fl' d='M677 91 V235 H801 V91' fill='none' stroke='$($t.g2)' stroke-width='2' stroke-linecap='round'/>")
    $pos = @(@(622, 74, 0), @(622, 146, 72), @(622, 218, 144), @(746, 218, 268), @(746, 146, 340), @(746, 74, 412))
    for ($k = 0; $k -lt [math]::Min($flow.Count, 6); $k++) {
        $bx = $pos[$k][0]; $by = $pos[$k][1]; $delay = Rnd (($pos[$k][2] / 412.0) * 6 - 0.48)
        [void]$sb.Append("<rect x='$bx' y='$by' width='110' height='34' rx='10' fill='$($t.panel)' stroke='$($t.line2)'/>")
        [void]$sb.Append("<rect class='bx' x='$bx' y='$by' width='110' height='34' rx='10' fill='none' stroke='$($t.g2)' stroke-width='1.5' opacity='0' style='animation-delay:$($delay)s'/>")
        [void]$sb.Append("<text x='$($bx + 55)' y='$($by + 21.5)' text-anchor='middle' class='m t2' font-size='10.5' font-weight='500' letter-spacing='1.2'>$(X $flow[$k])</text>")
    }
    [void]$sb.Append("<circle cx='677' cy='91' r='9' fill='$($t.gold)' opacity='.2'><animateMotion dur='6s' repeatCount='indefinite' path='M0 0 V144 H124 V0'/></circle>")
    [void]$sb.Append("<circle cx='677' cy='91' r='4.2' fill='$($t.gold)'><animateMotion dur='6s' repeatCount='indefinite' path='M0 0 V144 H124 V0'/></circle>")
    [void]$sb.Append("<text x='738' y='282' text-anchor='middle' class='m t3' font-size='10' letter-spacing='1.6'>CONFIGURED, NOT HARD-CODED</text>")
    [void]$sb.Append("<g class='up' style='animation-delay:.4s'>$(New-Icon 'arrow' 838 30 $t.text3 0.8)</g>")

    $desc = "$($pr.Title). $($pr.Lines -join ' ') Highlights: " + (($pr.Facts | ForEach-Object { $_.Big + ' (' + $_.Small + ')' }) -join ', ') + ". Stack: $($pr.Stack -join ', '). Role: $($pr.Role)."
    New-SvgDoc -W $W -H $H -Title "Featured project: $($pr.Title)" -Desc $desc -Theme $t -Css $css -Body $sb.ToString() -Fonts @('Sora')
}

function Build-Half($t, $pr) {
    $W = 440; $H = 300
    $css = ".ar{animation:nudge 3.2s ease-in-out infinite}@keyframes nudge{0%,100%{transform:none}50%{transform:translate(2px,-2px)}}"
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append((New-Panel 0.5 0.5 439 299 $t 22))
    [void]$sb.Append("<g class='up'>"); Add-CardTags $sb $pr $t 28 28; [void]$sb.Append('</g>')
    [void]$sb.Append("<g class='ar'>$(New-Icon 'arrow' 390 24 $t.text3 0.8)</g>")
    [void]$sb.Append("<g class='up' style='animation-delay:.1s'><text x='28' y='96' class='d t1' font-size='23' font-weight='700' letter-spacing='-.2'>$(X $pr.Title)</text>")
    $ly = 126; foreach ($l in $pr.Lines) { [void]$sb.Append("<text x='28' y='$ly' class='s t2' font-size='13.8'>$(X $l)</text>"); $ly += 21 }
    [void]$sb.Append('</g>')
    $fx = @(28, 226); $i = 0
    foreach ($f in $pr.Facts) {
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.2 + $i * 0.08))s'><rect x='$($fx[$i])' y='196' width='3' height='34' rx='1.5' fill='url(#gV)'/>")
        [void]$sb.Append("<text x='$($fx[$i] + 13)' y='210' class='d t1' font-size='14' font-weight='600'>$(X $f.Big)</text>")
        [void]$sb.Append("<text x='$($fx[$i] + 13)' y='228' class='s t3' font-size='12'>$(X $f.Small)</text></g>")
        $i++
    }
    $st = New-ChipFlow -X 28 -Y 248 -MaxW 384 -Items $pr.Stack -Theme $t -Size 11 -H 26 -Gap 7 -Pad 11 -Ls 0.1 -Delay 0.3
    [void]$sb.Append($st.Svg)
    $desc = "$($pr.Title). $($pr.Lines -join ' ') Highlights: " + (($pr.Facts | ForEach-Object { $_.Big + ' (' + $_.Small + ')' }) -join ', ') + ". Stack: $($pr.Stack -join ', '). Role: $($pr.Role)."
    New-SvgDoc -W $W -H $H -Title "Project: $($pr.Title)" -Desc $desc -Theme $t -Css $css -Body $sb.ToString() -Fonts @('Sora')
}

function Build-More($t) {
    $W = 440; $H = 300; $cx = 220; $cy = 112
    $css = ".rr{transform-origin:$($cx)px $($cy)px;animation:spin 22s linear infinite}.ar{animation:nudge 3.2s ease-in-out infinite}@keyframes nudge{0%,100%{transform:none}50%{transform:translate(2px,-2px)}}.a{transform-box:fill-box;transform-origin:center;animation:dr 18s ease-in-out infinite alternate}@keyframes dr{to{transform:translate(-80px,40px) scale(1.15)}}"
    $body = @"
$(New-Panel 0.5 0.5 439 299 $t 22)
<g clip-path="url(#mc)"><g class="a"><circle cx="360" cy="40" r="200" fill="url(#au2)" opacity=".6"/></g></g>
<circle class="rr" cx="$cx" cy="$cy" r="44" fill="none" stroke="url(#gD)" stroke-width="1.5" stroke-dasharray="4 7"/>
<circle cx="$cx" cy="$cy" r="32" fill="$($t.chipBg)" stroke="$($t.chipLine)"/>
<g class="ar">$(New-Icon 'arrow' ($cx - 14) ($cy - 14) $t.g2 1 2)</g>
<text x="$cx" y="200" text-anchor="middle" class="d t1" font-size="22" font-weight="700">Explore all repositories</text>
<text x="$cx" y="228" text-anchor="middle" class="s t2" font-size="14">Experiments, tools and work in progress</text>
<text x="$cx" y="262" text-anchor="middle" class="m" font-size="11" font-weight="500" letter-spacing="2" fill="$($t.g2)">GITHUB.COM/$(X $P.GitHub.ToUpper())</text>
"@
    $defs = "<clipPath id='mc'><rect x='.5' y='.5' width='439' height='299' rx='22'/></clipPath>"
    New-SvgDoc -W $W -H $H -Title 'Explore all repositories' -Desc "Link card to all public repositories of $($P.GitHub) on GitHub." -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora')
}

# ========================================================= CAPABILITIES ==
function Build-Capabilities($t) {
    $caps = @($P.Capabilities); $W = 900; $cw = 441; $gap = 18; $inner = $cw - 48
    # measure each panel's chip block to size rows
    $heights = @()
    foreach ($cap in $caps) {
        $m = New-ChipFlow -X 0 -Y 0 -MaxW $inner -Items $cap.Items -Theme $t -Size 12 -H 30 -Gap 8 -RowGap 9 -Pad 12 -Ls 0
        $heights += (92 + $m.Bottom + 24)
    }
    $rowH = @(); for ($r = 0; $r -lt [math]::Ceiling($caps.Count / 2); $r++) { $rowH += [math]::Max($heights[2 * $r], $heights[[math]::Min(2 * $r + 1, $caps.Count - 1)]) }
    $sb = New-Object System.Text.StringBuilder; $y = 0.5
    for ($r = 0; $r -lt $rowH.Count; $r++) {
        for ($k = 0; $k -lt 2; $k++) {
            $i = 2 * $r + $k; if ($i -ge $caps.Count) { break }
            $cap = $caps[$i]; $x = $k * ($cw + $gap) + 0.5
            [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.1 + $i * 0.1))s'>")
            [void]$sb.Append((New-Panel $x $y ($cw - 1) ($rowH[$r] - 1) $t 20))
            [void]$sb.Append("<rect x='$($x + 24)' y='$($y + 24)' width='40' height='40' rx='12' fill='$($t.chipBg)' stroke='$($t.chipLine)'/>")
            [void]$sb.Append((New-Icon $cap.Icon ($x + 30) ($y + 30) $t.g2 1))
            [void]$sb.Append("<text x='$($x + 78)' y='$($y + 44)' class='d t1' font-size='19' font-weight='600'>$(X $cap.Title)</text>")
            [void]$sb.Append("<text x='$($x + 78)' y='$($y + 63)' class='s t3' font-size='13'>$(X $cap.Sub)</text>")
            $f = New-ChipFlow -X ($x + 24) -Y ($y + 88) -MaxW $inner -Items $cap.Items -Theme $t -Size 12 -H 30 -Gap 8 -RowGap 9 -Pad 12 -Ls 0 -Delay (0.25 + $i * 0.1) -Step 0.04
            [void]$sb.Append($f.Svg)
            [void]$sb.Append('</g>')
        }
        $y += $rowH[$r] + $gap
    }
    # stack strip
    $strip = New-ChipFlow -X 24 -Y ($y + 44) -MaxW 852 -Items $P.Stack -Theme $t -Size 12 -H 30 -Gap 8 -Pad 12 -Ls 0 -Tone 'accent'
    $sh = $strip.Bottom - $y + 22
    [void]$sb.Append("<g class='up' style='animation-delay:.6s'>$(New-Panel 0.5 $y 899 $sh $t 20 -NoHairline)")
    [void]$sb.Append("<text x='24' y='$($y + 30)' class='m t3' font-size='10.5' font-weight='500' letter-spacing='2'>$(X $P.StackLabel)</text>")
    [void]$sb.Append($strip.Svg + '</g>')
    $H = [math]::Ceiling($y + $sh + 1)
    $desc = (($caps | ForEach-Object { $_.Title + ': ' + ($_.Items -join ', ') + '.' }) -join ' ') + ' Stacks across recent projects: ' + ($P.Stack -join ', ') + '.'
    New-SvgDoc -W $W -H $H -Title 'Capabilities' -Desc $desc -Theme $t -Body $sb.ToString() -Fonts @('Sora')
}

# ============================================================ PHILOSOPHY ==
function Build-Philosophy($t) {
    $Ph = $P.Philosophy; $L = @($Ph.Lines); $W = 900
    $lastY = 84 + ($L.Count - 1) * 36
    $chips = New-ChipFlow -X 112 -Y ($lastY + 64) -MaxW 752 -Items $Ph.Interests -Theme $t -Size 12 -H 30 -Gap 8 -Pad 13 -Ls 0 -Tone 'accent' -Delay 0.6
    $H = [math]::Ceiling($chips.Bottom + 36)
    $css = ".a{transform-box:fill-box;transform-origin:center;animation:dr 24s ease-in-out infinite alternate}@keyframes dr{to{transform:translate(-120px,40px) scale(1.2)}}"
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $L.Count; $i++) {
        $fill = "class='d t1'"; if ($i -eq $L.Count - 1) { $fill = "class='d' fill='url(#gA)'" }
        [void]$sb.Append("<g class='up' style='animation-delay:$(Rnd (0.1 + $i * 0.12))s'><text x='112' y='$(84 + $i * 36)' $fill font-size='23' font-weight='600' letter-spacing='-.2'>$(X $L[$i])</text></g>")
    }
    $body = @"
$(New-Panel 0.5 0.5 899 ($H - 1) $t 24)
<g clip-path="url(#pf)"><g class="a"><circle cx="820" cy="40" r="260" fill="url(#au2)" opacity=".7"/></g></g>
<text x="36" y="126" class="d" font-size="120" font-weight="700" fill="url(#gD)">&#8220;</text>
$($sb.ToString())
<g class="up" style="animation-delay:.55s"><rect x="112" y="$($lastY + 26)" width="28" height="2" rx="1" fill="url(#gA)"/><text x="150" y="$($lastY + 31)" class="m t3" font-size="11.5" font-weight="500" letter-spacing="2.5">$(X $P.Name.ToUpper())</text></g>
$($chips.Svg)
"@
    $defs = "<clipPath id='pf'><rect x='.5' y='.5' width='899' height='$($H - 1)' rx='24'/></clipPath>"
    New-SvgDoc -W $W -H $H -Title 'Personal philosophy' -Desc ("Quote: " + ($L -join ' ') + " Interests: " + ($Ph.Interests -join ', ') + '.') -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora')
}

# =============================================================== CONNECT ==
function Build-Connect($t) {
    $Cn = $P.Connect; $W = 900; $H = 300
    $css = @"
.a{transform-box:fill-box;transform-origin:center;animation:dr 20s ease-in-out infinite alternate}
.b{transform-box:fill-box;transform-origin:center;animation:dr2 26s ease-in-out infinite alternate}
@keyframes dr{to{transform:translate(120px,30px) scale(1.15)}}
@keyframes dr2{to{transform:translate(-110px,-30px) scale(1.2)}}
.st{animation:tr 5s cubic-bezier(.5,0,.3,1) infinite}
@keyframes tr{0%{transform:translateX(0);opacity:0}12%{opacity:1}88%{opacity:1}100%{transform:translateX(300px);opacity:0}}
"@
    $defs = @"
<clipPath id="cc"><rect x=".5" y=".5" width="899" height="299" rx="24"/></clipPath>
<radialGradient id="fade" cx=".5" cy=".5" r=".6"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>
<mask id="dm"><rect width="$W" height="$H" fill="url(#fade)"/></mask>
"@
    $nodes = ''
    foreach ($nd in @(@(300, 'IDEAS', $t.g2), @(450, 'TECHNOLOGY', $t.g2), @(600, 'IMPACT', $t.gold))) {
        $nodes += "<circle cx='$($nd[0])' cy='236' r='5' fill='$($t.panel)' stroke='$($nd[2])' stroke-width='2'/><text x='$($nd[0])' y='262' text-anchor='middle' class='m t3' font-size='10.5' font-weight='500' letter-spacing='2.5'>$($nd[1])</text>"
    }
    $body = @"
$(New-Panel 0.5 0.5 899 299 $t 24)
<g clip-path="url(#cc)">
<rect width="$W" height="$H" fill="url(#dots)" mask="url(#dm)"/>
<g class="a"><circle cx="120" cy="280" r="260" fill="url(#au1)"/></g>
<g class="b"><circle cx="800" cy="20" r="260" fill="url(#au2)"/></g>
</g>
<g class="up"><text x="450" y="64" text-anchor="middle" class="m ac" font-size="12" font-weight="600" letter-spacing="3.5">$(X $Cn.Eyebrow)</text></g>
<g class="up" style="animation-delay:.12s"><text x="450" y="118" text-anchor="middle" class="d t1" font-size="36" font-weight="700" letter-spacing="-.6">$(X $Cn.Title)</text></g>
<g class="up" style="animation-delay:.24s"><text x="450" y="156" text-anchor="middle" class="s t2" font-size="15.5">$(X $Cn.Lines[0])</text><text x="450" y="180" text-anchor="middle" class="s t2" font-size="15.5">$(X $Cn.Lines[1])</text></g>
<g class="up" style="animation-delay:.36s">
<rect x="300" y="235" width="300" height="2" rx="1" fill="$($t.line2)"/>
<rect x="300" y="235" width="300" height="2" rx="1" fill="url(#gA)" opacity=".5"/>
<g class="st"><rect x="270" y="234" width="60" height="4" rx="2" fill="url(#streak)"/></g>
$nodes
</g>
"@
    New-SvgDoc -W $W -H $H -Title $Cn.Title -Desc ($Cn.Title + ' ' + ($Cn.Lines -join ' ')) -Theme $t -Css $css -Defs $defs -Body $body -Fonts @('Sora')
}

# =============================================================== BUTTONS ==
function Build-Button($t, [string]$label) {
    $W = 240; $H = 56
    $shc = '#FFFFFF'; $sho = '.16'; if ($t.name -eq 'light') { $shc = $t.g2; $sho = '.16' }
    $css = ".sh{animation:shine 6s ease-in-out infinite}@keyframes shine{0%{transform:translateX(0)}35%,100%{transform:translateX(360px)}}"
    $defs = @"
<clipPath id="bc"><rect x="1" y="1" width="238" height="54" rx="27"/></clipPath>
<linearGradient id="shg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="$shc" stop-opacity="0"/><stop offset=".5" stop-color="$shc" stop-opacity="$sho"/><stop offset="1" stop-color="$shc" stop-opacity="0"/></linearGradient>
"@
    $body = @"
<rect x="1" y="1" width="238" height="54" rx="27" fill="$($t.panel)"/>
<rect x="1" y="1" width="238" height="54" rx="27" fill="url(#gA)" opacity=".07"/>
<g clip-path="url(#bc)"><g class="sh"><rect x="-90" y="0" width="70" height="56" fill="url(#shg)" transform="skewX(-20)"/></g></g>
<rect x="1" y="1" width="238" height="54" rx="27" fill="none" stroke="url(#gA)" stroke-width="1.5"/>
<text x="108" y="33.5" text-anchor="middle" class="s t1" font-size="15" font-weight="600">$(X $label)</text>
$(New-Icon 'arrow' 186 17 $t.g2 0.78 2.2)
"@
    New-SvgDoc -W $W -H $H -Title $label -Desc "Button: $label" -Theme $t -Css $css -Defs $defs -Body $body
}

# ================================================================ FOOTER ==
function Build-Footer($t) {
    $W = 900; $H = 150
    function Wave([double]$y0, [double]$amp) {
        $d = "M0 $y0"
        for ($k = 0; $k -lt 8; $k++) {
            $sign = 1; if ($k % 2 -eq 1) { $sign = -1 }
            $d += " Q$($k * 225 + 112.5) $(Rnd ($y0 - $sign * $amp)) $(($k + 1) * 225) $y0"
        }
        $d + " L1800 $H L0 $H Z"
    }
    $css = ".w1{animation:wv 16s linear infinite}.w2{animation:wv 23s linear infinite reverse}@keyframes wv{from{transform:translateX(0)}to{transform:translateX(-900px)}}"
    $statement = 'TURNING IDEAS INTO TECHNOLOGY ' + $script:MID + ' TRANSFORMING TECHNOLOGY INTO IMPACT'
    $defs = @"
<linearGradient id="fv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<linearGradient id="fh" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".18" stop-color="#fff"/><stop offset=".82" stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<mask id="mv" maskUnits="userSpaceOnUse" x="0" y="0" width="$W" height="$H"><rect x="0" y="86" width="$W" height="$($H - 86)" fill="url(#fv)"/></mask>
<mask id="mh" maskUnits="userSpaceOnUse" x="0" y="0" width="$W" height="$H"><rect width="$W" height="$H" fill="url(#fh)"/></mask>
"@
    $body = @"
<g mask="url(#mh)"><g mask="url(#mv)">
<g class="w1"><path d="$(Wave 104 12)" fill="url(#gA)" opacity=".30"/></g>
<g class="w2"><path d="$(Wave 116 9)" fill="url(#gA)" opacity=".22"/></g>
</g></g>
<text x="450" y="42" text-anchor="middle" class="m t3" font-size="11.5" font-weight="500" letter-spacing="2.4">$(X $statement)</text>
<text x="450" y="68" text-anchor="middle" class="m t3" font-size="10.5" letter-spacing="2" opacity=".75">$(X ($P.Name.ToUpper() + ' ' + $script:MID + ' ' + $P.Location.ToUpper()))</text>
"@
    New-SvgDoc -W $W -H $H -Title 'Footer' -Desc "Closing statement: Turning ideas into technology. Transforming technology into impact." -Theme $t -Css $css -Defs $defs -Body $body
}

# ========================================================= SNAKE STUB ==
function Build-SnakePlaceholder($t) {
    $body = @"
<rect x=".5" y=".5" width="879" height="159" rx="18" fill="$($t.panel)" stroke="$($t.line)" stroke-dasharray="4 6"/>
<text x="440" y="76" text-anchor="middle" class="m t3" font-size="12" letter-spacing="2">CONTRIBUTION ANIMATION</text>
<text x="440" y="100" text-anchor="middle" class="s t3" font-size="13">Appears after the first run of the Profile assets workflow</text>
"@
    New-SvgDoc -W 880 -H 160 -Title 'Contribution animation placeholder' -Desc 'Placeholder until the GitHub Actions workflow generates the contribution animation.' -Theme $t -Body $body
}

# ================================================================== RUN ==
Write-Host 'Building assets from profile.psd1'
foreach ($t in $script:Themes.Values) {
    $n = $t.name
    Save-Svg "assets/hero/hero-banner-$n.svg" (Build-Hero $t)
    foreach ($k in @('about', 'journey', 'work', 'capabilities', 'activity', 'vision', 'connect')) {
        Save-Svg "assets/section-graphics/header-$k-$n.svg" (Build-Header $t $k)
    }
    Save-Svg "assets/section-graphics/about-code-$n.svg" (Build-CodeCard $t)
    Save-Svg "assets/section-graphics/clients-$n.svg" (Build-Spectrum $t)
    Save-Svg "assets/career/career-timeline-$n.svg" (Build-Timeline $t)
    Save-Svg "assets/project-banners/practice-areas-$n.svg" (Build-Practice $t)
    foreach ($pr in $P.Projects) {
        if ($pr.Kind -eq 'featured') { Save-Svg "assets/project-banners/$($pr.Slug)-$n.svg" (Build-Featured $t $pr) }
        else { Save-Svg "assets/project-banners/$($pr.Slug)-$n.svg" (Build-Half $t $pr) }
    }
    Save-Svg "assets/project-banners/more-repos-$n.svg" (Build-More $t)
    Save-Svg "assets/section-graphics/capabilities-$n.svg" (Build-Capabilities $t)
    Save-Svg "assets/section-graphics/philosophy-$n.svg" (Build-Philosophy $t)
    Save-Svg "assets/section-graphics/connect-$n.svg" (Build-Connect $t)
    Save-Svg "assets/section-graphics/footer-$n.svg" (Build-Footer $t)
    foreach ($b in $P.Buttons) { Save-Svg "assets/icons/button-$($b.Slug)-$n.svg" (Build-Button $t $b.Label) }
    $snake = Join-Path $script:RepoRoot "assets/activity/snake-$n.svg"
    if (-not (Test-Path $snake)) { Save-Svg "assets/activity/snake-$n.svg" (Build-SnakePlaceholder $t) }
}
Write-Host 'Done.'

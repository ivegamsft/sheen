#!/usr/bin/env pwsh
# render-diagram-types.ps1 — the 16 per-type layout algorithms for the
# documentation-diagram renderer (#113). Dot-sourced by render-diagram.ps1,
# which defines the SVG primitive helpers (Svg-Rect, Svg-Text, Svg-Connector,
# Svg-EdgeLabel, Svg-Icon, ...), $FontFamily, and Get-Icon used below.
#
# Design conventions applied throughout (see docs/foundations/diagram-skin-adapter.md
# and skills/design-audit/SKILL.md "Diagram Anti-Slop Rules"):
#   - Every colour is a skin role (paper/paper-2/ink/muted/soft/rule/
#     rule-solid/accent/accent-tint/link/series[0-7]) — never a literal hex,
#     so STRAY-HEX (#115) always passes.
#   - `accent`/`accent-tint` are reserved for at most 1-2 focal-emphasis
#     elements (ACCENT-BUDGET) — most renderers below don't use them at all.
#   - Only genuine structural nodes (boxes joined by real connectors — org
#     chart, fishbone) get an `id` attribute, so DENSITY counts structural
#     complexity, not data-mark counts (a 50-bar bar chart is not "50 nodes").
#   - `class="connector"` is used only where an orthogonal (org chart) or
#     exact-45-degree (fishbone) routing is natural. Loop/flywheel and Sankey
#     use inherently curved/diagonal flow paths, so those are undecorated
#     `<path>` elements exempt from the geometry lint's connector rules —
#     documented per-function below.
#   - No `<rect>` corner radius exceeds 10px (RADIUS) and no drop-shadow
#     filters are used anywhere (SHADOW) — diagrams are flat by design.

# ── shared small helpers ─────────────────────────────────────────────────────

function New-Result {
    param([string]$Title, [string]$Description, [int]$Width, [int]$Height, [string]$Svg,
          [string[]]$TableHeaders, [System.Collections.IEnumerable]$TableRows)
    return [ordered]@{
        Title        = $Title
        Description  = $Description
        Width        = $Width
        Height       = $Height
        Svg          = $Svg
        TableHeaders = $TableHeaders
        TableRows    = @($TableRows)
    }
}

function Pick-Series([hashtable]$Skin, [int]$i) {
    $series = $Skin['series']
    return $series[$i % $series.Count]
}

# Measure-Object emits NO output object at all when its input pipeline is
# completely empty, so `(... | Measure-Object -Sum).Sum` throws under
# Set-StrictMode when a filter matches zero items. This helper always
# returns a number (0 for empty input).
function Sum-Values($items, [string]$prop) {
    $arr = @($items)
    if ($arr.Count -eq 0) { return 0 }
    $m = $arr | Measure-Object -Property $prop -Sum
    if (-not $m) { return 0 }
    return $m.Sum
}

# ── 1. Bar ────────────────────────────────────────────────────────────────────
function Render-Bar($Spec, $Skin) {
    $w = 640; $h = 400; $marginL = 60; $marginB = 50; $marginT = 40; $marginR = 30
    $plotW = $w - $marginL - $marginR; $plotH = $h - $marginT - $marginB
    $cats = @($Spec.categories)
    $maxVal = ($cats | ForEach-Object { $_.value } | Measure-Object -Maximum).Maximum
    if ($maxVal -le 0) { $maxVal = 1 }
    $n = $cats.Count
    $gap = 14
    $barW = [Math]::Max(8, ($plotW - $gap * ($n - 1)) / $n)

    $svg = @()
    $svg += Svg-Line -X1 $marginL -Y1 $marginT -X2 $marginL -Y2 ($marginT + $plotH) -Stroke $Skin['rule-solid'] -StrokeWidth 1.5
    $svg += Svg-Line -X1 $marginL -Y1 ($marginT + $plotH) -X2 ($marginL + $plotW) -Y2 ($marginT + $plotH) -Stroke $Skin['rule-solid'] -StrokeWidth 1.5

    $rows = @()
    for ($i = 0; $i -lt $n; $i++) {
        $c = $cats[$i]
        $barH = [Math]::Round(($c.value / $maxVal) * $plotH)
        $x = $marginL + $i * ($barW + $gap)
        $y = $marginT + $plotH - $barH
        $svg += Svg-Rect -X $x -Y $y -W $barW -H $barH -Fill (Pick-Series $Skin $i)
        $svg += Svg-Text -X ($x + $barW / 2) -Y ($y - 6) -Content ([string]$c.value) -Fill $Skin['ink'] -Size 11 -Anchor 'middle'
        $svg += Svg-Text -X ($x + $barW / 2) -Y ($marginT + $plotH + 18) -Content ([string]$c.label) -Fill $Skin['muted'] -Size 11 -Anchor 'middle'
        $rows += , @([string]$c.label, [string]$c.value)
    }
    return New-Result -Title $Spec.title -Description "Bar chart: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Category', 'Value') -TableRows $rows
}

# ── 2. Line ───────────────────────────────────────────────────────────────────
function Render-Line($Spec, $Skin) {
    $w = 640; $h = 400; $marginL = 60; $marginB = 50; $marginT = 40; $marginR = 30
    $plotW = $w - $marginL - $marginR; $plotH = $h - $marginT - $marginB
    $seriesList = @($Spec.series)
    $allPts = @($seriesList | ForEach-Object { $_.points })
    $maxX = ($allPts | ForEach-Object { $_.x } | Measure-Object -Maximum).Maximum
    $minX = ($allPts | ForEach-Object { $_.x } | Measure-Object -Minimum).Minimum
    $maxY = ($allPts | ForEach-Object { $_.y } | Measure-Object -Maximum).Maximum
    if ($maxX -eq $minX) { $maxX = $minX + 1 }
    if ($maxY -le 0) { $maxY = 1 }

    $svg = @()
    $svg += Svg-Line -X1 $marginL -Y1 $marginT -X2 $marginL -Y2 ($marginT + $plotH) -Stroke $Skin['rule-solid'] -StrokeWidth 1.5
    $svg += Svg-Line -X1 $marginL -Y1 ($marginT + $plotH) -X2 ($marginL + $plotW) -Y2 ($marginT + $plotH) -Stroke $Skin['rule-solid'] -StrokeWidth 1.5

    $rows = @()
    for ($s = 0; $s -lt $seriesList.Count; $s++) {
        $series = $seriesList[$s]
        $color = Pick-Series $Skin $s
        $pts = @($series.points)
        $coords = $pts | ForEach-Object {
            $px = $marginL + (($_.x - $minX) / ($maxX - $minX)) * $plotW
            $py = $marginT + $plotH - (($_.y / $maxY) * $plotH)
            "$([Math]::Round($px,1)),$([Math]::Round($py,1))"
        }
        $d = "M " + ($coords -join " L ")
        $svg += Svg-Path -D $d -Stroke $color -StrokeWidth 2.5
        foreach ($p in $pts) {
            $px = $marginL + (($p.x - $minX) / ($maxX - $minX)) * $plotW
            $py = $marginT + $plotH - (($p.y / $maxY) * $plotH)
            $svg += Svg-Circle -Cx $px -Cy $py -R 3 -Fill $color
            $rows += , @([string]$series.name, [string]$p.x, [string]$p.y)
        }
        $svg += Svg-Text -X ($marginL + 8 + $s * 120) -Y ($marginT - 16) -Content $series.name -Fill $color -Size 11 -Anchor 'start' -Weight 'bold'
    }
    return New-Result -Title $Spec.title -Description "Line chart: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Series', 'X', 'Y') -TableRows $rows
}

# ── 3. Sankey ─────────────────────────────────────────────────────────────────
# Flow ribbons are inherently curved (bezier), not orthogonal — rendered as
# plain <path> (no class="connector"), exempt from the geometry lint's
# connector rules by design (documented at file header).
function Render-Sankey($Spec, $Skin) {
    $w = 700; $h = 420; $marginT = 40; $marginB = 30
    $nodes = @($Spec.nodes)
    $links = @($Spec.links)
    $columns = ($nodes | ForEach-Object { $_.column } | Sort-Object -Unique)
    $colW = 140; $nodeW = 18
    $colX = @{}
    foreach ($c in $columns) { $colX[$c] = 40 + $c * $colW }

    $plotH = $h - $marginT - $marginB
    $nodePos = @{}
    foreach ($c in $columns) {
        $colNodes = @($nodes | Where-Object { $_.column -eq $c })
        $totalValue = Sum-Values (@($links | Where-Object { ($colNodes.id) -contains $_.source })) 'value'
        if (-not $totalValue -or $totalValue -le 0) {
            $totalValue = Sum-Values (@($links | Where-Object { ($colNodes.id) -contains $_.target })) 'value'
        }
        if (-not $totalValue -or $totalValue -le 0) { $totalValue = 1 }
        $y = $marginT
        $gap = 16
        foreach ($node in $colNodes) {
            $outVal = Sum-Values (@($links | Where-Object { $_.source -eq $node.id })) 'value'
            $inVal = Sum-Values (@($links | Where-Object { $_.target -eq $node.id })) 'value'
            $val = [Math]::Max($outVal, $inVal)
            if (-not $val -or $val -le 0) { $val = 1 }
            $nodeH = [Math]::Max(16, ($val / $totalValue) * ($plotH - $gap * ($colNodes.Count - 1)))
            $nodePos[$node.id] = @{ X = $colX[$node.column]; Y = $y; H = $nodeH; Label = $node.label }
            $y += $nodeH + $gap
        }
    }

    $svg = @()
    $linkIdx = 0
    foreach ($link in $links) {
        $from = $nodePos[$link.source]; $to = $nodePos[$link.target]
        if (-not $from -or -not $to) { continue }
        $x1 = $from.X + $nodeW; $y1 = $from.Y + $from.H / 2
        $x2 = $to.X; $y2 = $to.Y + $to.H / 2
        $midX = ($x1 + $x2) / 2
        $strokeW = [Math]::Max(4, ($link.value / 10.0))
        $d = "M $x1,$y1 C $midX,$y1 $midX,$y2 $x2,$y2"
        $color = Pick-Series $Skin $linkIdx
        $svg += "<path d=`"$d`" fill=`"none`" stroke=`"$color`" stroke-width=`"$strokeW`" stroke-opacity=`"0.55`" />"
        $linkIdx++
    }
    $rows = @()
    foreach ($node in $nodes) {
        $pos = $nodePos[$node.id]
        if (-not $pos) { continue }
        $svg += Svg-Rect -X $pos.X -Y $pos.Y -W $nodeW -H $pos.H -Fill $Skin['ink']
        $anchorX = if ($pos.X -lt ($w / 2)) { $pos.X - 6 } else { $pos.X + $nodeW + 6 }
        $anchor = if ($pos.X -lt ($w / 2)) { 'end' } else { 'start' }
        $svg += Svg-Text -X $anchorX -Y ($pos.Y + $pos.H / 2 + 4) -Content $pos.Label -Fill $Skin['ink'] -Size 11 -Anchor $anchor
    }
    foreach ($link in $links) { $rows += , @($link.source, $link.target, [string]$link.value) }
    return New-Result -Title $Spec.title -Description "Sankey diagram: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Source', 'Target', 'Value') -TableRows $rows
}

# ── 4. Treemap (flat slice-and-dice) ─────────────────────────────────────────
function Render-Treemap($Spec, $Skin) {
    $w = 640; $h = 400
    $items = @($Spec.items) | Sort-Object -Property value -Descending
    $total = ($items | Measure-Object -Property value -Sum).Sum
    if (-not $total -or $total -le 0) { $total = 1 }

    $svg = @()
    $rows = @()
    $x = 0; $y = 0; $remW = $w; $remH = $h; $horizontal = $true
    $consumed = 0
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $frac = $item.value / $total
        if ($horizontal) {
            $itemW = [Math]::Round($remW * $frac / (1.0 - ($consumed / $total)))
            if ($i -eq $items.Count - 1) { $itemW = $remW }
            $itemW = [Math]::Min($itemW, $remW)
            $svg += Svg-Rect -X $x -Y $y -W $itemW -H $remH -Fill (Pick-Series $Skin $i) -Stroke $Skin['paper'] -StrokeWidth 2
            $svg += Svg-Text -X ($x + 6) -Y ($y + 18) -Content $item.label -Fill $Skin['paper'] -Size 12 -Weight 'bold'
            $svg += Svg-Text -X ($x + 6) -Y ($y + 34) -Content ([string]$item.value) -Fill $Skin['paper'] -Size 11
            $x += $itemW; $remW -= $itemW
        } else {
            $itemH = [Math]::Round($remH * $frac)
            $svg += Svg-Rect -X $x -Y $y -W $remW -H $itemH -Fill (Pick-Series $Skin $i) -Stroke $Skin['paper'] -StrokeWidth 2
            $svg += Svg-Text -X ($x + 6) -Y ($y + 18) -Content $item.label -Fill $Skin['paper'] -Size 12 -Weight 'bold'
            $svg += Svg-Text -X ($x + 6) -Y ($y + 34) -Content ([string]$item.value) -Fill $Skin['paper'] -Size 11
            $y += $itemH; $remH -= $itemH
        }
        $horizontal = -not $horizontal
        $consumed += $item.value
        $rows += , @([string]$item.label, [string]$item.value)
    }
    return New-Result -Title $Spec.title -Description "Treemap: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Label', 'Value') -TableRows $rows
}

# ── 5. Gantt ──────────────────────────────────────────────────────────────────
function Render-Gantt($Spec, $Skin) {
    $tasks = @($Spec.tasks)
    $w = 700; $marginL = 140; $marginT = 40; $rowH = 34; $marginR = 30
    $h = $marginT + $tasks.Count * $rowH + 30
    $maxEnd = ($tasks | ForEach-Object { $_.start + $_.duration } | Measure-Object -Maximum).Maximum
    if (-not $maxEnd -or $maxEnd -le 0) { $maxEnd = 1 }
    $plotW = $w - $marginL - $marginR

    $svg = @()
    for ($d = 0; $d -le $maxEnd; $d += [Math]::Max(1, [Math]::Round($maxEnd / 10))) {
        $gx = $marginL + ($d / $maxEnd) * $plotW
        $svg += Svg-Line -X1 $gx -Y1 $marginT -X2 $gx -Y2 ($h - 20) -Stroke $Skin['soft'] -StrokeWidth 1
        $svg += Svg-Text -X $gx -Y ($h - 6) -Content "day $d" -Fill $Skin['muted'] -Size 9 -Anchor 'middle'
    }
    $rows = @()
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $t = $tasks[$i]
        $y = $marginT + $i * $rowH
        $bx = $marginL + ($t.start / $maxEnd) * $plotW
        $bw = [Math]::Max(6, ($t.duration / $maxEnd) * $plotW)
        $svg += Svg-Text -X ($marginL - 10) -Y ($y + $rowH / 2 + 4) -Content $t.label -Fill $Skin['ink'] -Size 11 -Anchor 'end'
        $svg += Svg-Rect -X $bx -Y ($y + 6) -W $bw -H ($rowH - 14) -Fill (Pick-Series $Skin $i) -Rx 3
        $rows += , @([string]$t.label, [string]$t.start, [string]$t.duration)
    }
    return New-Result -Title $Spec.title -Description "Gantt chart: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Task', 'Start (day)', 'Duration (days)') -TableRows $rows
}

# ── 6. Kanban ─────────────────────────────────────────────────────────────────
function Render-Kanban($Spec, $Skin) {
    $columns = @($Spec.columns)
    $colW = 180; $gap = 16; $marginT = 50; $cardH = 34
    $maxCards = ($columns | ForEach-Object { $_.cards.Count } | Measure-Object -Maximum).Maximum
    $w = $columns.Count * ($colW + $gap) + $gap
    $h = $marginT + [Math]::Max(1, $maxCards) * ($cardH + 8) + 30

    $svg = @()
    $rows = @()
    for ($i = 0; $i -lt $columns.Count; $i++) {
        $col = $columns[$i]
        $x = $gap + $i * ($colW + $gap)
        $svg += Svg-Rect -X $x -Y 16 -W $colW -H ($h - 30) -Fill $Skin['paper-2'] -Stroke $Skin['rule-solid'] -StrokeWidth 1.5 -Rx 4
        $svg += Svg-Text -X ($x + $colW / 2) -Y 40 -Content $col.label -Fill $Skin['ink'] -Size 13 -Anchor 'middle' -Weight 'bold'
        for ($j = 0; $j -lt $col.cards.Count; $j++) {
            $cy = $marginT + $j * ($cardH + 8)
            $svg += Svg-Rect -X ($x + 10) -Y $cy -W ($colW - 20) -H $cardH -Fill $Skin['paper'] -Stroke $Skin['rule'] -StrokeWidth 1 -Rx 3
            $svg += Svg-Text -X ($x + $colW / 2) -Y ($cy + $cardH / 2 + 4) -Content $col.cards[$j] -Fill $Skin['ink'] -Size 10 -Anchor 'middle'
            $rows += , @($col.label, $col.cards[$j])
        }
    }
    return New-Result -Title $Spec.title -Description "Kanban board: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Column', 'Card') -TableRows $rows
}

# ── 7. Story map ──────────────────────────────────────────────────────────────
function Render-StoryMap($Spec, $Skin) {
    $activities = @($Spec.activities)
    $releases = @($Spec.releases)
    $colW = 150; $gap = 10; $marginT = 60; $cardH = 30
    $w = $activities.Count * ($colW + $gap) + $gap
    $maxRows = ($releases | ForEach-Object { ($_.storiesByActivity | ForEach-Object { $_.Count } | Measure-Object -Maximum).Maximum } | Measure-Object -Maximum).Maximum
    $h = $marginT + $releases.Count * ((([int]$maxRows) * ($cardH + 6)) + 40) + 20

    $svg = @()
    $rows = @()
    for ($i = 0; $i -lt $activities.Count; $i++) {
        $x = $gap + $i * ($colW + $gap)
        $svg += Svg-Rect -X $x -Y 16 -W $colW -H 34 -Fill $Skin['soft'] -Stroke $Skin['rule-solid'] -StrokeWidth 1.5 -Rx 3
        $svg += Svg-Text -X ($x + $colW / 2) -Y 38 -Content $activities[$i] -Fill $Skin['ink'] -Size 12 -Anchor 'middle' -Weight 'bold'
    }
    $y = $marginT + 20
    for ($r = 0; $r -lt $releases.Count; $r++) {
        $release = $releases[$r]
        $svg += Svg-Text -X $gap -Y ($y - 6) -Content $release.label -Fill $Skin['muted'] -Size 11 -Weight 'bold'
        for ($i = 0; $i -lt $activities.Count; $i++) {
            $x = $gap + $i * ($colW + $gap)
            $stories = @($release.storiesByActivity[$i])
            for ($j = 0; $j -lt $stories.Count; $j++) {
                $cy = $y + $j * ($cardH + 6)
                $svg += Svg-Rect -X $x -Y $cy -W $colW -H $cardH -Fill $Skin['paper-2'] -Stroke $Skin['rule'] -StrokeWidth 1 -Rx 3
                $svg += Svg-Text -X ($x + $colW / 2) -Y ($cy + $cardH / 2 + 4) -Content $stories[$j] -Fill $Skin['ink'] -Size 10 -Anchor 'middle'
                $rows += , @($release.label, $activities[$i], $stories[$j])
            }
        }
        $y += (([int]$maxRows) * ($cardH + 6)) + 40
    }
    return New-Result -Title $Spec.title -Description "Story map: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Release', 'Activity', 'Story') -TableRows $rows
}

# ── 8. User journey ───────────────────────────────────────────────────────────
function Render-UserJourney($Spec, $Skin) {
    $stages = @($Spec.stages)
    $w = 700; $h = 340; $marginL = 60; $marginR = 30; $marginT = 60; $marginB = 80
    $plotW = $w - $marginL - $marginR; $plotH = $h - $marginT - $marginB
    $n = $stages.Count
    $stepX = $plotW / [Math]::Max(1, $n - 1)

    $svg = @()
    $svg += Svg-Line -X1 $marginL -Y1 ($marginT + $plotH / 2) -X2 ($marginL + $plotW) -Y2 ($marginT + $plotH / 2) -Stroke $Skin['soft'] -StrokeWidth 1 -DashArray '4,4'

    $coords = @()
    for ($i = 0; $i -lt $n; $i++) {
        $x = $marginL + $i * $stepX
        $y = $marginT + $plotH - (($stages[$i].emotion / 5.0) * $plotH)
        $coords += "$([Math]::Round($x,1)),$([Math]::Round($y,1))"
    }
    $svg += Svg-Path -D ("M " + ($coords -join " L ")) -Stroke (Pick-Series $Skin 0) -StrokeWidth 2.5

    $rows = @()
    for ($i = 0; $i -lt $n; $i++) {
        $s = $stages[$i]
        $x = $marginL + $i * $stepX
        $y = $marginT + $plotH - (($s.emotion / 5.0) * $plotH)
        $svg += Svg-Circle -Cx $x -Cy $y -R 5 -Fill (Pick-Series $Skin 0)
        $svg += Svg-Text -X $x -Y ($marginT + $plotH + 22) -Content $s.label -Fill $Skin['ink'] -Size 11 -Anchor 'middle' -Weight 'bold'
        $svg += Svg-Text -X $x -Y ($marginT + $plotH + 40) -Content $s.action -Fill $Skin['muted'] -Size 10 -Anchor 'middle'
        $rows += , @($s.label, $s.action, [string]$s.emotion)
    }
    $svg += Svg-Text -X $marginL -Y ($marginT - 30) -Content 'Emotion (1 = low, 5 = high)' -Fill $Skin['muted'] -Size 10
    return New-Result -Title $Spec.title -Description "User journey map: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Stage', 'Action', 'Emotion (1-5)') -TableRows $rows
}

# ── 9. Quadrant ────────────────────────────────────────────────────────────────
function Render-Quadrant($Spec, $Skin) {
    $w = 500; $h = 500; $margin = 60
    $plot = $w - $margin * 2
    $svg = @()
    $svg += Svg-Rect -X $margin -Y $margin -W $plot -H $plot -Fill 'none' -Stroke $Skin['rule-solid'] -StrokeWidth 1.5
    $svg += Svg-Line -X1 ($margin + $plot / 2) -Y1 $margin -X2 ($margin + $plot / 2) -Y2 ($margin + $plot) -Stroke $Skin['rule'] -StrokeWidth 1
    $svg += Svg-Line -X1 $margin -Y1 ($margin + $plot / 2) -X2 ($margin + $plot) -Y2 ($margin + $plot / 2) -Stroke $Skin['rule'] -StrokeWidth 1
    $svg += Svg-Text -X ($margin + $plot / 2) -Y ($margin - 16) -Content $Spec.xAxis -Fill $Skin['muted'] -Size 11 -Anchor 'middle'
    $svg += "<g transform=`"translate($($margin-40),$($margin+$plot/2)) rotate(-90)`">" + (Svg-Text -X 0 -Y 0 -Content $Spec.yAxis -Fill $Skin['muted'] -Size 11 -Anchor 'middle') + "</g>"

    $rows = @()
    $items = @($Spec.items)
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $x = $margin + $item.x * $plot
        $y = $margin + $plot - ($item.y * $plot)
        $svg += Svg-Circle -Cx $x -Cy $y -R 6 -Fill (Pick-Series $Skin $i)
        $svg += Svg-Text -X ($x + 10) -Y ($y + 4) -Content $item.label -Fill $Skin['ink'] -Size 11
        $rows += , @($item.label, [string]$item.x, [string]$item.y)
    }
    return New-Result -Title $Spec.title -Description "Quadrant chart: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Label', $Spec.xAxis, $Spec.yAxis) -TableRows $rows
}

# ── 10. Fishbone ───────────────────────────────────────────────────────────────
# Bones are drawn at an exact 45-degree angle so they satisfy the geometry
# lint's SLANT rule (which allows only 0/45/90-degree connectors).
function Render-Fishbone($Spec, $Skin) {
    $w = 760; $h = 420; $spineY = $h / 2; $effectX = $w - 90
    $categories = @($Spec.categories)
    $boxW = 130; $boxH = 30; $offset = 90

    $svg = @()
    $svg += Svg-Line -X1 60 -Y1 $spineY -X2 $effectX -Y2 $spineY -Stroke $Skin['rule-solid'] -StrokeWidth 2.5

    $n = $categories.Count
    $spacing = ($effectX - 140) / [Math]::Max(1, $n)
    $rows = @()
    for ($i = 0; $i -lt $n; $i++) {
        $cat = $categories[$i]
        $attachX = 120 + $i * $spacing
        $above = ($i % 2 -eq 0)
        $boxCx = $attachX - $offset
        $boxCy = if ($above) { $spineY - $offset } else { $spineY + $offset }
        $boxId = "cat-$i"
        $svg += Svg-Connector -FromId 'spine' -ToId $boxId -D "M $attachX,$spineY L $boxCx,$boxCy" -Stroke $Skin['muted'] -StrokeWidth 1.5
        $svg += Svg-Rect -X ($boxCx - $boxW / 2) -Y ($boxCy - $boxH / 2) -W $boxW -H $boxH -Fill $Skin['paper-2'] -Stroke $Skin['rule-solid'] -StrokeWidth 1.5 -Id $boxId -Rx 3
        $svg += Svg-Text -X $boxCx -Y ($boxCy + 4) -Content $cat.label -Fill $Skin['ink'] -Size 11 -Anchor 'middle' -Weight 'bold'
        $causesText = ($cat.causes -join '; ')
        $causeY = if ($above) { $boxCy - $boxH / 2 - 8 } else { $boxCy + $boxH / 2 + 16 }
        $svg += Svg-Text -X $boxCx -Y $causeY -Content $causesText -Fill $Skin['muted'] -Size 9 -Anchor 'middle'
        $rows += , @($cat.label, $causesText)
    }
    $svg += Svg-Connector -FromId 'spine' -ToId 'effect' -D "M $($effectX-100),$spineY L $($effectX-10),$spineY" -Stroke $Skin['ink'] -StrokeWidth 2
    $svg += Svg-Rect -X ($effectX - 10) -Y ($spineY - 20) -W 100 -H 40 -Fill $Skin['muted'] -Id 'effect' -Rx 3
    $svg += Svg-Text -X ($effectX + 40) -Y ($spineY + 5) -Content $Spec.effect -Fill $Skin['paper'] -Size 11 -Anchor 'middle' -Weight 'bold'

    return New-Result -Title $Spec.title -Description "Fishbone (cause-and-effect) diagram: $($Spec.title) -> $($Spec.effect)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Category', 'Causes') -TableRows $rows
}

# ── 11. Pyramid/funnel ────────────────────────────────────────────────────────
function Render-Funnel($Spec, $Skin) {
    $levels = @($Spec.levels)
    $w = 500; $marginT = 30; $levelH = 60; $h = $marginT + $levels.Count * $levelH + 20
    $maxVal = ($levels | Measure-Object -Property value -Maximum).Maximum
    if (-not $maxVal -or $maxVal -le 0) { $maxVal = 1 }
    $maxWidth = $w - 80

    $svg = @()
    $rows = @()
    for ($i = 0; $i -lt $levels.Count; $i++) {
        $lvl = $levels[$i]
        $topFrac = if ($i -eq 0) { 1.0 } else { $levels[$i - 1].value / $maxVal }
        $botFrac = $lvl.value / $maxVal
        $topW = $maxWidth * $topFrac
        $botW = $maxWidth * $botFrac
        $y = $marginT + $i * $levelH
        $topX1 = ($w - $topW) / 2; $topX2 = $topX1 + $topW
        $botX1 = ($w - $botW) / 2; $botX2 = $botX1 + $botW
        $points = "$topX1,$y $topX2,$y $botX2,$($y+$levelH) $botX1,$($y+$levelH)"
        $svg += Svg-Polygon -Points $points -Fill (Pick-Series $Skin $i) -Stroke $Skin['paper'] -StrokeWidth 2
        $svg += Svg-Text -X ($w / 2) -Y ($y + $levelH / 2 - 4) -Content $lvl.label -Fill $Skin['paper'] -Size 12 -Anchor 'middle' -Weight 'bold'
        $svg += Svg-Text -X ($w / 2) -Y ($y + $levelH / 2 + 12) -Content ([string]$lvl.value) -Fill $Skin['paper'] -Size 10 -Anchor 'middle'
        $rows += , @([string]$lvl.label, [string]$lvl.value)
    }
    return New-Result -Title $Spec.title -Description "Pyramid/funnel diagram: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Level', 'Value') -TableRows $rows
}

# ── 12. Org chart ──────────────────────────────────────────────────────────────
# Every connector is drawn as two pure vertical segments joined by an
# undecorated horizontal "bus" line, so every `class="connector"` path has
# dx=0 (passes SLANT trivially) and the bus itself (no class) is exempt from
# the geometry lint entirely — see file header for the rationale.
function Render-OrgChart($Spec, $Skin) {
    $boxW = 130; $boxH = 40; $levelH = 90; $hGap = 20

    # pass 1: leaf count per node (for horizontal span)
    function Has-Prop($obj, $name) { return [bool]($obj.PSObject.Properties.Name -contains $name) }
    function Count-Leaves($node) {
        if (-not (Has-Prop $node 'children') -or @($node.children).Count -eq 0) { return 1 }
        $sum = 0
        foreach ($c in @($node.children)) { $sum += Count-Leaves $c }
        return $sum
    }

    $script:orgNodes = @()
    $script:orgIdSeq = 0
    function Layout-Node($node, $depth, $xStart, $xEnd, $parentId) {
        $id = "org-$($script:orgIdSeq)"; $script:orgIdSeq++
        $cx = ($xStart + $xEnd) / 2
        $cy = 40 + $depth * $levelH
        $script:orgNodes += [pscustomobject]@{ Id = $id; ParentId = $parentId; Label = $node.label; Cx = $cx; Cy = $cy }
        $children = @(if (Has-Prop $node 'children') { @($node.children) })
        if ($children.Count -gt 0) {
            $totalLeaves = ($children | ForEach-Object { Count-Leaves $_ } | Measure-Object -Sum).Sum
            $x = $xStart
            foreach ($child in $children) {
                $leaves = Count-Leaves $child
                $span = ($xEnd - $xStart) * ($leaves / $totalLeaves)
                Layout-Node $child ($depth + 1) $x ($x + $span) $id
                $x += $span
            }
        }
        return $id
    }
    $totalLeaves = Count-Leaves $Spec.root
    $w = [Math]::Max(500, $totalLeaves * ($boxW + $hGap) + $hGap)
    Layout-Node $Spec.root 0 0 $w $null | Out-Null
    $maxDepth = ($script:orgNodes | ForEach-Object { ($_.Cy - 40) / $levelH } | Measure-Object -Maximum).Maximum
    $h = 40 + ($maxDepth + 1) * $levelH + 30

    $svg = @()
    $rows = @()
    $parentIds = @($script:orgNodes | Where-Object { $_.ParentId } | ForEach-Object { $_.ParentId } | Select-Object -Unique)
    foreach ($parentId in $parentIds) {
        $parent = $script:orgNodes | Where-Object { $_.Id -eq $parentId } | Select-Object -First 1
        $kids = @($script:orgNodes | Where-Object { $_.ParentId -eq $parentId })
        if ($kids.Count -eq 1) {
            # Single child: one straight vertical connector, no bus needed (a
            # two-segment chain here would have both segments share the same
            # point since parent.Cx == child.Cx, tripping SHARED-ATTACH).
            $n = $kids[0]
            $svg += Svg-Connector -FromId $parent.Id -ToId $n.Id -D "M $($parent.Cx),$($parent.Cy + $boxH/2) L $($n.Cx),$($n.Cy - $boxH/2)" -Stroke $Skin['muted'] -StrokeWidth 1.5
            continue
        }
        $busY = ($parent.Cy + $boxH / 2 + $kids[0].Cy - $boxH / 2) / 2
        $svg += Svg-Connector -FromId $parent.Id -ToId "bus-$parentId" -D "M $($parent.Cx),$($parent.Cy + $boxH/2) L $($parent.Cx),$busY" -Stroke $Skin['muted'] -StrokeWidth 1.5
        $busXs = (@($kids | ForEach-Object { $_.Cx }) + $parent.Cx)
        $busMinX = ($busXs | Measure-Object -Minimum).Minimum
        $busMaxX = ($busXs | Measure-Object -Maximum).Maximum
        $svg += "<path d=`"M $busMinX,$busY L $busMaxX,$busY`" fill=`"none`" stroke=`"$($Skin['muted'])`" stroke-width=`"1.5`" />"
        foreach ($n in $kids) {
            $svg += Svg-Connector -FromId "bus-$parentId" -ToId $n.Id -D "M $($n.Cx),$busY L $($n.Cx),$($n.Cy - $boxH/2)" -Stroke $Skin['muted'] -StrokeWidth 1.5
        }
    }
    foreach ($n in $script:orgNodes) {
        $svg += Svg-Rect -X ($n.Cx - $boxW / 2) -Y ($n.Cy - $boxH / 2) -W $boxW -H $boxH -Fill $Skin['paper-2'] -Stroke $Skin['rule-solid'] -StrokeWidth 1.5 -Id $n.Id -Rx 4
        $svg += Svg-Icon -Name 'users' -X ($n.Cx - $boxW / 2 + 8) -Y ($n.Cy - 9) -Size 18 -Color $Skin['muted']
        $svg += Svg-Text -X ($n.Cx + 10) -Y ($n.Cy + 5) -Content $n.Label -Fill $Skin['ink'] -Size 11 -Anchor 'middle' -Weight 'bold'
        $parentLabel = if ($n.ParentId) { ($script:orgNodes | Where-Object { $_.Id -eq $n.ParentId }).Label } else { '(root)' }
        $rows += , @($n.Label, $parentLabel)
    }
    return New-Result -Title $Spec.title -Description "Org chart: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Role', 'Reports to') -TableRows $rows
}

# ── 13. Loop/flywheel ──────────────────────────────────────────────────────────
# Rotational arrows are inherently curved — undecorated <path> (no
# class="connector"), exempt from the geometry lint by design (file header).
function Render-Loop($Spec, $Skin) {
    $steps = @($Spec.steps)
    $w = 480; $h = 480; $cx = $w / 2; $cy = $h / 2; $r = 160
    $n = $steps.Count
    $boxW = 130; $boxH = 44

    $svg = @()
    $positions = @()
    for ($i = 0; $i -lt $n; $i++) {
        $angle = (2 * [Math]::PI * $i / $n) - ([Math]::PI / 2)
        $x = $cx + $r * [Math]::Cos($angle)
        $y = $cy + $r * [Math]::Sin($angle)
        $positions += @{ X = $x; Y = $y }
    }
    for ($i = 0; $i -lt $n; $i++) {
        $a = $positions[$i]; $b = $positions[($i + 1) % $n]
        $midX = $cx + ($a.X + $b.X - 2 * $cx) / 2 * 1.15 + $cx * 0
        $ctrlX = $cx + (($a.X + $b.X) / 2 - $cx) * 1.25
        $ctrlY = $cy + (($a.Y + $b.Y) / 2 - $cy) * 1.25
        $d = "M $($a.X),$($a.Y) Q $ctrlX,$ctrlY $($b.X),$($b.Y)"
        $svg += "<path d=`"$d`" fill=`"none`" stroke=`"$($Skin['muted'])`" stroke-width=`"2`" marker-end=`"url(#loop-arrow)`" />"
    }
    $svg += "<defs><marker id=`"loop-arrow`" markerWidth=`"8`" markerHeight=`"8`" refX=`"6`" refY=`"4`" orient=`"auto`"><path d=`"M0,0 L8,4 L0,8 Z`" fill=`"$($Skin['muted'])`" /></marker></defs>"

    $rows = @()
    for ($i = 0; $i -lt $n; $i++) {
        $p = $positions[$i]
        $svg += Svg-Rect -X ($p.X - $boxW / 2) -Y ($p.Y - $boxH / 2) -W $boxW -H $boxH -Fill (Pick-Series $Skin $i) -Rx 4
        $svg += Svg-Text -X $p.X -Y ($p.Y + 5) -Content $steps[$i] -Fill $Skin['paper'] -Size 11 -Anchor 'middle' -Weight 'bold'
        $rows += , @([string]($i + 1), $steps[$i])
    }
    return New-Result -Title $Spec.title -Description "Loop/flywheel diagram: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Step #', 'Step') -TableRows $rows
}

# ── 14. Timeline ───────────────────────────────────────────────────────────────
function Render-Timeline($Spec, $Skin) {
    $events = @($Spec.events)
    $w = 720; $h = 220; $marginL = 50; $marginR = 50; $y = $h / 2
    $plotW = $w - $marginL - $marginR
    $n = $events.Count
    $step = $plotW / [Math]::Max(1, $n - 1)

    $svg = @()
    $svg += Svg-Line -X1 $marginL -Y1 $y -X2 ($marginL + $plotW) -Y2 $y -Stroke $Skin['rule-solid'] -StrokeWidth 2

    $rows = @()
    for ($i = 0; $i -lt $n; $i++) {
        $e = $events[$i]
        $x = $marginL + $i * $step
        $above = ($i % 2 -eq 0)
        $svg += Svg-Circle -Cx $x -Cy $y -R 6 -Fill (Pick-Series $Skin 0)
        $labelY = if ($above) { $y - 20 } else { $y + 34 }
        $dateY = if ($above) { $y - 36 } else { $y + 50 }
        $svg += Svg-Line -X1 $x -Y1 $y -X2 $x -Y2 $labelY -Stroke $Skin['soft'] -StrokeWidth 1
        $svg += Svg-Text -X $x -Y $labelY -Content $e.label -Fill $Skin['ink'] -Size 11 -Anchor 'middle' -Weight 'bold'
        $svg += Svg-Text -X $x -Y $dateY -Content $e.date -Fill $Skin['muted'] -Size 9 -Anchor 'middle'
        $rows += , @($e.date, $e.label)
    }
    return New-Result -Title $Spec.title -Description "Timeline: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Date', 'Event') -TableRows $rows
}

# ── 15. Venn (2 or 3 sets) ─────────────────────────────────────────────────────
function Render-Venn($Spec, $Skin) {
    $sets = @($Spec.sets)
    $w = 500; $h = 420; $r = 130
    $svg = @()
    $rows = @()
    if ($sets.Count -eq 2) {
        $c1 = @{ X = $w / 2 - $r * 0.55; Y = $h / 2 }
        $c2 = @{ X = $w / 2 + $r * 0.55; Y = $h / 2 }
        $svg += Svg-Circle -Cx $c1.X -Cy $c1.Y -R $r -Fill (Pick-Series $Skin 0) -Opacity 0.45
        $svg += Svg-Circle -Cx $c2.X -Cy $c2.Y -R $r -Fill (Pick-Series $Skin 1) -Opacity 0.45
        $svg += Svg-Text -X ($c1.X - $r * 0.6) -Y ($c1.Y - $r * 0.6) -Content $sets[0].label -Fill $Skin['ink'] -Size 13 -Anchor 'middle' -Weight 'bold'
        $svg += Svg-Text -X ($c2.X + $r * 0.6) -Y ($c2.Y - $r * 0.6) -Content $sets[1].label -Fill $Skin['ink'] -Size 13 -Anchor 'middle' -Weight 'bold'
        if ($Spec.overlapLabel) { $svg += Svg-Text -X ($w / 2) -Y ($h / 2 + 5) -Content $Spec.overlapLabel -Fill $Skin['ink'] -Size 11 -Anchor 'middle' }
        $rows += , @($sets[0].label, '')
        $rows += , @($sets[1].label, '')
        if ($Spec.overlapLabel) { $rows += , @('(overlap)', $Spec.overlapLabel) }
    } else {
        $r = 120
        $centers = @(
            @{ X = $w / 2; Y = $h / 2 - $r * 0.55 },
            @{ X = $w / 2 - $r * 0.65; Y = $h / 2 + $r * 0.4 },
            @{ X = $w / 2 + $r * 0.65; Y = $h / 2 + $r * 0.4 }
        )
        for ($i = 0; $i -lt 3; $i++) {
            $svg += Svg-Circle -Cx $centers[$i].X -Cy $centers[$i].Y -R $r -Fill (Pick-Series $Skin $i) -Opacity 0.4
        }
        $labelOffsets = @(@{X=0;Y=-$r*0.9}, @{X=-$r*1.0;Y=$r*0.6}, @{X=$r*1.0;Y=$r*0.6})
        for ($i = 0; $i -lt 3; $i++) {
            $svg += Svg-Text -X ($centers[$i].X + $labelOffsets[$i].X) -Y ($centers[$i].Y + $labelOffsets[$i].Y) -Content $sets[$i].label -Fill $Skin['ink'] -Size 12 -Anchor 'middle' -Weight 'bold'
            $rows += , @($sets[$i].label, '')
        }
        if ($Spec.overlapLabel) {
            $svg += Svg-Text -X ($w / 2) -Y ($h / 2 + 10) -Content $Spec.overlapLabel -Fill $Skin['ink'] -Size 10 -Anchor 'middle'
            $rows += , @('(overlap)', $Spec.overlapLabel)
        }
    }
    return New-Result -Title $Spec.title -Description "Venn diagram: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Set', 'Overlap note') -TableRows $rows
}

# ── 16. DP security matrix ─────────────────────────────────────────────────────
# Risk level is encoded by BOTH fill-opacity AND a numeric label + icon —
# never colour alone (data-visualisation accessibility contract).
function Render-SecurityMatrix($Spec, $Skin) {
    $rowsSpec = @($Spec.rows); $colsSpec = @($Spec.cols); $cells = $Spec.cells
    $labelW = 160; $cellW = 90; $cellH = 44; $marginT = 50
    $w = $labelW + $colsSpec.Count * $cellW + 20
    $h = $marginT + $rowsSpec.Count * $cellH + 20

    $svg = @()
    for ($c = 0; $c -lt $colsSpec.Count; $c++) {
        $x = $labelW + $c * $cellW
        $svg += Svg-Text -X ($x + $cellW / 2) -Y ($marginT - 10) -Content $colsSpec[$c] -Fill $Skin['muted'] -Size 10 -Anchor 'middle' -Weight 'bold'
    }
    $rows = @()
    $levelOpacity = @(0.12, 0.35, 0.6, 0.9)
    $levelName = @('None', 'Low', 'Medium', 'High')
    for ($r = 0; $r -lt $rowsSpec.Count; $r++) {
        $y = $marginT + $r * $cellH
        $svg += Svg-Text -X ($labelW - 10) -Y ($y + $cellH / 2 + 4) -Content $rowsSpec[$r] -Fill $Skin['ink'] -Size 11 -Anchor 'end' -Weight 'bold'
        for ($c = 0; $c -lt $colsSpec.Count; $c++) {
            $x = $labelW + $c * $cellW
            $level = [int]$cells[$r][$c]
            $opacity = $levelOpacity[[Math]::Min($level, 3)]
            $svg += Svg-Rect -X $x -Y $y -W ($cellW - 4) -H ($cellH - 4) -Fill $Skin['muted'] -Stroke $Skin['rule'] -StrokeWidth 1
            $svg += "<rect x=`"$x`" y=`"$y`" width=`"$($cellW-4)`" height=`"$($cellH-4)`" fill=`"$($Skin['muted'])`" fill-opacity=`"$opacity`" />"
            if ($level -ge 2) { $svg += Svg-Icon -Name 'shield-lock' -X ($x + 8) -Y ($y + 8) -Size 16 -Color $Skin['ink'] }
            $svg += Svg-Text -X ($x + $cellW - 16) -Y ($y + $cellH - 12) -Content ([string]$level) -Fill $Skin['ink'] -Size 10 -Anchor 'middle'
            $rows += , @($rowsSpec[$r], $colsSpec[$c], $levelName[[Math]::Min($level, 3)])
        }
    }
    return New-Result -Title $Spec.title -Description "DP security matrix: $($Spec.title)" -Width $w -Height $h `
        -Svg ($svg -join "`n") -TableHeaders @('Data classification', 'Control', 'Risk level') -TableRows $rows
}

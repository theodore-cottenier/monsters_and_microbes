$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$data = Get-Content (Join-Path $PSScriptRoot 'relationships.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$bitmap = New-Object System.Drawing.Bitmap(2304,1830)
$g = [System.Drawing.Graphics]::FromImage($bitmap)
$g.ScaleTransform(1.5,1.5)
$g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'
$paper = [System.Drawing.ColorTranslator]::FromHtml('#f8f1e2')
$g.Clear($paper)
$colors = @{benefit='#32744b'; predation='#c27708'; parasitism='#b13b32'; infection='#744da0'; transport='#216da4'}
function Draw-Text([string]$value, [single]$x, [single]$baseline, [single]$size, [string]$color='#292d2a', [string]$style='Regular', [bool]$halo=$false, [string]$family='Georgia') {
    $font = New-Object System.Drawing.Font($family,$size,([System.Drawing.FontStyle]::$style),([System.Drawing.GraphicsUnit]::Pixel))
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($color))
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = 'Center'
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $point = New-Object System.Drawing.PointF($x,($baseline-$size*1.04))
    $path.AddString($value,$font.FontFamily,[int]$font.Style,$size,$point,$format)
    if ($halo) {
        $outline = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#fcf6e8'),5)
        $outline.LineJoin = 'Round'
        $g.DrawPath($outline,$path)
        $outline.Dispose()
    }
    $g.FillPath($brush,$path)
    $path.Dispose(); $font.Dispose(); $brush.Dispose(); $format.Dispose()
}
function Draw-Arrow($path, [string]$type) {
    $under = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(205,255,248,232),6)
    $g.DrawPath($under,$path)
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($colors[$type]),3)
    if ($type -eq 'parasitism') { $pen.DashPattern = @(2.7,2) }
    if ($type -eq 'infection') { $pen.DashPattern = @(0.7,2.3) }
    $cap = New-Object System.Drawing.Drawing2D.AdjustableArrowCap(5,6,$true)
    $pen.CustomEndCap = $cap
    $g.DrawPath($pen,$path)
    $pen.Dispose(); $under.Dispose(); $cap.Dispose()
}
Draw-Text 'HydroSalts - A Living Vent Food Web' 768 42 36 '#292d2a' 'Bold'
Draw-Text 'Hot sulfur channels  /  Living matrix terraces  /  Cold brine and abandoned fissures' 768 70 16
$g.TranslateTransform(0,82)
$art = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot 'vent_habitat.png'))
$g.DrawImage($art,0,0,1536,1024)
foreach ($edge in $data.relationships) {
    $tokens = [regex]::Matches($edge.path,'[MC]|-?\d+(?:\.\d+)?') | ForEach-Object { $_.Value }
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    [single]$px = $tokens[1]; [single]$py = $tokens[2]
    $i = 3
    while ($i -lt $tokens.Count) {
        if ($tokens[$i] -ne 'C') { throw 'Unsupported path command' }
        $p.AddBezier($px,$py,[single]$tokens[$i+1],[single]$tokens[$i+2],[single]$tokens[$i+3],[single]$tokens[$i+4],[single]$tokens[$i+5],[single]$tokens[$i+6])
        $px = $tokens[$i+5]; $py = $tokens[$i+6]; $i += 7
    }
    Draw-Arrow $p $edge.type
    Draw-Text $edge.id $edge.x $edge.y 12 $colors[$edge.type] 'Bold' $true 'Arial'
    $p.Dispose()
}
foreach ($node in $data.nodes) {
    Draw-Text ($node.id + ' ' + $node.name) $node.x $node.y 18 '#292d2a' 'Bold' $true
    Draw-Text $node.species $node.x $node.latinY 15 '#292d2a' 'Italic' $true
}
$g.TranslateTransform(0,-82)
$brush = New-Object System.Drawing.SolidBrush($paper)
$g.FillRectangle($brush,0,1108,1536,112)
$line = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#867c64'),1)
$g.DrawLine($line,32,1110,1504,1110)
$kinds = @('benefit','predation','parasitism','infection','transport')
$labels = @('Beneficial exchange','Predation','Parasitism','Viral infection','Commensal transport')
for ($j=0; $j -lt 5; $j++) {
    $x = 42 + $j*300
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddLine($x,1137,($x+35),1137)
    Draw-Arrow $p $kinds[$j]
    Draw-Text $labels[$j] ($x+140) 1143 16
    $p.Dispose()
}
Draw-Text 'Exchange: provider to recipient. Predation / parasitism / infection: attacker to target. E01-E20: see relationship table.' 768 1176 16
Draw-Text 'Speculative ecosystem / Organisms enlarged, not to scale / 15 organisms, 20 relationships, 18 links independent of the tick' 768 1202 14 '#292d2a' 'Italic'
$output = Join-Path $PSScriptRoot 'symbiosis_map.png'
$bitmap.Save($output,[System.Drawing.Imaging.ImageFormat]::Png)
$art.Dispose(); $brush.Dispose(); $line.Dispose(); $g.Dispose(); $bitmap.Dispose()
Write-Output "Rendered $output"

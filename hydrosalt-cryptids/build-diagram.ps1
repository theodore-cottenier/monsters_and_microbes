$ErrorActionPreference = "Stop"
$templatePath = Join-Path $PSScriptRoot "symbiosis_map.template.svg"
$artPath = Join-Path $PSScriptRoot "vent_habitat.png"
$outputPath = Join-Path $PSScriptRoot "symbiosis_map.svg"
$template = [IO.File]::ReadAllText($templatePath)
$art = [Convert]::ToBase64String([IO.File]::ReadAllBytes($artPath))
$svg = $template.Replace("__EMBEDDED_HABITAT__", "data:image/png;base64," + $art)
$null = [xml]$svg
[IO.File]::WriteAllText($outputPath, $svg, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Built $outputPath"

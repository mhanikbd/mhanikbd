<#
  Turns any portrait photo into assets/source/profile-photo.jpg: a centered
  square crop, 360x360, JPEG quality 86 (about 25-45 KB). The hero banner
  embeds this file, so keeping it small keeps the banner fast.

  Windows only (uses System.Drawing):
    powershell -ExecutionPolicy Bypass -File tools/prepare-photo.ps1 -Path "C:\path\to\photo.jpg"
  Optional: -FocusY 0.35 moves the crop up (0 = top, 0.5 = center) to keep the face in frame.
  Then run tools/build-assets.ps1 (or push: the workflow rebuilds the banner).
#>
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [double]$FocusY = 0.4,
    [int]$Size = 360,
    [int]$Quality = 86
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'assets/source/profile-photo.jpg'
New-Item -ItemType Directory -Force (Split-Path -Parent $out) | Out-Null

$src = [System.Drawing.Image]::FromFile((Resolve-Path $Path).Path)
try {
    $side = [math]::Min($src.Width, $src.Height)
    $sx = [int](($src.Width - $side) / 2)
    $sy = [int][math]::Max(0, [math]::Min($src.Height - $side, ($src.Height - $side) * $FocusY * 2))
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)), (New-Object System.Drawing.Rectangle($sx, $sy, $side, $side)), [System.Drawing.GraphicsUnit]::Pixel)
    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
    $bmp.Save($out, $codec, $ep)
    $g.Dispose(); $bmp.Dispose()
} finally { $src.Dispose() }
Write-Host ("Saved {0} ({1:N0} bytes)" -f $out, (Get-Item $out).Length)

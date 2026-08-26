Add-Type -AssemblyName System.Drawing

# Icono: cuadrado burdeos con un documento y sus cláusulas (líneas de texto)
function New-Icon([int]$size, [string]$path, [bool]$rounded, [double]$pad) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $bg = [System.Drawing.Color]::FromArgb(255, 125, 42, 47)   # #7d2a2f burdeos
  $brush = New-Object System.Drawing.SolidBrush $bg

  if ($rounded) {
    $r = $size * 0.22
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc(0, 0, $d, $d, 180, 90)
    $p.AddArc($size - $d, 0, $d, $d, 270, 90)
    $p.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
    $p.AddArc(0, $size - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    $g.FillPath($brush, $p)
  } else {
    $g.FillRectangle($brush, 0, 0, $size, $size)
  }

  # Lienzo interior de 100x100 unidades
  $inner = $size * (1 - $pad * 2)
  $ox = $size * $pad
  $oy = $size * $pad
  $s  = $inner / 100.0

  $papel = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 254, 251))
  $tinta = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 125, 42, 47))

  # Hoja de contrato con la esquina superior derecha doblada
  $hoja = New-Object System.Drawing.Drawing2D.GraphicsPath
  $hoja.AddLine($ox + 20*$s, $oy + 10*$s, $ox + 63*$s, $oy + 10*$s)
  $hoja.AddLine($ox + 63*$s, $oy + 10*$s, $ox + 80*$s, $oy + 27*$s)
  $hoja.AddLine($ox + 80*$s, $oy + 27*$s, $ox + 80*$s, $oy + 90*$s)
  $hoja.AddLine($ox + 80*$s, $oy + 90*$s, $ox + 20*$s, $oy + 90*$s)
  $hoja.CloseFigure()
  $g.FillPath($papel, $hoja)

  # Pliegue de la esquina
  $pliegue = New-Object System.Drawing.Drawing2D.GraphicsPath
  $pliegue.AddLine($ox + 63*$s, $oy + 10*$s, $ox + 63*$s, $oy + 27*$s)
  $pliegue.AddLine($ox + 63*$s, $oy + 27*$s, $ox + 80*$s, $oy + 27*$s)
  $pliegue.CloseFigure()
  $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 125, 42, 47))), $pliegue)

  # Cláusulas: líneas de texto, la tercera resaltada
  $lineas = @(
    @(30, 40, 40), @(30, 50, 40), @(30, 60, 26), @(30, 70, 40)
  )
  foreach ($l in $lineas) {
    $x = $ox + $l[0]*$s; $y = $oy + $l[1]*$s; $w = $l[2]*$s; $h = 5*$s
    $g.FillRectangle($tinta, $x, $y, $w, $h)
  }

  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host "  -> $path"
}

$dir = Join-Path $PSScriptRoot "icons"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

New-Icon 192 (Join-Path $dir "icon-192.png")          $true  0.10
New-Icon 512 (Join-Path $dir "icon-512.png")          $true  0.10
New-Icon 512 (Join-Path $dir "icon-512-maskable.png") $false 0.20
New-Icon 180 (Join-Path $dir "apple-touch-icon.png")  $false 0.10
New-Icon 32  (Join-Path $dir "favicon-32.png")        $false 0.06
Write-Host "Iconos generados."

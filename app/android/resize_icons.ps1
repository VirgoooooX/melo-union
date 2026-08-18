Add-Type -AssemblyName System.Drawing

$meloLogoPath = "l:\Web\Melo-union\app\assets\images\melo_logo.png"
$src = [System.Drawing.Bitmap]::FromFile($meloLogoPath)
$w = $src.Width
$h = $src.Height

# Step 1: Create pure white + light-cyan logo on transparent background
$fgLogo = New-Object System.Drawing.Bitmap($w, $h)
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $p = $src.GetPixel($x, $y)
        if ($p.A -eq 0) {
            $fgLogo.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            continue
        }
        if ($p.R -lt 70) {
            # Note -> White with original alpha
            $fgLogo.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p.A, 255, 255, 255))
        } else {
            # Bars -> Light cyan (#CFF3EE) with original alpha
            $fgLogo.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p.A, 207, 243, 238))
        }
    }
}
$src.Dispose()

$resBase = "l:\Web\Melo-union\app\android\app\src\main\res"

$densities = @(
    @{Name="mdpi";    Adaptive=108; Safe=70;  Legacy=48},
    @{Name="hdpi";    Adaptive=162; Safe=105; Legacy=72},
    @{Name="xhdpi";   Adaptive=216; Safe=140; Legacy=96},
    @{Name="xxhdpi";  Adaptive=324; Safe=210; Legacy=144},
    @{Name="xxxhdpi"; Adaptive=432; Safe=280; Legacy=192}
)

function Get-RoundedRectPath([System.Drawing.RectangleF]$rect, [float]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $arc = New-Object System.Drawing.RectangleF($rect.X, $rect.Y, $diameter, $diameter)
    
    # Top-Left
    $path.AddArc($arc, 180, 90)
    # Top-Right
    $arc.X = $rect.Right - $diameter
    $path.AddArc($arc, 270, 90)
    # Bottom-Right
    $arc.Y = $rect.Bottom - $diameter
    $path.AddArc($arc, 0, 90)
    # Bottom-Left
    $arc.X = $rect.Left
    $path.AddArc($arc, 90, 90)
    $path.CloseFigure()
    return $path
}

$brandGreen = [System.Drawing.Color]::FromArgb(255, 10, 166, 154)

foreach ($d in $densities) {
    $densityName = $d["Name"]
    $full = $d["Adaptive"]
    $safe = $d["Safe"]
    $leg = $d["Legacy"]

    # 1. Adaptive Foreground (ic_launcher_foreground.png)
    $bmpFg = New-Object System.Drawing.Bitmap($full, $full)
    $g = [System.Drawing.Graphics]::FromImage($bmpFg)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

    $scale = [Math]::Min($safe / $w, $safe / $h)
    $dw = [int]($w * $scale)
    $dh = [int]($h * $scale)
    $dx = [int](($full - $dw) / 2)
    $dy = [int](($full - $dh) / 2)
    $g.DrawImage($fgLogo, $dx, $dy, $dw, $dh)
    $g.Dispose()

    $targetDir = "$resBase\mipmap-$densityName"
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $fgPath = "$targetDir\ic_launcher_foreground.png"
    $bmpFg.Save($fgPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpFg.Dispose()

    # 2. Legacy Icon (ic_launcher.png) - Rounded square with brand green background
    $bmpLeg = New-Object System.Drawing.Bitmap($leg, $leg)
    $gLeg = [System.Drawing.Graphics]::FromImage($bmpLeg)
    $gLeg.Clear([System.Drawing.Color]::Transparent)
    $gLeg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gLeg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

    $rect = New-Object System.Drawing.RectangleF(0, 0, $leg, $leg)
    $rPath = Get-RoundedRectPath $rect ($leg * 0.22)
    $brush = New-Object System.Drawing.SolidBrush($brandGreen)
    $gLeg.FillPath($brush, $rPath)
    $brush.Dispose()
    $rPath.Dispose()

    $scaleLeg = [Math]::Min(($leg * 0.72) / $w, ($leg * 0.72) / $h)
    $lw = [int]($w * $scaleLeg)
    $lh = [int]($h * $scaleLeg)
    $lx = [int](($leg - $lw) / 2)
    $ly = [int](($leg - $lh) / 2)
    $gLeg.DrawImage($fgLogo, $lx, $ly, $lw, $lh)
    $gLeg.Dispose()

    $legPath = "$targetDir\ic_launcher.png"
    $bmpLeg.Save($legPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpLeg.Dispose()

    # 3. Launch Image (launch_image.png)
    $bmpLaunch = New-Object System.Drawing.Bitmap($full, $full)
    $gL = [System.Drawing.Graphics]::FromImage($bmpLaunch)
    $gL.Clear([System.Drawing.Color]::Transparent)
    $gL.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gL.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

    $launchScale = [Math]::Min(($full * 0.65) / $w, ($full * 0.65) / $h)
    $lw2 = [int]($w * $launchScale)
    $lh2 = [int]($h * $launchScale)
    $lx2 = [int](($full - $lw2) / 2)
    $ly2 = [int](($full - $lh2) / 2)
    $gL.DrawImage($fgLogo, $lx2, $ly2, $lw2, $lh2)
    $gL.Dispose()

    $launchPath = "$targetDir\launch_image.png"
    $bmpLaunch.Save($launchPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpLaunch.Dispose()

    Write-Host "Generated mipmap-$densityName (Adaptive=${full}x${full}, Safe=${dw}x${dh}, Legacy=${leg}x${leg})"
}

$fgLogo.Dispose()
Write-Host "Done generating Android icon assets!"
Add-Type -AssemblyName System.Drawing

$src = "l:\Web\Melo-union\app\assets\images\melo_logo_inverse.png"
$sourceImg = [System.Drawing.Image]::FromFile($src)
$resBase = "l:\Web\Melo-union\app\android\app\src\main\res"

$dList = @(
    @{Name="mdpi";    Full=108; Safe=72},
    @{Name="hdpi";    Full=162; Safe=108},
    @{Name="xhdpi";   Full=216; Safe=144},
    @{Name="xxhdpi";  Full=324; Safe=216},
    @{Name="xxxhdpi"; Full=432; Safe=288}
)

Write-Host "--- App icon foregrounds ---"
foreach ($d in $dList) {
    $full = $d.Full; $safe = $d.Safe
    $bmp = New-Object System.Drawing.Bitmap($full, $full)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $scale = [Math]::Min($safe / $sourceImg.Width, $safe / $sourceImg.Height)
    $w = [int]($sourceImg.Width * $scale)
    $h = [int]($sourceImg.Height * $scale)
    $x = ($full - $w) / 2; $y = ($full - $h) / 2
    $g.DrawImage($sourceImg, $x, $y, $w, $h)
    $g.Dispose()

    $path = "$resBase\mipmap-$($d.Name)\ic_launcher_foreground.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "$($d.Name): canvas=$($full)x$($full), logo=$($w)x$($h)"
}

Write-Host "--- Launch images ---"
foreach ($d in $dList) {
    $full = $d.Full
    $target = [int]($full * 0.85)

    $bmp = New-Object System.Drawing.Bitmap($full, $full)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $scale = [Math]::Min($target / $sourceImg.Width, $target / $sourceImg.Height)
    $w = [int]($sourceImg.Width * $scale)
    $h = [int]($sourceImg.Height * $scale)
    $x = ($full - $w) / 2; $y = ($full - $h) / 2
    $g.DrawImage($sourceImg, $x, $y, $w, $h)
    $g.Dispose()

    $path = "$resBase\mipmap-$($d.Name)\launch_image.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "$($d.Name): canvas=$($full)x$($full), logo=$($w)x$($h)"
}

$sourceImg.Dispose()
Write-Host "Done!"
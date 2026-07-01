param(
    [string] $Version,
    [string] $Platform = "all", # "all", "windows", "android"
    [string] $Remote = "origin",
    [switch] $NoPush
)

$ErrorActionPreference = "Stop"

# Check if git working directory is clean
$status = git status --porcelain
if ($status) {
    throw "Git working directory is not clean. Please commit or stash changes first."
}

# If Version is not supplied, prompt for it
if (-not $Version) {
    $Version = Read-Host "Enter new version (e.g., 1.0.2+3)"
    if (-not $Version) {
        throw "Version cannot be empty."
    }
}

$Version = $Version.TrimStart("v")
# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+\+\d+$') {
    Write-Warning "Version format should be major.minor.patch+build (e.g. 1.0.0+1)"
    $confirm = Read-Host "Proceed anyway? (y/n)"
    if ($confirm -ne "y") {
        throw "Version format validation failed."
    }
}

# Update app/pubspec.yaml
$pubspecPath = "app/pubspec.yaml"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    $newContent = $content -replace '(?m)^version:\s+\S+', "version: $Version"
    Set-Content $pubspecPath $newContent -NoNewline
    Write-Host "Updated $pubspecPath to version: $Version"
} else {
    throw "Could not find $pubspecPath"
}

# Update app/lib/src/bootstrap/app_version.dart
$versionPath = "app/lib/src/bootstrap/app_version.dart"
if (Test-Path $versionPath) {
    $versionContent = "const String appVersion = '$Version';`n"
    Set-Content $versionPath $versionContent -NoNewline
    Write-Host "Updated $versionPath to version: $Version"
} else {
    throw "Could not find $versionPath"
}

# Normalize and validate Platform
$Platform = $Platform.ToLower()
if ($Platform -notmatch '^(all|windows|android)$') {
    if ($Platform) {
        Write-Warning "Invalid platform specified: $Platform. Must be all, windows, or android."
    }
    $Platform = ""
}

# If Platform is empty/not specified, prompt for it
if (-not $Platform) {
    Write-Host "Select release target:"
    Write-Host "  1. All (Android & Windows)"
    Write-Host "  2. Windows Only"
    Write-Host "  3. Android Only"
    $targetChoice = Read-Host "Choice (1-3) [default: 1]"
    if ($targetChoice -eq "2") {
        $Platform = "windows"
    } elseif ($targetChoice -eq "3") {
        $Platform = "android"
    } else {
        $Platform = "all"
    }
}

Write-Host "Target platform: $Platform"

# Commit, Tag, Push
$tagBase = "v$($Version.Split('+')[0])"
$tag = $tagBase
Write-Host "Creating Git Commit and Tag: $tag (platform=$Platform)"

git add $pubspecPath $versionPath
$staged = git diff --cached --name-only
if ($staged) {
    git commit -m "chore: bump version to $Version"
} else {
    git commit --allow-empty -m "chore: bump version to $Version"
}

# Tag with platform metadata annotation
git tag -a $tag -f -m "Release $tag" -m "platform=$Platform"

if (-not $NoPush) {
    # Check if we are running in interactive mode (i.e. Version wasn't passed as a parameter)
    $isInteractive = -not $MyInvocation.BoundParameters.ContainsKey('Version')
    
    $doPush = $true
    if ($isInteractive) {
        $pushChoice = Read-Host "Push to $Remote and tag now? (y/n) [default: y]"
        if ($pushChoice -eq "n") {
            $doPush = $false
        }
    }
    
    if ($doPush) {
        git push $Remote HEAD
        git push $Remote $tag -f
        Write-Host "Pushed successfully! GitHub Action will now compile and release $tag."
    } else {
        Write-Host "Tag created locally. You can push manually using:"
        Write-Host "  git push $Remote HEAD && git push $Remote $tag"
    }
} else {
    Write-Host "Tag created locally. Push is skipped due to -NoPush switch."
    Write-Host "You can push manually using:"
    Write-Host "  git push $Remote HEAD && git push $Remote $tag"
}


# Check if git working directory is clean
$status = git status --porcelain
if ($status) {
    Write-Error "Git working directory is not clean. Please commit or stash changes first."
    exit 1
}

# Prompt for version
$version = Read-Host "Enter new version (e.g., 1.0.2+3)"
if (-not $version) {
    Write-Error "Version cannot be empty."
    exit 1
}

# Validate version format
if ($version -notmatch '^\d+\.\d+\.\d+\+\d+$') {
    Write-Warning "Version format should be major.minor.patch+build (e.g. 1.0.0+1)"
    $confirm = Read-Host "Proceed anyway? (y/n)"
    if ($confirm -ne "y") { exit 1 }
}

# Update app/pubspec.yaml
$pubspecPath = "app/pubspec.yaml"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw
    $newContent = $content -replace '(?m)^version:\s+\S+', "version: $version"
    Set-Content $pubspecPath $newContent -NoNewline
    Write-Host "Updated $pubspecPath to version: $version"
} else {
    Write-Error "Could not find $pubspecPath"
    exit 1
}

# Prompt for platform target
Write-Host "Select release target:"
Write-Host "  1. All (Android & Windows)"
Write-Host "  2. Windows Only"
Write-Host "  3. Android Only"
$targetChoice = Read-Host "Choice (1-3) [default: 1]"
if (-not $targetChoice) { $targetChoice = "1" }

$tagSuffix = ""
if ($targetChoice -eq "2") {
    $tagSuffix = "-windows"
    Write-Host "Target: Windows Only"
} elseif ($targetChoice -eq "3") {
    $tagSuffix = "-android"
    Write-Host "Target: Android Only"
} else {
    Write-Host "Target: All platforms"
}

# Commit, Tag, Push
$tagBase = "v$($version.Split('+')[0])"
$tag = "$tagBase$tagSuffix"
Write-Host "Creating Git Commit and Tag: $tag"
git add $pubspecPath
git commit -m "chore: bump version to $version"
git tag -a $tag -m "Release $tag"

Write-Host "Ready to push changes and tag to trigger GitHub Action release."
$push = Read-Host "Push to origin main and tag now? (y/n)"
if ($push -eq "y") {
    git push origin main
    git push origin $tag
    Write-Host "Pushed successfully! GitHub Action will now compile and release $tag."
} else {
    Write-Host "Tag created locally. You can push manually using:"
    Write-Host "  git push origin main && git push origin $tag"
}

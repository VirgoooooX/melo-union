#!/bin/bash
set -e

# Check git clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Git working directory is not clean. Please commit or stash changes first."
    exit 1
fi

# Prompt for version
read -p "Enter new version (e.g., 1.0.2+3): " version
if [ -z "$version" ]; then
    echo "Error: Version cannot be empty."
    exit 1
fi

# Update app/pubspec.yaml
pubspec_path="app/pubspec.yaml"
if [ -f "$pubspec_path" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version:.*/version: $version/" "$pubspec_path"
    else
        sed -i "s/^version:.*/version: $version/" "$pubspec_path"
    fi
    echo "Updated $pubspec_path to version: $version"
else
    echo "Error: Could not find $pubspec_path"
    exit 1
fi

# Prompt for platform target
echo "Select release target:"
echo "  1. All (Android & Windows)"
echo "  2. Windows Only"
echo "  3. Android Only"
read -p "Choice (1-3) [default: 1]: " target_choice
target_choice=${target_choice:-1}

tag_suffix=""
if [ "$target_choice" = "2" ]; then
    tag_suffix="-windows"
    echo "Target: Windows Only"
elif [ "$target_choice" = "3" ]; then
    tag_suffix="-android"
    echo "Target: Android Only"
else
    echo "Target: All platforms"
fi

# Git ops
tag_version=$(echo "$version" | cut -d'+' -f1)
tag="v$tag_version$tag_suffix"

git add "$pubspec_path"
git commit -m "chore: bump version to $version"
git tag -a "$tag" -m "Release $tag"
echo "Created commit and tag: $tag"

read -p "Push to origin main and tag now? (y/n): " push
if [ "$push" = "y" ] || [ "$push" = "Y" ]; then
    git push origin main
    git push origin "$tag"
    echo "Pushed successfully! GitHub Action release flow triggered."
else
    echo "Tag created locally. Push manually using: git push origin main && git push origin $tag"
fi

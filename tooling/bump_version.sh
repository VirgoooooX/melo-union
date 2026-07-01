#!/bin/bash
set -e

# Parse arguments
VERSION=""
PLATFORM=""
REMOTE="origin"
NOPUSH=false
IS_INTERACTIVE=true

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--version) VERSION="$2"; IS_INTERACTIVE=false; shift ;;
        -p|--platform) PLATFORM="$2"; shift ;;
        -r|--remote) REMOTE="$2"; shift ;;
        --no-push) NOPUSH=true ;;
        *) echo "Error: Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check git clean
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Git working directory is not clean. Please commit or stash changes first."
    exit 1
fi

# Prompt for version if not provided
if [ -z "$VERSION" ]; then
    read -p "Enter new version (e.g., 1.0.2+3): " VERSION
    if [ -z "$VERSION" ]; then
        echo "Error: Version cannot be empty."
        exit 1
    fi
fi

# Clean leading 'v'
VERSION="${VERSION#v}"

# Update app/pubspec.yaml
pubspec_path="app/pubspec.yaml"
if [ -f "$pubspec_path" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version:.*/version: $VERSION/" "$pubspec_path"
    else
        sed -i "s/^version:.*/version: $VERSION/" "$pubspec_path"
    fi
    echo "Updated $pubspec_path to version: $VERSION"
else
    echo "Error: Could not find $pubspec_path"
    exit 1
fi

# Update app/lib/src/bootstrap/app_version.dart
version_path="app/lib/src/bootstrap/app_version.dart"
if [ -f "$version_path" ]; then
    display_version=$(echo "$VERSION" | cut -d'+' -f1)
    echo -e "const String appVersion = '$VERSION';\nconst String appDisplayVersion = '$display_version';" > "$version_path"
    echo "Updated $version_path to version: $VERSION (display: $display_version)"
else
    echo "Error: Could not find $version_path"
    exit 1
fi

# Validate and normalize PLATFORM
PLATFORM=$(echo "$PLATFORM" | tr '[:upper:]' '[:lower:]')
if [[ "$PLATFORM" != "all" && "$PLATFORM" != "windows" && "$PLATFORM" != "android" ]]; then
    if [ -n "$PLATFORM" ]; then
        echo "Warning: Invalid platform '$PLATFORM' specified. Must be 'all', 'windows', or 'android'."
    fi
    PLATFORM=""
fi

# Prompt for platform target if not provided
if [ -z "$PLATFORM" ]; then
    echo "Select release target:"
    echo "  1. All (Android & Windows)"
    echo "  2. Windows Only"
    echo "  3. Android Only"
    read -p "Choice (1-3) [default: 1]: " target_choice
    target_choice=${target_choice:-1}
    if [ "$target_choice" = "2" ]; then
        PLATFORM="windows"
    elif [ "$target_choice" = "3" ]; then
        PLATFORM="android"
    else
        PLATFORM="all"
    fi
fi

echo "Target platform: $PLATFORM"

# Git ops
tag_version=$(echo "$VERSION" | cut -d'+' -f1)
tag="v$tag_version"

echo "Creating Git Commit and Tag: $tag (platform=$PLATFORM)"
git add "$pubspec_path" "$version_path"

if [ -n "$(git diff --cached --name-only)" ]; then
    git commit -m "chore: bump version to $VERSION"
else
    git commit --allow-empty -m "chore: bump version to $VERSION"
fi

# Tag with platform metadata annotation
git tag -a "$tag" -f -m "Release $tag" -m "platform=$PLATFORM"
echo "Created commit and tag: $tag"

if [ "$NOPUSH" = false ]; then
    do_push=true
    if [ "$IS_INTERACTIVE" = true ]; then
        read -p "Push to $REMOTE and tag now? (y/n) [default: y]: " push_choice
        push_choice=${push_choice:-y}
        if [[ "$push_choice" != "y" && "$push_choice" != "Y" ]]; then
            do_push=false
        fi
    fi
    
    if [ "$do_push" = true ]; then
        git push "$REMOTE" HEAD
        git push "$REMOTE" "$tag" -f
        echo "Pushed successfully! GitHub Action release flow triggered."
    else
        echo "Tag created locally. Push manually using: git push $REMOTE HEAD && git push $REMOTE $tag"
    fi
else
    echo "Tag created locally. Push skipped due to --no-push."
    echo "You can push manually using: git push $REMOTE HEAD && git push $REMOTE $tag"
fi

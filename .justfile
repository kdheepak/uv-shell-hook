# List available commands
[private]
default:
    @just --list

# Get the next version based on bump type
next-version type="patch":
    #!/usr/bin/env bash
    set -euo pipefail

    latest_tag=$(gh release list --limit 1 --json tagName --jq '.[0].tagName // "v0.0.0"')
    version=${latest_tag#v}
    IFS='.' read -r major minor patch <<< "$version"

    case "{{type}}" in
        major)
            major=$((major + 1)); minor=0; patch=0 ;;
        minor)
            minor=$((minor + 1)); patch=0 ;;
        patch)
            patch=$((patch + 1)) ;;
        *)
            echo "Error: Invalid bump type '{{type}}'. Use: major, minor, or patch"; exit 1 ;;
    esac

    echo "v${major}.${minor}.${patch}"

# Bump version and tag it
bump type="patch":
    #!/usr/bin/env bash
    set -euo pipefail

    new_version=$(just next-version {{type}})
    echo "New version: $new_version"

    git commit --allow-empty -m "Bump version to $new_version"
    git tag "$new_version"

    echo "✓ Created commit and tag for $new_version"
    echo "  Run: just release version=$new_version"

# Push commit, tag, and create GitHub release
release version:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Pushing commit and tag for $version..."
    git push
    git push origin "$version"

    echo "Creating GitHub release for $version..."
    gh release create "$version" --title "$version" --generate-notes

    echo "✓ Release $version created and pushed"

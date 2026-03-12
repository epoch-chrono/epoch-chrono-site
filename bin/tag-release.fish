#!/usr/bin/env fish
# bin/tag-release.fish — cria e faz push de uma git tag semver
# Uso: ./bin/tag-release.fish [major|minor|patch]
# Default: patch

set bump_type (test (count $argv) -gt 0; and echo $argv[1]; or echo "patch")

# Pegar versão atual do package.json
set current (node -p "require('./package.json').version" 2>/dev/null; or echo "0.0.0")
set parts (string split "." $current)
set major $parts[1]
set minor $parts[2]
set patch $parts[3]

switch $bump_type
  case "major"
    set major (math $major + 1)
    set minor 0
    set patch 0
  case "minor"
    set minor (math $minor + 1)
    set patch 0
  case "patch"
    set patch (math $patch + 1)
  case "*"
    echo "Uso: tag-release.fish [major|minor|patch]"
    exit 1
end

set new_version "$major.$minor.$patch"
set tag "v$new_version"

# Atualizar package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json'));
pkg.version = '$new_version';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

git add package.json
git commit -m "chore: bump epochVersion to $tag"
git tag -a $tag -m "Release $tag"
git push origin main
git push origin $tag

echo "✓ Released $tag"

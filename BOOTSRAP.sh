#!/usr/bin/env zsh

set -e # abort when any command errors, prevents this script from self-removing at the end if anything went wrong

# plugin name is the same as the git repo name and can therefore be inferred
repo=$(git remote -v | head -n1 | sed 's/\.git.*//' | sed 's/.*://')
name=$(echo "$repo" | cut -d/ -f2)
name_short=$(echo "$name" | cut -d"-" -f2)

# desc can be inferred from github description (not using jq for portability)
desc=$(curl -sL "https://api.github.com/repos/$repo" | grep "description" | head -n1 | cut -d'"' -f4)

# current year for license
year=$(date +"%Y")

#───────────────────────────────────────────────────────────────────────────────

# replace them all
# $1: placeholder name as {{mustache-template}}
# $2: the replacement
function replacePlaceholders() {
	LC_ALL=C # prevent byte sequence error
	# INFO macOS' sed requires `sed -i ''`, remove the `''` when on Linux or using GNU sed
	find . -type f -not -path '*/\.git/*' -not -name ".DS_Store" -not -path '*/node_modules/*' -exec sed -i '' "s/{{$1}}/$2/g" {} \;
}

replacePlaceholders "plugin-name" "$name"
replacePlaceholders "plugin-desc" "$desc"
replacePlaceholders "year" "$year"

# for panvimdoc
replacePlaceholders "plugin-short-name" "$name_short"
mkdir -p ".doc/"
touch "./doc/$name_short.txt" 

osascript -e 'display notification "" with title "ℹ️ Write Permissions for workflow needed."'
open -a "https://github.com/$repo/settings/actions"

#───────────────────────────────────────────────────────────────────────────────

# make this script delete itself
rm -- "$0"

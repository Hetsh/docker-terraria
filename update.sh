#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Debian Stable
IMG_CHANNEL="stable"
update_image "library/debian" "Debian" "false" "$IMG_CHANNEL-\d+-slim"

# Terraria Server
CURRENT_APP_VERSION="${_CURRENT_VERSION%-*}"
MIRROR="https://terraria.org"
VERSION_REGEX="\d{4}"
DOWNLOAD_URI=$(curl --silent --location "$MIRROR" | grep -P -o "(?<=href=.).*$VERSION_REGEX\.zip")
NEW_APP_VERSION=$(echo $DOWNLOAD_URI | grep -P -o "$VERSION_REGEX(?=.zip)" | sed 's|.|&\.|g' | sed 's|\.$||')
if [ "$CURRENT_APP_VERSION" != "$NEW_APP_VERSION" ]; then
	prepare_update "" "Terraria Server" "$CURRENT_APP_VERSION" "$NEW_APP_VERSION"
	update_version "$NEW_APP_VERSION"

	# Since the terraria server is not a regular package, the version number needs
	# to be replaced with the url to download the archive
	_UPDATES[-3]="APP_URL"
	_UPDATES[-2]="\".*\""
	_UPDATES[-1]="\"${MIRROR}${DOWNLOAD_URI}\""
fi

# Packages
PKG_URL="https://packages.debian.org/$IMG_CHANNEL/amd64"
update_pkg "unzip" "Unzip" "false" "$PKG_URL" "\d+\.\d+-\d+\+deb\d+u\d+"

if ! updates_available; then
	#echo "No updates available."
	exit 0
fi

# Perform modifications
if [ "${1-}" = "--noconfirm" ] || confirm_action "Save changes?"; then
	save_changes

	if [ "${1-}" = "--noconfirm" ] || confirm_action "Commit changes?"; then
		commit_changes
	fi
fi
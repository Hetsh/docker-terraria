#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

update_custom() {
	local ID="$1"
	local NAME="$2"
	local MAIN="$3"
	local MIRROR="$4"
	local URL_REGEX="$5"
	local VERSION_REGEX="$6"

	local CURRENT_URL=$(cat Dockerfile | grep --only-matching --perl-regexp "(?<=$ID=\").*(?=\")")
	local NEW_URL=$(curl --silent --location "$MIRROR" | grep --only-matching --perl-regexp "$URL_REGEX")
	if [ -z "$CURRENT_URL" ] || [ -z "$NEW_URL" ]; then
		echo -e "\e[31mFailed to scrape $NAME URL!\e[0m"
		return
	fi

	# Convert to URI
	if [ "${NEW_URL:0:4}" == "http" ]; then
		# Already URI
		true
	elif [ "${NEW_URL:0:1}" == '/' ]; then
		# Absolute path
		ROOT=$(echo "$MIRROR" | grep --only-matching --perl-regexp "http(s)?:\/\/[^\/]+")
		NEW_URL="${ROOT}$NEW_URL"
	else
		# Relative path
		NEW_URL="$MIRROR/$NEW_URL"
	fi

	local CURRENT_VERSION=$(echo "$CURRENT_URL" | grep --only-matching --perl-regexp "$VERSION_REGEX" | sed 's|.|&\.|g' | sed 's|\.$||')
	local NEW_VERSION=$(echo "$NEW_URL" | grep --only-matching --perl-regexp "$VERSION_REGEX" | sed 's|.|&\.|g' | sed 's|\.$||')
	if [ -z "$CURRENT_VERSION" ] || [ -z "$NEW_VERSION" ]; then
		echo -e "\e[31mFailed to scrape $NAME version!\e[0m"
		return
	fi

	if [ "$CURRENT_URL" != "$NEW_URL" ]; then
		prepare_update "$ID" "$NAME" "$CURRENT_VERSION" "$NEW_VERSION" "$CURRENT_URL" "$NEW_URL"

		if [ "$MAIN" = "true" ] && [ "${CURRENT_VERSION%-*}" != "${NEW_VERSION%-*}" ]; then
			update_version "$NEW_VERSION"
		else
			update_release
		fi
	fi
}

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Debian Stable
IMG_CHANNEL="stable"
update_image "library/debian" "Debian" "false" "$IMG_CHANNEL-\d+-slim"

# Packages
PKG_URL="https://packages.debian.org/$IMG_CHANNEL/amd64"
update_pkg "unzip" "Unzip" "false" "$PKG_URL" "\d+\.\d+-\d+\+deb\d+u\d+"

# Terraria Server
update_custom "APP_URL" "Terraria Server" "true" "https://terraria.org" "(?<=href=(\"|')).*/terraria-server-\d{4}\.zip" "\d{4}(?=.zip)"

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
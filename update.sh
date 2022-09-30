#!/usr/bin/env bash


# Abort on any error
set -e -u

# Simpler git usage, relative file paths
CWD=$(dirname "$0")
cd "$CWD"

# Load helpful functions
source libs/common.sh
source libs/docker.sh

# Check for update on GitHub
update_custom() {
	local ID="$1"
	local NAME="$2"
	local MIRROR="https://terraria.org/api/get/dedicated-servers-names"
	local VERSION_REGEX="\d+"

	local CURRENT_VERSION=$(cat Dockerfile | grep --only-matching --perl-regexp "(?<=$ID=)$VERSION_REGEX")
	local NEW_VERSION=$(curl --silent --location "$MIRROR" | jq -r ".[0]" | grep --only-matching --perl-regexp "$VERSION_REGEX")
	if [ -z "$CURRENT_VERSION" ] || [ -z "$NEW_VERSION" ];then
		echo -e "\e[31mFailed to scrape $NAME version!\e[0m"
		return
	fi

	if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
		return
	fi

	prepare_update "$ID" "$NAME" "$CURRENT_VERSION" "$NEW_VERSION"
	update_version "$NEW_VERSION"
}

# Check dependencies
assert_dependency "jq"
assert_dependency "curl"

# Debian Stable
IMG_CHANNEL="stable"
update_image "amd64/debian" "Debian" "false" "$IMG_CHANNEL-\d+-slim"

# Terraria Server
update_custom "APP_VERSION" "Terraria Server"

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
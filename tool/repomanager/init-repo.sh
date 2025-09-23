#!/usr/bin/env bash

REPO_TEMPLATE_URL="https://github.com/kemadev/repo-tmpl"

function main() {
	set -euo pipefail
	REPO_URL="$(git remote get-url origin)"
	REPO_NAME="${REPO_URL#https://}"

	local HOST_REGEX="^([^\/[:space:]]+)"
    local ORG_REGEX="([^\/[:space:]]+)"
    local REPO_REGEX="([^[:space:]]+?)(?:\.git)?"

	HOST="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}(?=.*)")"
	ORG="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}\/\K${ORG_REGEX}(?=.*)")"
	REPO="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}\/${ORG_REGEX}\/\K${REPO_REGEX}(?=$|\/[^\/[:space:]]+)" | sed "s|.git||g")"

	TEMP="$(mktemp -d -t init-repo-XXXXXX)"

	git clone --filter=blob:none --sparse "${REPO_TEMPLATE_URL}" "${TEMP}"
	git -C "${TEMP}" sparse-checkout set template/go-app
	rm -rf "${TEMP}/.git"

	cp -r "${TEMP}/" .
}

main "${@}"

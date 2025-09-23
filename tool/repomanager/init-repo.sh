#!/usr/bin/env bash

REPO_TEMPLATE_URL="https://github.com/kemadev/repo-tmpl"
TEMPLATE_SUBDIR="template"

REPO_NAME_TEMPLATE_KEY="REPONAMETMPL"

function usage() {
    cat << EOF
Usage: ${0} TEMPLATE

Initialize a git repository from a template, that is a sub-directory of "${TEMPLATE_SUBDIR}" from ${REPO_TEMPLATE_URL}

EXAMPLES:
    ${0} "mytemplate"
EOF
}

function parse_args() {
	if [[ -z "${1:-}" ]]; then
		usage
		exit 1
	fi

	TEMPLATE_NAME="${1}"
}

function init_repo() {
	local REPO_URL="$(git remote get-url origin)"
	REPO_NAME="${REPO_URL#https://}"

	local HOST_REGEX="^([^\/[:space:]]+)"
    local ORG_REGEX="([^\/[:space:]]+)"
    local REPO_REGEX="([^[:space:]]+?)(?:\.git)?"

	local HOST="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}(?=.*)")"
	local ORG="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}\/\K${ORG_REGEX}(?=.*)")"
	local REPO="$(echo "${REPO_NAME}" | grep -oP "${HOST_REGEX}\/${ORG_REGEX}\/\K${REPO_REGEX}(?=$|\/[^\/[:space:]]+)" | sed "s|.git||g")"

	local TEMP="$(mktemp -d -t init-repo-XXXXXX)"

	git clone --filter=blob:none --sparse "${REPO_TEMPLATE_URL}" "${TEMP}"
	git -C "${TEMP}" sparse-checkout set "${TEMPLATE_SUBDIR}/${TEMPLATE_NAME}"
	rm -rf "${TEMP}/.git"

	REPO_PATH="${TEMP}/${TEMPLATE_SUBDIR}/${TEMPLATE_NAME}"

	if [ ! -d "${REPO_PATH}" ]; then
		echo "${TEMPLATE_SUBDIR}/${TEMPLATE_NAME} does not exist in remote"
		usage
		exit 1
	fi

	cp -r "${REPO_PATH}/"* .
}

function replace_template_vars() {
	find . -type f -exec sed -i "s|${REPO_NAME_TEMPLATE_KEY}|${REPO_NAME}|g" {} +
}

function create_files() {
	local MAIN_FILE_DIR="cmd/${REPO_NAME}"

	mkdir -p "${MAIN_FILE_DIR}"
	cat << EOF
EOF > "${MAIN_FILE_DIR}/main.go"
}

function main() {
	set -euo pipefail

	parse_args "${@}"
	init_repo
	replace_template_vars
}

main "${@}"

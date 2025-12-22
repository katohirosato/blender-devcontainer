#!/usr/bin/env bash
# Usage: utils/obfuscate/obfuscate.sh [package1] [package2] ...
# If no packages specified, obfuscates all packages

set -euo pipefail

set -a
[ -f "${ROOTDIR}/.env" ] && source "${ROOTDIR}/.env"
set +a

ROOTDIR=$(dirname "$(dirname "$(realpath "$0")")")

readonly DOCKERFILE="${ROOTDIR}/utils/obfuscate/obfuscate.Dockerfile"
readonly OUTPUT_DIR="${ROOTDIR}"
readonly EXTENSIONS=${ "${ROOTDIR}/$(basename $EXTENSIONS)":"${ROOTDIR}/extensions/"}

packages=("$@")

if [ ${#packages[@]} -eq 0 ]; then
    docker buildx build --output type=local,dest="${OUTPUT_DIR}" --file "${DOCKERFILE}" --build-arg EXTENSIONS="${EXTENSIONS}" .
else
    docker buildx build --output type=local,dest="${OUTPUT_DIR}" --file "${DOCKERFILE}" --build-arg EXTENSIONS="${EXTENSIONS}" --build-arg PACKAGES="${packages[*]}" .
fi

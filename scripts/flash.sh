#!/usr/bin/env bash
set -Eeuo pipefail

readonly SERVICE="zephyr-dev"
readonly WORKSPACE="/workspace"
readonly ZEPHYR_DIR="${WORKSPACE}/deps/zephyr"
readonly SDK_DIR="${WORKSPACE}/.zephyr-sdk"
readonly SETUP_MARKER="/opt/venv/.zephyr-setup-complete"
readonly RPI_OPENOCD="/opt/raspberrypi-openocd/bin/openocd"
readonly ZEPHYR_BUILD_DIRECTORY="${WORKSPACE}/zephyr-course/build/zephyr"

usage() {
  cat <<'EOF'
Usage:
  ./flash.sh <runner>

Examples:
  ./flash.sh openocd
  ./flash.sh uf2
EOF
}

project_is_built() {
  test -f ${ZEPHYR_BUILD_DIRECTORY}/zephyr.elf && test -f ${ZEPHYR_BUILD_DIRECTORY}/zephyr.uf2 >/dev/null 2>&1
}

flash_board() {
  local runner="$1"

  if ! project_is_built; then
    cat >&2 <<'EOF'
    Could not find firmware images on build directory
    Run the following command first:
    ./script/setup.sh
EOF
    exit 1
  fi

  echo "Flashing using ${runner}..."
  west flash --runner ${runner}
}

main() {
  if (($# != 1)); then
    usage >&2
    exit 2
  fi

  flash_board "$@"
}

main "$@"

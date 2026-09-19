#!/usr/bin/env bash
set -Eeuo pipefail

readonly SERVICE="zephyr-dev"
readonly WORKSPACE="/workspace"
readonly ZEPHYR_DIR="${WORKSPACE}/deps/zephyr"
readonly SDK_DIR="${WORKSPACE}/.zephyr-sdk"
readonly SETUP_MARKER="/opt/venv/.zephyr-setup-complete"
readonly RPI_OPENOCD="/opt/raspberrypi-openocd/bin/openocd"

usage() {
  cat <<'EOF'
Usage:
  ./build.sh <project> <board>

Examples:
  ./build.sh app rpi_pico2/rp2350a/m33
EOF
}

workspace_is_initialized() {
  test -f ${WORKSPACE}/.west/config && west topdir >/dev/null 2>&1
}

environment_is_setup() {
  workspace_is_initialized &&
    test -d "${ZEPHYR_DIR}" &&
    test -f "${SETUP_MARKER}" &&
    cmake_registry_is_configured &&
    sdk_is_installed
}

sdk_is_installed() {
  find ${SDK_DIR} -type f -path "*/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" -perm /111 -print -quit 2>/dev/null | grep -q .
}

cmake_registry_is_configured() {
  find /root/.cmake/packages/Zephyr -type f -print -quit 2>/dev/null | grep -q .
}

build_project() {
  local board="$2"
  local project="$1"

  if ! environment_is_setup; then
    cat >&2 <<'EOF'
    The Zephyr environment has not been completely set up.
    Run the following command first:
    ./script/build.sh
EOF
    exit 1
  fi

  echo "Building ${project} for ${board}..."
  # OPENOCD is a CMake cache variable. Set it explicitly so Zephyr records the
  # Raspberry Pi fork in build/zephyr/runners.yaml instead of SDK OpenOCD.
  west build -p always -b "${board}" ${project} -- \
    -DOPENOCD="${RPI_OPENOCD}"
}

main() {
  if (($# != 2)); then
    usage >&2
    exit 2
  fi

  build_project "$@"
}

main "$@"

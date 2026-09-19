#!/usr/bin/env bash
set -euo pipefail

readonly WORKSPACE="/workspace"
readonly ZEPHYR_DIR="${WORKSPACE}/deps/zephyr"
readonly SDK_DIR="${WORKSPACE}/.zephyr-sdk"
readonly SETUP_MARKER="/opt/venv/.zephyr-setup-complete"

RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[34m'
RESET='\e[0m'

usage() {
  cat <<'EOF'
Usage:
  ./setup.sh
EOF
}

workspace_is_initialized() {
  test -f ${WORKSPACE}/.west/config && west topdir >/dev/null 2>&1
}

sdk_is_installed() {
  find ${SDK_DIR} -type f -path "*/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" -perm /111 -print -quit 2>/dev/null | grep -q .
}

setup_environment() {

  cd ${WORKSPACE}

  echo -e "${GREEN}Checking west workspace${RESET}"
  if workspace_is_initialized; then
    echo "> West workspace is already initialized; skipping west init."
  else
    echo "> Initializing the West workspace..."
    west init -l
  fi

  echo -e"${GREEN}Updating West projects${RESET}"
  west update

  echo -e "${GREEN}Installing or updating Python requirements${RESET}"
  west packages pip --install

  echo -e "${GREEN}Exporting Zephyr to the CMake user package registry${RESET}"
  west zephyr-export

  echo -e "${GREEN}Checking for ARM SDK Toolchain${RESET}"
  if sdk_is_installed; then
    echo "> The ARM Zephyr SDK toolchain is already installed; skipping SDK installation."
  else
    echo "> Installing the ARM Zephyr SDK toolchain..."
    cd ${ZEPHYR_DIR}
    west sdk install --install-base "${SDK_DIR}" --toolchains arm-zephyr-eabi
  fi

  touch "${SETUP_MARKER}"
  echo -e "${GREEN}Setup completed successfully.${RESET}"
}

main() {
  if (($# != 0)); then
    usage >&2
    exit 2
  fi

  setup_environment
}

main "$@"

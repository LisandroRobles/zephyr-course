#!/usr/bin/env bash

set -Eeuo pipefail

readonly SERVICE="zephyr-dev"
readonly WORKSPACE="/workspace"
readonly ZEPHYR_DIR="${WORKSPACE}/deps/zephyr"
readonly SDK_DIR="${WORKSPACE}/.zephyr-sdk"
readonly SETUP_MARKER="/opt/venv/.zephyr-course-setup-complete"
readonly RPI_OPENOCD="/opt/raspberrypi-openocd/bin/openocd"

usage() {
    cat <<'EOF'
Usage:
  ./zephyr-course.sh setup
  ./zephyr-course.sh build <board>

Examples:
  ./zephyr-course.sh setup
  ./zephyr-course.sh build rpi_pico2/rp2350a/m33
EOF
}

compose() {
    docker compose "$@"
}

service_is_running() {
    [[ "$(compose ps --status running --quiet "${SERVICE}")" != "" ]]
}

start_service() {
    echo "Starting the Zephyr development container..."
    # Compose builds the image automatically when it does not exist. This function
    # avoids using --build here: routine setup/build commands should reuse the
    # existing image and container whenever possible.
    compose up -d "${SERVICE}"
}

stop_service() {
    if service_is_running; then
        echo "Stopping the Zephyr development container..."
        compose stop "${SERVICE}"
    fi
}

exec_zephyr() {
    compose exec "${SERVICE}" "$@"
}

sdk_is_installed() {
    exec_zephyr sh -c \
        'find /workspace/.zephyr-sdk -type f -path "*/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" -perm /111 -print -quit 2>/dev/null | grep -q .'
}

cmake_registry_is_configured() {
    exec_zephyr sh -c \
        'find /root/.cmake/packages/Zephyr -type f -print -quit 2>/dev/null | grep -q .'
}

environment_is_setup() {
    workspace_is_initialized &&
        exec_zephyr test -d "${ZEPHYR_DIR}" &&
        exec_zephyr test -f "${SETUP_MARKER}" &&
        cmake_registry_is_configured &&
        sdk_is_installed
}

setup_environment() {
    start_service

    # setup must leave the service stopped, including when one of its steps fails.
    trap stop_service EXIT

    if workspace_is_initialized; then
        echo "West workspace is already initialized; skipping west init."
    else
        echo "Initializing the West workspace..."
        exec_zephyr west init -l
    fi

    echo "Updating West projects..."
    exec_zephyr west update

    echo "Installing or updating Python requirements..."
    exec_zephyr west packages pip --install

    echo "Exporting Zephyr to the CMake user package registry..."
    exec_zephyr west zephyr-export

    if sdk_is_installed; then
        echo "The ARM Zephyr SDK toolchain is already installed; skipping SDK installation."
    else
        echo "Installing the ARM Zephyr SDK toolchain..."
        compose exec \
            --workdir "${ZEPHYR_DIR}" \
            "${SERVICE}" \
            west sdk install \
            --install-base "${SDK_DIR}" \
            --toolchains arm-zephyr-eabi
    fi

    exec_zephyr touch "${SETUP_MARKER}"
    echo "Setup completed successfully."
}

build_project() {
    local board="$1"

    start_service

    # Leave the service stopped after the build, including when a check or the
    # build itself fails.
    trap stop_service EXIT

    if ! environment_is_setup; then
        cat >&2 <<'EOF'
The Zephyr environment has not been completely set up.
Run the following command first:

  ./zephyr-course.sh setup
EOF
        exit 1
    fi
    echo "Building the application for ${board}..." \
        -DOPENOCD="${RPI_OPENOCD}" # OPENOCD is a CMake cache variable. Set it explicitly so Zephyr records the Raspberry Pi fork in build/zephyr/runners.yaml instead of SDK OpenOCD. exec_zephyr west build -p always -b "${board}" app -- \
}

main() {
    if (($# == 0)); then
        usage >&2
        exit 2
    fi

    case "$1" in
    setup)
        if (($# != 1)); then
            usage >&2
            exit 2
        fi
        setup_environment
        ;;
    build)
        if (($# != 2)); then
            echo "Error: build requires a board argument." >&2
            usage >&2
            exit 2
        fi
        build_project "$2"
        ;;
    -h | --help | help)
        usage
        ;;
    *)
        echo "Error: unknown command '$1'." >&2
        usage >&2
        exit 2
        ;;
    esac
}

main "$@"

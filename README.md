# Zephyr foundational course

This repository contains the course application and a Docker Compose development
environment for Zephyr RTOS 4.2.0.

The docker container provides the operating-system tools, Python, `west`, and the Zephyr
SDK toolchain. The repository and downloaded Zephyr modules are stored in the host
workspace, while a Docker named volume preserves the Python virtual environment.

## Requirements

The requirement to run the development container are:

- Docker Engine
- Docker Compose v2 (`docker compose version`)

For Ubuntu, install the requirements with:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
```

Enable and start docker:

```bash
sudo systemctl enable --now docker
```

To run docker without sudo:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

Run all commands below from this repository's directory, where `compose.yaml` is
located.

## Workspace layout

The Compose bind mount maps the directory containing this repository to
`/workspace`:

```text
/workspace/
├── .west/
├── .zephyr-sdk/
├── deps/
│   └── zephyr/
└── zephyr-course/
    ├── app/
    ├── compose.yaml
    ├── dockerfile
    ├── zephyr-course.sh
    └── west.yml
```

The Python virtual environment is stored in the `zephyr-venv` Docker named
volume, mounted at `/opt/venv`. The CMake user package registry produced by
`west zephyr-export` is stored in `zephyr-cmake-registry`, mounted at
`/root/.cmake`. Both survive container recreation.

## Helper script

Run the helper from the directory containing `compose.yaml`. Its available
commands can be displayed with:

```bash
./zephyr-course.sh --help
```

### Set up the environment

Run the complete setup with:

```bash
./zephyr-course.sh setup
```

The command starts the development container and then:

1. Initializes the West workspace if it is not already initialized.
2. Updates the projects declared in `west.yml`.
3. Installs or updates the required Python packages.
4. Exports Zephyr to CMake's user package registry.
5. Installs the ARM Zephyr SDK toolchain if it is not already installed.

It is safe to run `setup` again. Existing West and SDK installations are
detected, while the repeatable update, package installation, and export steps
ensure that changes to the project dependencies are applied. The container is
stopped when setup finishes or fails.

### Build the application

Pass the required Zephyr board target to `build`:

```bash
./zephyr-course.sh build rpi_pico2/rp2350a/m33
```

The command starts the container, verifies that setup completed successfully,
and performs a pristine application build for the selected board. If the
environment is incomplete, it asks you to run `setup` first. The container is
stopped when the build finishes or fails.

The general form is:

```bash
./zephyr-course.sh build <board>
```

## Manual setup and build

The helper is the recommended interface. The equivalent individual commands
are documented below for reference and troubleshooting.

Build the image and start the development container:

```bash
docker compose up --build -d
```

Initialize the parent directory as a West workspace using this repository as the
local manifest repository:

```bash
docker compose exec zephyr-dev west init -l
```

Fetch the projects declared in `west.yml`:

```bash
docker compose exec zephyr-dev west update
```

Install the Zephyr Python requirements in the persistent virtual environment:

```bash
docker compose exec zephyr-dev west packages pip --install
```

Export the Zephyr CMake package:

```bash
docker compose exec zephyr-dev west zephyr-export
```

Install the SDK and ARM toolchain in the bind-mounted workspace:

```bash
docker compose exec \
  --workdir /workspace/deps/zephyr \
  zephyr-dev \
  west sdk install \
    --install-base /workspace/.zephyr-sdk \
    --toolchains arm-zephyr-eabi
```

Verify the installation:

```bash
docker compose exec zephyr-dev west topdir
docker compose exec --workdir /workspace/deps/zephyr zephyr-dev west sdk list
```

The setup commands normally need to be executed only once. Do not run `west init`
again after the West workspace has been initialized.

### Build the application manually

Replace `<board>` with the Zephyr board target you want to use:

```bash
docker compose exec zephyr-dev \
  west build -p always -b <board> app
```

For subsequent incremental builds, omit `-p always`:

```bash
docker compose exec zephyr-dev west build
```

To select a different application or board, perform a pristine build again:

```bash
docker compose exec zephyr-dev \
  west build -p always -b <board> path/to/application
```

## Build the Zephyr Blinky sample

```bash
docker compose exec \
  --workdir /workspace/deps/zephyr \
  zephyr-dev \
  west build -p always -b <board> samples/basic/blinky
```

## Updating dependencies

After changing the revision or projects in `west.yml`, update the repositories and
Python packages:

```bash
docker compose up -d
docker compose exec zephyr-dev west update
docker compose exec zephyr-dev west packages pip --install
```

## Resetting the Python environment

The Python environment and CMake package registry survive container deletion
because they are stored in named volumes. To remove all Compose-managed
containers and named volumes and start again:

```bash
docker compose down --volumes
./zephyr-course.sh setup
```

The `--volumes` option deletes the persistent Python environment, setup marker,
and CMake package registry. It does not delete the bind-mounted source,
downloaded modules, or SDK under `/workspace`.

## Manual installation

To set up Zephyr without Docker, follow the official
[Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/develop/getting_started/index.html)

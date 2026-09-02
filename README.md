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
    └── west.yml
```

The Python virtual environment is stored separately in the Docker named volume
`zephyr-venv`, mounted at `/opt/venv`.

## First-time setup

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

## Build the course application

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

## Daily workflow

Start the existing development container:

```bash
docker compose up -d
```

Build the application:

```bash
docker compose exec zephyr-dev west build
```

Stop the container without deleting it:

```bash
docker compose stop
```

Alternatively, remove the service container while retaining the workspace and
named virtual-environment volume:

```bash
docker compose down
```

The next `docker compose up -d` recreates the service container and reuses the
existing `zephyr-venv` volume.

## Updating dependencies

After changing the revision or projects in `west.yml`, update the repositories and
Python packages:

```bash
docker compose up -d
docker compose exec zephyr-dev west update
docker compose exec zephyr-dev west packages pip --install
```

## Resetting the Python environment

The virtual environment survives container deletion because it is stored in a
named volume. To remove all Compose-managed containers and named volumes and start
again:

```bash
docker compose down --volumes
docker compose up --build -d
docker compose exec zephyr-dev west packages pip --install
```

The `--volumes` option deletes the persistent Python environment. It does not
delete the bind-mounted source, downloaded modules, or SDK under `/workspace`.

## Manual installation

To set up Zephyr without Docker, follow the official
[Zephyr Getting Started Guide](https://docs.zephyrproject.org/latest/develop/getting_started/index.html)
through the Blinky sample build.

FROM ubuntu:22.04

WORKDIR /workspace

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends \
    git \
    cmake \
    ninja-build \
    gperf \
    ccache \
    dfu-util \
    device-tree-compiler \
    wget \
    python3-dev \
    python3-venv \
    python3-tk \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1 \
    python3-pip \
    autoconf \
    automake \
    libtool \
    pkg-config \
    libusb-1.0-0-dev \
    libftdi1-dev \
    libhidapi-dev \
    && rm -rf /var/lib/apt/lists/* 

# Zephyr's SDK OpenOCD does not support the RP2350. Build the Raspberry Pi fork,
# which provides both the RP2350 target script and the required flash driver.
ARG RPI_OPENOCD_REF=sdk-2.0.0
RUN git clone --branch "${RPI_OPENOCD_REF}" --depth 1 \
        https://github.com/raspberrypi/openocd.git /tmp/raspberrypi-openocd \
    && cd /tmp/raspberrypi-openocd \
    && ./bootstrap \
    && ./configure --prefix=/opt/raspberrypi-openocd --enable-cmsis-dap \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/raspberrypi-openocd

ENV RPI_OPENOCD=/opt/raspberrypi-openocd/bin/openocd

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python3 -m venv ${VIRTUAL_ENV}

RUN python -m pip install --no-cache-dir west

WORKDIR /workspace/zephyr-course

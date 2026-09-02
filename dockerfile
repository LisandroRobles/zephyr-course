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
    && rm -rf /var/lib/apt/lists/* 

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python3 -m venv ${VIRTUAL_ENV}

RUN python -m pip install --no-cache-dir west

WORKDIR /workspace/zephyr-course
# RUN cd app && west init -l
#
# RUN west update
# RUN west packages pip --install
# RUN west zephyr-export
#
# RUN cd deps/zephyr && west sdk install --toolchains arm-zephyr-eabi

# RUN west build -p always -b <your-board-name> samples/basic/blinky

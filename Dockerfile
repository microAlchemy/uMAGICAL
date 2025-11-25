FROM ubuntu:24.04
LABEL maintainer="Mingjie Liu <jay_liu@utexas.edu>"

ENV DEBIAN_FRONTEND=noninteractive

# Core toolchain and Python
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    vim \
    csh \
    flex \
    bison \
    python3-dev \
    python3-pip \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Libraries except Boost (built from source below)
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libncurses-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libsparsehash-dev \
    libeigen3-dev \
    liblpsolve55-dev \
    pybind11-dev \
    && rm -rf /var/lib/apt/lists/*

# Lemon from source (no package on noble)
RUN wget -O /tmp/lemon-1.3.1.tar.gz http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.tar.gz \
    && cd /tmp && tar xzf lemon-1.3.1.tar.gz && cd lemon-1.3.1 \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr .. \
    && make -j$(nproc) && make install \
    && cd / && rm -rf /tmp/lemon-1.3.1 /tmp/lemon-1.3.1.tar.gz

# Build and install Boost 1.71 (newer Boost+GCC combos have caused Boost.Geometry errors)
ARG BOOST_VERSION=1.71.0
ARG BOOST_VERSION_UNDERSCORE=1_71_0
RUN curl -L -o /tmp/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz \
    && cd /tmp && tar xzf boost_${BOOST_VERSION_UNDERSCORE}.tar.gz && cd boost_${BOOST_VERSION_UNDERSCORE} \
    && ./bootstrap.sh --prefix=/usr/local --with-libraries=system,graph,iostreams \
    && ./b2 -j$(nproc) link=shared runtime-link=shared install \
    && cd / && rm -rf /tmp/boost_${BOOST_VERSION_UNDERSCORE} /tmp/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz
ENV BOOST_ROOT=/usr/local

# Set up python aliases
RUN echo "alias python=python3" >> ~/.bashrc \
    && echo "alias pip=pip3" >> ~/.bashrc \
    && ln -s /usr/bin/python3 /usr/bin/python

# Allow pip to install into system environment on 24.04
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Set environment variables for system libraries
ENV LPSOLVE_DIR=/usr
ENV LPSOLVE_LIBRARIES=/usr/lib/liblpsolve55.a
ENV LEMON_DIR=/usr

# Create symlinks for lpsolve so CMake can find it
RUN ln -s /usr/lib/liblpsolve55_pic.a /usr/lib/liblpsolve55.so \
    && for f in /usr/include/lpsolve/*.h; do ln -s "$f" "/usr/include/$(basename "$f")"; done \
    && ln -s /usr/include/eigen3/Eigen /usr/include/Eigen

# Install wnlib (Manual build)
RUN mkdir wnlib && cd wnlib \
    && wget http://www.willnaylor.com/wnlib.tar.gz \
    && gunzip wnlib.tar.gz && tar xvf wnlib.tar \
    && export PATH=${PATH}:/wnlib/acc \
    && make all \
    && cd acc && ar rcs text.a */*.o && cd .. \
    && rm -f wnlib.tar
ENV WNLIB_DIR=/wnlib

# Install pybind11 (Manual clone to ensure we have the source for submodules if needed,
# though pip install pybind11 is also done later. Keeping consistent with original structure)
RUN git clone https://github.com/pybind/pybind11.git
ENV PYBIND11_DIR=/pybind11

# Install limbo (Manual build)
# Note: Limbo depends on boost, flex, bison, zlib which are now system installed
RUN git clone https://github.com/limbo018/Limbo.git \
    && mkdir Limbo/build && cd Limbo/build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/limbo \
    && make -j$(nproc) && make install
ENV LIMBO_DIR=/limbo
ENV LIMBO_INC=/limbo/include

# Python deps (pin pre-2.0 numpy for gdspy compatibility)
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    "numpy==1.26.4" \
    "scipy==1.11.4" \
    "matplotlib==3.8.4" \
    "networkx==3.3" \
    "Cython==3.0.10" \
    "pybind11==2.12.0"

# Install gdspy
RUN git clone https://github.com/jayl940712/gdspy.git \
    && pip3 install gdspy/ \
    && rm -rf gdspy

# Copy local source
COPY . /MAGICAL
WORKDIR /MAGICAL

# Ensure submodules are present for downstream builds
RUN if [ -d .git ]; then git submodule update --init --recursive; else echo "No .git found; assuming submodules are already present in build context"; fi

# Patch IdeaPlaceEx CMakeLists.txt to link against colamd and dl
RUN sed -i 's/${LPSOLVE_LIBRARIES}/${LPSOLVE_LIBRARIES} colamd dl/g' IdeaPlaceEx/CMakeLists.txt
# Clean up any existing build artifacts to ensure a fresh build
RUN rm -rf build/ \
    && rm -rf flow/cpp/magical_flow/build/ \
    && rm -rf IdeaPlaceEx/build/ \
    && rm -rf anaroute/build/ \
    && rm -rf device_generation/build/ \
    && ./build.sh

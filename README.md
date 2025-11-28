# uMAGICAL #

uMAGICAL: MicroAlchemy Machine Generated Analog IC Layout

This is the top-level uMAGICAL flow repository. In uMAGICAL, we maintain seperate components, such as constraint generation, placement and routing, in different repository. And we integrate each component through top-level python flow.

This project is currently still under active development.

# Dependency #

- Docker image: Ubuntu 24.04 base with all build tools preinstalled (see [Dockerfile](Dockerfile)).
- Python: 3.10+ (Docker image uses 3.12) with pinned packages: numpy 1.26.4, scipy 1.11.4, matplotlib 3.8.4, networkx 3.3, Cython 3.0.10, pybind11 2.12.0.
- System packages: build-essential, cmake, git, wget, curl, vim, csh, flex, bison, python3-dev/pip, pkg-config, zlib1g-dev, libncurses-dev, libnss3-dev, libssl-dev, libreadline-dev, libffi-dev, libsparsehash-dev, libeigen3-dev, liblpsolve55-dev, pybind11-dev.
- Built from source (versions match the Dockerfile):
    - [Lemon 1.3.1](https://lemon.cs.elte.hu/trac/lemon)
    - [Boost 1.71.0](https://www.boost.org) (newer Boost + GCC combos can trigger Boost.Geometry errors)
    - [wnlib](http://www.willnaylor.com/wnlib.tar.gz)
    - [Limbo](https://github.com/limbo018/Limbo)
- Other notes: lpsolve 5.5 is expected and symlinked for CMake discovery (see Dockerfile for the exact steps).


# How to clone #

To clone the repository and submodules, go to the path to download the repository.
```
# clone the repository (including submodules)
git clone --recurse-submodules https://github.com/microAlchemy/uMAGICAL.git
```

# How to build #

Two options are provided for building: with and without [Docker](https://hub.docker.com). You can also build from source (NOT RECOMMENDED) resolving the required dependancies first.

## Build with Docker

You can use the Docker container to avoid building all the dependencies yourself.
1. Install Docker on [Linux](https://docs.docker.com/install/).
2. Navigate to the repository.
    ```
    cd MAGICAL
    ```
3. Get the docker container with either of the following options.
    - Option 1 (Recommended): pull from the cloud  [jayl940712/magical](https://hub.docker.com/r/jayl940712/magical).
    ```
    docker pull jayl940712/magical:latest
    ```
    - Option 2: build the container.
    ```
    docker build . --file Dockerfile --tag magical:latest
    ```
4. Run the docker container
    ```
    docker run -it -v $(pwd):/MAGICAL jayl940712/magical:latest bash
    ```
    Or if you used option 2 to build the container
    ```
    docker run -it -v $(pwd):/MAGICAL magical:latest bash
    ```

The Dockerfile installs all third-party dependencies (including Lemon 1.3.1, Boost 1.71.0, wnlib, and Limbo), pins Python packages for compatibility, pulls submodules, and runs `./build.sh` so the Python components are installed inside the image.

## Build without Docker (advanced)

If you cannot use Docker, mirror the steps in the Dockerfile:
1. Install the system packages listed in the dependency section.
2. Build and install Lemon 1.3.1, Boost 1.71.0, wnlib, and Limbo into locations visible to CMake (see the Dockerfile for exact commands and environment variables).
3. Ensure lpsolve 5.5 headers and libraries are discoverable (the Dockerfile symlinks them into standard include/lib paths).
4. From the repository root run:
    ```
    ./build.sh
    ```
   which installs the Python packages from each subcomponent with `pip`.

# How to run #

Benchmark circuit examples are under examples/

All technology related parameters including benchmark circuit sizing are samples and not related to any proprietary PDK information.

Benchmark circuits currently includes:
1 adc, 1 comparator, 3 ota

To run the benchmark circuits
```
cd /MAGICAL/examples/BENCH/ (ex. adc1)
source run.sh
```

The output layout gdsii files: BENCH/TOP_CIRCUIT.route.gds (ex. adc1/xxx.route.gds)

Note: currently adc2 have routing issues.

# Custom layout constraint inputs #

The automatic symmetry constraint generation is currently embedded into the flow. To ensure circuit functionality it is ideal that designers provide  constraints to guide the placement and routing.

A sample device and net symmetry constraint is given for adc1. These files should also be the output for the current automatic symmetry constraint generation flow.

Sample symmetry device constraint file:
examples/adc1/CTDSM_TOP.sym

Sample symmetry net constraint file:
examples/adc1/CTDSM_TOP.symnet

## Device symmetry constraints

Device symmetry constraints greatly affect the placement solution and output layout quality. Currently we only consider symmetry groups, symmetry device pairs and self-symmetric device constraints.

**Symmetry group**: A group of symmetry device pairs and self-symmetric devices that share the same symmetry axis.

**Symmetry device pair**: Two devices that are reflection symmetric with respect to a symmetry axis (usually vertical).

**Self-symmetry device**: A single device that is reflection symmetric with itself respect to a symmetry axis.

## Net symmetry constraints

Similar to device symmetry constraints, we consider symmetry net pairs and self-symmetry net constraints.

**Symmetry net pair**: Two nets that are reflection symmetric with respect to a symmetry axis (usually vertical). For a valid constraint, the corresponding pins of the two nets must be reflective symmetric with a axix.

**Self-symmetry net**: A single net that is reflection symmetric with itself respect to a symmetry axis.

# License #
[BSD 3-Clause](https://github.com/microAlchemy/uMAGICAL/blob/master/LICENSE)

# Installation & System Architecture Guide (HPC/Admin)

This document provides technical instructions for setting up the ANUGA + Flood Modeling pipeline. It is intended for System Administrators and HPC Engineers who need to manage dependencies, environment variables, and hardware-specific builds.

---

## 1. System Requirements & Stack
The toolchain is optimized for Linux environments (Ubuntu 20.04+, RHEL 8+, or BOSS-OS) running on HPC architectures like Param Shavak.

| Component       | Version/Source        | Role                                      |
| :-------------- | :-------------------- | :---------------------------------------- |
| Python          | 3.8+                  | Simulation logic & post-processing        |
| ANUGA           | v3.2.0 (cloned)       | Hydrodynamic Physics Engine               |
| OpenMPI         | 4.x+                  | Parallel Processing (Message Passing)     |
| GeoServer       | 2.24+                 | Geospatial WMS/WFS Data Hosting           |
| Node.js         | v20+ (LTS)            | React Dashboard Runtime                   |
| Java JRE        | 11 or 17              | Runtime for GeoServer (Jetty)             |

---

## 2. Pre-Installation (Critical Prep)

### IMPORTANT: Conda Warning
Before starting the installation, **DEACTIVATE ALL CONDA ENVIRONMENTS**. 
Conda's internal library paths often conflict with system MPI compilers (`mpicc`) and NetCDF headers, leading to "Symbol not found" errors during the ANUGA build.
```bash
conda deactivate
# Repeat until you are in the base system environment
```

## Air-Gapped/Cluster Prep

If working on a restricted HPC node without direct internet access, ensure the following binary archives are pre-staged in the opensource_tools/ directory:

1. geoserver-*-bin.zip
2. node-v*-linux-x64.tar.xz

**MPI Note:** Ensure mpicc and mpirun are accessible in your $PATH. On clusters, this usually requires 'module load mpi/openmpi-x86_64'.

---

## 3. Automated Installation
The system uses a CMake-driven build process to compile ANUGA's C-extensions and Python dependencies against your specific hardware (CPU/MPI) instructions.

```bash
# Initialize the build system
cmake .

# Execute the installation pipeline
make setup
```

## What happens during 'make setup':
1. System Check: Verifies headers for libnetcdf, gdal, and gfortran.
2. Environment Isolation: Configures local paths to avoid polluting system Python.
3. ANUGA Build: Clones anuga_core, compiles Cython kernels, and installs in editable mode.
4. Tool Deployment: Extracts Node.js and GeoServer into the project tree.
5. Script Generation: Automatically writes environment-sourcing scripts in build/.

## 4. Environment Verification
Once the build completes, use these tests to verify the integrity of the stack.

### A. Verify Physics Engine (ANUGA + MPI)
```bash
source build/setup_mpi_env.sh
make verify
```

Verification check: Ensures ANUGA can be imported and detects multiple MPI processors.

### B. Verify Visualization Tools (Node + GeoServer)
```bash
source build/setup_tools_env.sh
make test_tools
```

Verification check: Confirms Node.js pathing and Java/GeoServer accessibility.

## 5. Directory Architecture
Post-installation, your workspace will be structured as follows:

```plaintext
.
├── anuga_core/          # Compiled ANUGA source
├── build/               # Generated environment & control scripts
│   ├── setup_mpi_env.sh # <--- SOURCE THIS FOR SIMULATIONS
│   └── setup_tools_env.sh # <--- SOURCE THIS FOR UI/GEOSERVER
├── opensource_tools/    # Extracted binary tools (Node/GeoServer)
└── mahanadi_test_case/  # Simulation project files
```

## 6. Technical Troubleshooting & Caveats

**MPI Compilation Issues**
If mpi4py fails during installation, the build system likely cannot find your MPI wrapper. Fix: export MPICC=$(which mpicc) pip install mpi4py --no-cache-dir

**Shared Library Paths**
On RHEL-based systems (BOSS-OS), libnetcdf.so may reside in non-standard directories. Fix: The build/setup_mpi_env.sh script is generated to handle this, but you may need to manually append paths to LD_LIBRARY_PATH if using custom-built libraries.

---
**Next Step:** Once the environment is verified, refer to [RUNNING.md](./RUNNING.md) for simulation configuration and data workflow instructions.
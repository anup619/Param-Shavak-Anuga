# ANUGA + Flood Modeling Toolchain Installation

This is a comprehensive CMake-based installation system for ANUGA (Australian National University Geophysical Analysis) with integrated GeoServer, Node.js, and optional anuga-viewer for flood modeling workflows on Linux systems.

## Prerequisites

- **Operating System**: Ubuntu 20.04+ / Debian 11+ / RHEL 8+ / AlmaLinux 8+ / Fedora 35+
- **Privileges**: sudo access for installing system packages
- **Internet**: Required for downloading packages and cloning repositories
- **Disk Space**: ~2 GB for full installation (ANUGA + tools)

## Quick Start

### One-Command Installation

```bash
make setup
```

This single command will:
1. Install all system dependencies (MPI, NetCDF, Java, etc.)
2. Install Python build tools and scientific libraries
3. Clone and build ANUGA with MPI support
4. Extract GeoServer and Node.js (if archives present in `opensource_tools/`)
5. Optionally build anuga-viewer (if GDAL development headers available)

## What Gets Installed

### System Packages

**Ubuntu/Debian:**
- Build tools: `gcc`, `g++`, `make`, `cmake`, `git`, `ninja-build`
- Python: `python3`, `python3-pip`, `python3-dev`, `pkg-config`
- Scientific libraries: `libnetcdf-dev`
- MPI: `libopenmpi-dev`, `openmpi-bin`
- Utilities: `unzip`, `tar`, `curl`
- Java: `default-jre` (for GeoServer)
- Optional: `libgdal-dev`, `libcppunit-dev`, `libopenscenegraph-dev` (for anuga-viewer)

**RHEL/AlmaLinux/Fedora:**
- Build tools: `gcc`, `gcc-c++`, `make`, `cmake`, `git`, `ninja-build`
- Python: `python3`, `python3-pip`, `python3-devel`, `pkgconf-pkg-config`
- Scientific libraries: `netcdf-devel`
- MPI: `openmpi`, `openmpi-devel`
- Utilities: `unzip`, `tar`, `curl`
- Java: `java-17-openjdk` (for GeoServer)
- Optional: `OpenSceneGraph-devel`, `cppunit-devel`, `gdal-devel` (for anuga-viewer)

### Python Packages (Installed in Order)

1. **Build tools**: `cython`, `meson`, `meson-python`, `ninja`
2. **Scientific stack**: `numpy`, `scipy`, `matplotlib`, `tomli`
3. **Geospatial/IO**: `netcdf4`, `pyshp`
4. **ANUGA dependencies**: `dill`, `pymetis`, `pytools`, `polyline`, `triangle`
5. **MPI support**: `mpi4py` (built from source with MPI compiler)

### ANUGA Core

- **Source**: https://github.com/GeoscienceAustralia/anuga_core.git (v3.2.0)
- **Installation**: Editable mode (`pip install -e .`)
- **Location**: `./anuga_core/`

### Optional Tools (Extracted, Not System-Installed)

Place these archives in `opensource_tools/` before running setup:

1. **GeoServer** (`geoserver-2.28.2-bin.zip`)
   - Web-based geospatial server for flood map visualization
   - Requires Java (automatically installed)

2. **Node.js** (`node-v24.13.0-linux-x64.tar.xz`)
   - JavaScript runtime for React-based visualization frontend

3. **anuga-viewer** (auto-cloned if GDAL available)
   - 3D visualization tool for ANUGA results
   - Requires GDAL development headers

## Directory Structure

```
.
├── CMakeLists.txt                    # CMake configuration
├── setup.sh                          # Automated setup script (don't run directly - use make)
├── Makefile                          # Top-level build targets
├── README.md                         # This file
├── build/                            # CMake build artifacts + env scripts
│   ├── setup_mpi_env.sh             # Source before MPI runs
│   ├── setup_tools_env.sh           # Source for Node/GeoServer/viewer
│   ├── geoserver_start.sh           # Start GeoServer daemon
│   ├── geoserver_stop.sh            # Stop GeoServer daemon
│   └── test_anuga.sh                # ANUGA installation test
├── anuga_core/                       # ANUGA source (cloned during setup)
├── opensource_tools/                 # Place tool archives here
│   ├── geoserver-2.28.2-bin.zip     # (optional)
│   ├── node-v24.13.0-linux-x64.tar.xz  # (optional)
│   ├── geoserver-2.28.2-bin/        # (extracted during setup)
│   ├── node-v24.13.0-linux-x64/     # (extracted during setup)
│   └── anuga-viewer/                # (cloned if deps available)
└── mahanadi_test_case/               # Your flood modeling project
    ├── main.py
    ├── bridge.py
    ├── settings.toml
    ├── mesh_cache/                   # Cached mesh files
    └── anuga_outputs/                # Simulation results
```

## Usage

### Available Make Targets

```bash
make setup                  # Full installation (default)
make install                # Alias for setup
make test                   # Run ANUGA tests
make test_anuga             # Test ANUGA installation
make test_tools             # Test Node/GeoServer environment
make verify                 # Quick ANUGA import check
make geoserver-start        # Start GeoServer (detached)
make geoserver-stop         # Stop GeoServer
make clean                  # Remove build directory
make clean-outputs          # Remove simulation outputs (mesh_cache, anuga_outputs)
make clean-opensourcetools  # Remove extracted tools
make clean-all              # Complete cleanup (build, source, tools, outputs)
make help                   # Show all targets
```

### Testing Installation

**Quick verification:**
```bash
make verify
```

**Full test suite:**
```bash
make test_anuga
```

**Manual test:**
```bash
source build/setup_mpi_env.sh
python3 -c "import anuga; print('ANUGA version:', anuga.__version__)"
python3 -c "from anuga import myid, numprocs; print('myid:', myid, 'numprocs:', numprocs)"
```

### Running ANUGA Simulations

**Sequential (single core):**
```bash
source build/setup_mpi_env.sh
python3 mahanadi_test_case/main.py
```

**Parallel (MPI):**
```bash
source build/setup_mpi_env.sh
mpirun -np 4 python3 mahanadi_test_case/main.py
```

### Using GeoServer

**Start server:**
```bash
make geoserver-start
# Or manually:
source build/setup_tools_env.sh
bash build/geoserver_start.sh
```

**Access web interface:**
```
http://localhost:8080/geoserver
Default credentials: admin / geoserver
```

**Stop server:**
```bash
make geoserver-stop
```

### Using Node.js (for React Frontend)

```bash
source build/setup_tools_env.sh
node -v
npm -v
```

### Using anuga-viewer (if built)

```bash
source build/setup_tools_env.sh
anuga_viewer mahanadi_test_case/anuga_outputs/your_simulation.sww
```

## Environment Scripts

After installation, two environment scripts are available in `build/`:

**1. MPI Environment (for ANUGA simulations):**
```bash
source build/setup_mpi_env.sh
```
- Adds MPI compilers to PATH
- Sets LD_LIBRARY_PATH for MPI libraries
- Required before running ANUGA with MPI

**2. Tools Environment (for GeoServer/Node/viewer):**
```bash
source build/setup_tools_env.sh
```
- Adds Node.js to PATH (sets NODE_HOME)
- Sets GEOSERVER_HOME
- Adds anuga-viewer to PATH (if built)

## Troubleshooting

### Build Failures

**CMake syntax errors:**
```bash
make clean
make setup
```

**Python dependency conflicts:**
```bash
python3 -m pip uninstall -y <package>
make setup
```

**MPI not found:**
```bash
# On HPC systems, load MPI module first:
module load mpi/openmpi-x86_64
make setup
```

### GeoServer Issues

**Won't start:**
```bash
# Check Java installation
java -version

# Check GeoServer logs
tail -f opensource_tools/geoserver.out
```

**Port 8080 already in use:**
```bash
# Find and kill existing process
lsof -i :8080
kill <PID>
```

### ANUGA Import Errors

**netCDF4 missing:**
```bash
python3 -m pip install --break-system-packages netcdf4
```

**mpi4py fails:**
```bash
source build/setup_mpi_env.sh
MPICC=$(command -v mpicc) python3 -m pip install --no-cache-dir --no-binary mpi4py mpi4py --break-system-packages
```

### Clean Rebuild

**Remove just build artifacts:**
```bash
make clean
make setup
```

**Complete fresh install:**
```bash
make clean-all
make setup
```

## Flood Modeling Workflow

This installation enables the following workflow:

1. **Prepare terrain data** (DEM in ASC format)
2. **Configure simulation** (`settings.toml`)
3. **Run ANUGA simulation** (`python3 main.py`)
4. **Post-process results** (automatic via `bridge.py`)
5. **Deploy to GeoServer** (automatic WMS layer creation)
6. **Visualize in browser** (React frontend with OpenLayers)

See `mahanadi_test_case/` for a complete example.

## System Requirements

**Minimum:**
- 2 CPU cores
- 4 GB RAM
- 10 GB disk space

**Recommended:**
- 4+ CPU cores (for MPI parallelization)
- 8+ GB RAM
- 20 GB disk space
- NVIDIA GPU (future CUDA support)

## Differences from Google Colab Version

| Feature | Colab | This Setup |
|---------|-------|------------|
| Persistence | ❌ Session-based | ✅ Permanent installation |
| MPI Support | ❌ Limited | ✅ Full OpenMPI integration |
| GeoServer | ❌ Not available | ✅ Integrated + auto-deploy |
| Parallel Runs | ⚠️ Sequential only | ✅ Multi-core via mpirun |
| Dependency Mgmt | ❌ Manual reinstall | ✅ CMake-managed |
| Production Ready | ❌ Prototyping only | ✅ HPC/server deployment |

## License

- **ANUGA**: GPL v3 (see https://github.com/GeoscienceAustralia/anuga_core)
- **GeoServer**: GPL v2
- **This build system**: MIT License

## Support & Resources

- **ANUGA Documentation**: https://anuga.readthedocs.io/
- **ANUGA Repository**: https://github.com/GeoscienceAustralia/anuga_core
- **GeoServer Docs**: https://docs.geoserver.org/
- **Build Issues**: Check CMake output and environment scripts in `build/`

## Contributing

For improvements to this build system, test on both Ubuntu and RHEL-based systems before submitting changes.

## Citation

If you use ANUGA in research, please cite:
```
Roberts, S., Nielsen, O., Gray, D., Sexton, J., & Davies, G. (2015).
ANUGA User Manual. Geoscience Australia.
```
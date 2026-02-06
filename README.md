# ANUGA Linux/Ubuntu Installation

This is a plug-and-play CMake-based installation system for ANUGA (Australian National University Geophysical Analysis) on Ubuntu/Linux systems.

## Prerequisites

- Ubuntu 20.04+ (or compatible Debian-based distribution)
- Internet connection for downloading packages
- sudo privileges for installing system packages

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the setup script which will install all dependencies and build ANUGA:

```bash
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

If you prefer to install system dependencies separately:

1. **Install system dependencies:**
```bash
sudo apt-get update -y
sudo apt-get install -y g++ libgdal-dev libnetcdf-dev mpi-default-dev ninja-build cmake git python3 python3-pip python3-dev pkg-config
```

2. **Run CMake build:**
```bash
mkdir build
cd build
cmake ..
make setup
```

## What Gets Installed

### System Packages
- `g++` - C++ compiler
- `libgdal-dev` - Geospatial Data Abstraction Library
- `libnetcdf-dev` - NetCDF library for scientific data
- `mpi-default-dev` - Message Passing Interface
- `ninja-build` - Build system
- `cmake` - Build configuration tool
- `git` - Version control
- `python3` and `python3-pip` - Python runtime and package manager

### Python Packages
- `numpy`, `scipy` - Scientific computing
- `netcdf4` - NetCDF interface
- `matplotlib` - Plotting library
- `gdal` - Python GDAL bindings
- `mpi4py` - Python MPI bindings
- `pymetis` - Graph partitioning
- `pytools`, `polyline`, `triangle` - Utilities
- `meson-python`, `meson`, `ninja` - Build tools

### ANUGA
- Cloned from: https://github.com/GeoscienceAustralia/anuga_core.git
- Installed in editable mode

## Testing Installation

After installation, test ANUGA:

```bash
cd build
make test_anuga
```

Or manually:

```bash
python3 -c "import anuga; print('ANUGA version:', anuga.__version__)"
```

## CMake Targets

- `make setup` - Complete installation (default)
- `make install_python_deps` - Install Python dependencies only
- `make clone_anuga` - Clone ANUGA repository only
- `make build_anuga` - Build and install ANUGA only
- `make test_anuga` - Test ANUGA installation
- `make clean_anuga` - Remove ANUGA source directory

## Directory Structure

```
.
├── CMakeLists.txt      # CMake configuration
├── setup.sh            # Automated setup script
├── README.md           # This file
├── build/              # CMake build directory (created during build)
└── anuga_core/         # ANUGA source code (cloned during build)
```

## Troubleshooting

### Permission Errors
If you encounter permission errors when installing Python packages, the script uses user-level pip installation. If issues persist:

```bash
python3 -m pip install --user <package_name>
```

### Missing System Dependencies
If CMake reports missing dependencies:

```bash
sudo apt-get install -y g++ libgdal-dev libnetcdf-dev mpi-default-dev ninja-build cmake git python3-pip python3-dev pkg-config
```

### GDAL Version Conflicts
If you encounter GDAL version mismatches between the system and Python:

```bash
pip3 install gdal==$(gdal-config --version)
```

### Clean Rebuild
To start fresh:

```bash
cd build
make clean_anuga
rm -rf *
cmake ..
make setup
```

## Differences from Google Colab Version

This CMake version provides:
- ✅ Persistent installation (not session-based)
- ✅ Proper dependency checking
- ✅ Reusable build system
- ✅ System-wide or user-level installation options
- ✅ Easy cleanup and rebuild
- ✅ Better error handling

## License

ANUGA is licensed under GPL. See the ANUGA repository for details.

## Support

For ANUGA-specific issues, visit: https://github.com/GeoscienceAustralia/anuga_core

For build system issues with this CMake setup, check that all system dependencies are properly installed.
